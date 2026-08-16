#!/usr/bin/env bash
# Shared-style helpers are inlined per repo (keep each repo self-contained).
# Safely update the running Heimdall stack and remove dangling images.
# Creates a local rollback backup first, then asks whether to keep it / how many to retain.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=scripts/deps.sh
source "${ROOT}/scripts/deps.sh"


KEEP_FILE=".backup-keep-count"
DEFAULT_KEEP=3
BACKUP_ROOT="${ROOT}/backups"

need() { command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }

refuse_legacy_data() {
  if [[ "${I_UNDERSTAND_THIS_IS_A_FRESH_INSTALL:-}" == "yes" ]]; then
    return 0
  fi
  if [[ -d data/config/www ]] || [[ -f data/config/www/index.php ]]; then
    cat <<'EOF' >&2
Refusing to update: data looks like a LinuxServer Heimdall install.

./manage.sh update is only for stacks already using this repo's official-php image.
See BREAKING-CHANGES.md
EOF
    exit 1
  fi
}

print_offsite_tip() {
  cat <<'EOF'

Tip: Local backups under backups/ can fill your disk over time.
Copy important snapshots to an external drive, NAS, or cloud
(rclone, Backblaze B2, S3, Nextcloud, etc.), then keep fewer copies here.
Restore later with:
  ./manage.sh backup --restore --from ./backups
  ./manage.sh backup --restore --from /mnt/usb/my-backups
EOF
}

prune_old_backups() {
  local keep="$1"
  mkdir -p "${BACKUP_ROOT}/snapshots"
  mapfile -t dirs < <(ls -1dt "${BACKUP_ROOT}"/snapshots/* 2>/dev/null || true)
  # Also prune any leftover legacy update-* tarball folders from older scripts
  mapfile -t legacy < <(ls -1dt "${BACKUP_ROOT}"/update-* 2>/dev/null || true)
  local total="${#dirs[@]}"
  if (( total > keep )); then
    local i
    for (( i = keep; i < total; i++ )); do
      echo "Removing old snapshot: ${dirs[$i]}"
      rm -rf "${dirs[$i]}"
    done
    echo "Backup retention: kept ${keep} newest snapshot(s); removed $((total - keep)) older one(s)."
  else
    echo "Backup retention: keeping all ${total} snapshot(s) (limit ${keep})."
  fi
  if ((${#legacy[@]} > 0)); then
    echo "Note: found ${#legacy[@]} legacy backups/update-* folder(s)."
    echo "  Restore those manually via their RESTORE.txt, or delete them to free space."
  fi
  # Refresh latest symlink if needed
  if [[ -d "${BACKUP_ROOT}/snapshots" ]]; then
    local newest
    newest="$(ls -1dt "${BACKUP_ROOT}"/snapshots/* 2>/dev/null | head -1 || true)"
    if [[ -n "$newest" ]]; then
      ln -sfn "snapshots/$(basename "$newest")" "${BACKUP_ROOT}/latest"
    fi
  fi
}

ask_backup_retention() {
  local dir="$1"
  if [[ -z "${dir}" || ! -e "${dir}" ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    echo "No interactive terminal — keeping backup at ${dir}"
    local keep="${DEFAULT_KEEP}"
    [[ -f "${KEEP_FILE}" ]] && keep="$(tr -dc '0-9' <"${KEEP_FILE}" || true)"
    [[ -z "${keep}" ]] && keep="${DEFAULT_KEEP}"
    echo "${keep}" >"${KEEP_FILE}"
    prune_old_backups "${keep}"
    print_offsite_tip
    return 0
  fi
  echo
  local reply=""
  read -r -p "Update succeeded. Keep rollback backup at ${dir}? [Y/n] " reply || true
  case "${reply:-Y}" in
    n|N|no|NO)
      rm -rf "${dir}"
      # fix latest pointer
      if [[ -L "${BACKUP_ROOT}/latest" ]]; then
        local cur
        cur="$(readlink -f "${BACKUP_ROOT}/latest" 2>/dev/null || true)"
        if [[ "$cur" == "$dir" ]]; then
          rm -f "${BACKUP_ROOT}/latest"
          local newest
          newest="$(ls -1dt "${BACKUP_ROOT}"/snapshots/* 2>/dev/null | head -1 || true)"
          [[ -n "$newest" ]] && ln -sfn "snapshots/$(basename "$newest")" "${BACKUP_ROOT}/latest"
        fi
      fi
      rmdir "${BACKUP_ROOT}/snapshots" 2>/dev/null || true
      rmdir "${BACKUP_ROOT}" 2>/dev/null || true
      echo "Backup deleted."
      ;;
    *)
      echo "Backup kept."
      local default="${DEFAULT_KEEP}"
      [[ -f "${KEEP_FILE}" ]] && default="$(tr -dc '0-9' <"${KEEP_FILE}" || true)"
      [[ -z "${default}" ]] && default="${DEFAULT_KEEP}"
      local keep=""
      read -r -p "How many local backups should we keep on this disk? [${default}] " keep || true
      keep="$(printf '%s' "${keep:-$default}" | tr -dc '0-9')"
      [[ -z "${keep}" || "${keep}" -lt 1 ]] && keep="${default}"
      echo "${keep}" >"${KEEP_FILE}"
      prune_old_backups "${keep}"
      print_offsite_tip
      echo "  This snapshot: ${dir}"
      echo "  Manual restore: ./manage.sh backup --restore --from ./backups"
      ;;
  esac
}

create_backup() {
  if [[ ! -x "${ROOT}/scripts/backup.sh" ]]; then
    echo "Missing executable backup.sh (required for pre-update snapshots)." >&2
    exit 1
  fi
  local keep="${DEFAULT_KEEP}"
  [[ -f "${KEEP_FILE}" ]] && keep="$(tr -dc '0-9' <"${KEEP_FILE}" || true)"
  [[ -z "${keep}" ]] && keep="${DEFAULT_KEEP}"
  echo "==> Pre-update snapshot via ./manage.sh backup --dest ${BACKUP_ROOT} ..."
  "${ROOT}/scripts/backup.sh" --dest "${BACKUP_ROOT}" --keep "${keep}"
  if [[ -L "${BACKUP_ROOT}/latest" ]]; then
    BACKUP_DIR="$(readlink -f "${BACKUP_ROOT}/latest")"
  else
    BACKUP_DIR="$(ls -1dt "${BACKUP_ROOT}"/snapshots/* 2>/dev/null | head -1 || true)"
  fi
  if [[ -z "${BACKUP_DIR}" || ! -d "${BACKUP_DIR}" ]]; then
    echo "Pre-update backup did not produce a snapshot." >&2
    exit 1
  fi
  echo "Backup ready: ${BACKUP_DIR}"
}


need docker
compose version >/dev/null
refuse_legacy_data

if [[ ! -f .env ]]; then
  echo "No .env found. Run ./manage.sh first." >&2
  exit 1
fi

create_backup

echo "==> Pulling base image layers / rebuilding Heimdall..."
compose build --pull
echo "==> Recreating containers with new image (brief downtime per service)..."
compose up -d --remove-orphans
echo "==> Status:"
compose ps
echo "==> Removing dangling (untagged) images only — not other projects' images..."
docker image prune -f

echo
echo "Update finished."
echo "Open Heimdall in your browser to confirm it still loads."
ask_backup_retention "${BACKUP_DIR}"
