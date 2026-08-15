#!/usr/bin/env bash
# Safely update the running Heimdall stack and remove dangling images.
# Creates a local rollback backup first, then asks whether to keep it.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

need() { command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }

refuse_legacy_data() {
  if [[ "${I_UNDERSTAND_THIS_IS_A_FRESH_INSTALL:-}" == "yes" ]]; then
    return 0
  fi
  if [[ -d data/config/www ]] || [[ -f data/config/www/index.php ]]; then
    cat <<'EOF' >&2
Refusing to update: data looks like a LinuxServer Heimdall install.

./update.sh is only for stacks already using this repo's official-php image.
See BREAKING-CHANGES.md
EOF
    exit 1
  fi
}

ask_backup_retention() {
  local dir="$1"
  if [[ ! -d "${dir}" ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    echo "No interactive terminal — keeping backup at ${dir}"
    return 0
  fi
  echo
  local reply=""
  read -r -p "Update succeeded. Keep rollback backup at ${dir}? [Y/n] " reply || true
  case "${reply:-Y}" in
    n|N|no|NO)
      rm -rf "${dir}"
      # Remove backups/ if empty
      rmdir backups 2>/dev/null || true
      echo "Backup deleted."
      ;;
    *)
      echo "Backup kept."
      echo "  See ${dir}/RESTORE.txt if you need to roll back."
      ;;
  esac
}

create_backup() {
  BACKUP_DIR="backups/update-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${BACKUP_DIR}"
  echo "==> Creating rollback backup in ${BACKUP_DIR} ..."
  [[ -f .env ]] && cp -a .env "${BACKUP_DIR}/"
  [[ -f docker-compose.yml ]] && cp -a docker-compose.yml "${BACKUP_DIR}/"
  if [[ -d data ]]; then
    tar -C data -czf "${BACKUP_DIR}/data.tar.gz" .
  fi
  cat >"${BACKUP_DIR}/RESTORE.txt" <<EOF
Heimdall Docker rollback (stop stack first if needed):

  cd $(pwd)
  docker compose down
  # restore config
  cp -a ${BACKUP_DIR}/.env .env 2>/dev/null || true
  # restore data volume
  rm -rf data
  mkdir -p data
  tar -C data -xzf ${BACKUP_DIR}/data.tar.gz
  docker compose up -d
EOF
  echo "Backup ready: ${BACKUP_DIR}"
}

need docker
docker compose version >/dev/null
refuse_legacy_data

if [[ ! -f .env ]]; then
  echo "No .env found. Run ./install.sh first." >&2
  exit 1
fi

create_backup

echo "==> Pulling base image layers / rebuilding Heimdall..."
docker compose build --pull
echo "==> Recreating containers with new image (brief downtime per service)..."
docker compose up -d --remove-orphans
echo "==> Status:"
docker compose ps
echo "==> Removing dangling (untagged) images only — not other projects' images..."
docker image prune -f

echo
echo "Update finished."
echo "Open Heimdall in your browser to confirm it still loads."
ask_backup_retention "${BACKUP_DIR}"
