#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

need() { command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }

refuse_legacy_data() {
  if [[ "${I_UNDERSTAND_THIS_IS_A_FRESH_INSTALL:-}" == "yes" ]]; then
    echo "Override set: I_UNDERSTAND_THIS_IS_A_FRESH_INSTALL=yes — continuing."
    return 0
  fi
  # LinuxServer Heimdall persists app files under /config/www
  if [[ -d data/config/www ]] || [[ -f data/config/www/index.php ]]; then
    cat <<'EOF' >&2
Refusing to start: existing data looks like a LinuxServer Heimdall install.

git pull alone is safe. Re-running this script / compose with the new image is NOT
an in-place upgrade and can break your dashboard.

See BREAKING-CHANGES.md

Options:
  1) Keep running your current containers (do nothing).
  2) Move data/ aside, then install fresh.
  3) Only if you accept a fresh install:
       I_UNDERSTAND_THIS_IS_A_FRESH_INSTALL=yes ./install.sh
EOF
    exit 1
  fi
}

need docker
docker compose version >/dev/null
refuse_legacy_data

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example — edit TZ/ports/APP_URL if you want."
fi

mkdir -p data/config
docker compose build
docker compose up -d

echo
echo "Heimdall is starting (official php:apache image + Heimdall upstream source)."
echo "Open http://<this-computer-ip>:$(grep -E '^HTTP_PORT=' .env | cut -d= -f2 || echo 80)/"
