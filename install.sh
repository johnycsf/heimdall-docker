#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

need() { command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }
need docker
docker compose version >/dev/null

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
