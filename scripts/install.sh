#!/usr/bin/env bash
# Install Heimdall with Compose / Docker or Podman (interactive).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=scripts/deps.sh
source "${ROOT}/scripts/deps.sh"

ui_steps_init 4

refuse_legacy_data() {
  if [[ "${I_UNDERSTAND_THIS_IS_A_FRESH_INSTALL:-}" == "yes" ]]; then
    ui_warn "Override set: I_UNDERSTAND_THIS_IS_A_FRESH_INSTALL=yes — continuing."
    return 0
  fi
  if [[ -d data/config/www ]] || [[ -f data/config/www/index.php ]]; then
    ui_err "Existing data looks like a LinuxServer Heimdall install."
    cat <<'EOF' >&2

git pull alone is safe. Re-running this script with the new image is NOT
an in-place upgrade and can break your dashboard. See BREAKING-CHANGES.md

Options:
  1) Keep running your current containers (do nothing).
  2) Move data/ aside, then install fresh.
  3) Only if you accept a fresh install:
       I_UNDERSTAND_THIS_IS_A_FRESH_INSTALL=yes ./manage.sh install
EOF
    exit 1
  fi
}

ui_step "Checking host dependencies"
configure_container_engine
ui_banner "Heimdall" "$(compose_stack_subtitle "official php:apache + upstream Heimdall")"
ensure_host_deps docker sqlite3

ui_step "Checking for incompatible legacy data"
refuse_legacy_data
ui_ok "Data path looks good"

ui_step "Preparing configuration"
if [[ ! -f .env ]]; then
  cp .env.example .env
  ui_ok "Created .env from .env.example"
else
  ui_ok "Using existing .env"
fi
configure_host_port HTTP_PORT "Heimdall HTTP" 80
IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
if [[ -n "${IP}" ]]; then
  if [[ "${HTTP_PORT}" == "80" ]]; then
    env_file_set APP_URL "http://${IP}"
  else
    env_file_set APP_URL "http://${IP}:${HTTP_PORT}"
  fi
  ui_ok "APP_URL=$(env_file_get APP_URL)"
fi
mkdir -p data/config

ui_step "Building and starting containers"
ui_run --stream "Building Heimdall image" compose build
ui_run --stream "Starting stack" compose up -d

ensure_host_owned_dir data data/config

PORT="$(grep -E '^HTTP_PORT=' .env 2>/dev/null | cut -d= -f2 || echo 80)"
echo
ui_ok "Heimdall is starting"
ui_info "Open: ${UI_BOLD}http://<this-computer-ip>:${PORT}/${UI_RESET}"
ui_info "Later: ./manage.sh update   ·   ./manage.sh backup --dest /path/to/backups"
