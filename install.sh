#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

need() { command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }
need docker
docker compose version >/dev/null

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example — edit TZ/PUID/ports if you want."
fi

mkdir -p data/config
docker compose pull
docker compose up -d

echo
echo "Heimdall is starting."
echo "Open http://<this-computer-ip>:$(grep -E '^HTTP_PORT=' .env | cut -d= -f2 || echo 80)/"
echo "HTTPS also listens on port $(grep -E '^HTTPS_PORT=' .env | cut -d= -f2 || echo 443) (self-signed cert)."
