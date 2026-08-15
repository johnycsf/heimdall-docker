#!/usr/bin/env bash
# Safely update the running Heimdall stack and remove dangling images.
# Safe to run while containers are up (Compose recreates only what changed).
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

need docker
docker compose version >/dev/null
refuse_legacy_data

if [[ ! -f .env ]]; then
  echo "No .env found. Run ./install.sh first." >&2
  exit 1
fi

echo "==> Pulling base image layers / rebuilding Heimdall..."
docker compose build --pull
echo "==> Recreating containers with new image (brief downtime per service)..."
docker compose up -d --remove-orphans
echo "==> Waiting for container to be running..."
docker compose ps
echo "==> Removing dangling (untagged) images only — not other projects' images..."
docker image prune -f

echo
echo "Update finished."
echo "Open Heimdall in your browser to confirm it still loads."
