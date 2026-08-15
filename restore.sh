#!/usr/bin/env bash
# Restore Heimdall Docker data from a backups/update-* snapshot created by update.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

need() { command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }
need docker
docker compose version >/dev/null

if [[ ! -d backups ]]; then
  echo "No backups/ directory found. Run ./update.sh at least once first." >&2
  exit 1
fi

mapfile -t DIRS < <(ls -1dt backups/update-* 2>/dev/null || true)
if ((${#DIRS[@]} == 0)); then
  echo "No backups/update-* snapshots found." >&2
  exit 1
fi

echo "Available backups (newest first):"
local_i=1
for d in "${DIRS[@]}"; do
  size="$(du -sh "$d" 2>/dev/null | awk '{print $1}')"
  echo "  ${local_i}) ${d}  (${size})"
  local_i=$((local_i + 1))
done

choice=""
if [[ -t 0 ]]; then
  read -r -p "Restore which backup number? [1] " choice || true
else
  echo "Non-interactive: use ./restore.sh with a TTY to choose a backup." >&2
  exit 1
fi
choice="${choice:-1}"
if ! [[ "${choice}" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#DIRS[@]} )); then
  echo "Invalid selection." >&2
  exit 1
fi
SRC="${DIRS[$((choice - 1))]}"

if [[ ! -f "${SRC}/data.tar.gz" ]]; then
  echo "Backup ${SRC} is missing data.tar.gz" >&2
  exit 1
fi

echo
echo "This will STOP Heimdall and REPLACE ./data with ${SRC}."
read -r -p "Type 'restore' to continue: " confirm || true
if [[ "${confirm}" != "restore" ]]; then
  echo "Aborted."
  exit 1
fi

echo "==> Stopping stack..."
docker compose down
echo "==> Restoring files..."
[[ -f "${SRC}/.env" ]] && cp -a "${SRC}/.env" .env
rm -rf data
mkdir -p data
tar -C data -xzf "${SRC}/data.tar.gz"
echo "==> Starting stack..."
docker compose up -d
docker compose ps
echo
echo "Restore finished from ${SRC}."
