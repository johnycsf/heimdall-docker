# heimdall-docker

[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/johnycsf)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Issues](https://img.shields.io/badge/issues-welcome-lightgrey.svg)](../../issues/new/choose)

One-command Heimdall for homelab beginners — official images, backup-before-update.

![`./manage.sh` control center](docs/manage-demo.gif)

## Install

```bash
git clone https://github.com/johnycsf/heimdall-docker.git
cd heimdall-docker
chmod +x manage.sh
./manage.sh
```

`./manage.sh` opens a **↑/↓ menu** with a `>` cursor (j/k and Enter also work). Open `http://YOUR_IP:8080/` (or the `HTTP_PORT` from `.env`).

Uses the **official** [`php:8.4-apache`](https://hub.docker.com/_/php) image and builds Heimdall from the [upstream release](https://github.com/linuxserver/Heimdall/releases) (no LinuxServer container runtime).

Kubernetes version: [heimdall-k8s](https://github.com/johnycsf/heimdall-k8s)

> **Updating an older clone?** `git pull` alone will not wipe data. Re-running install/compose **can** break a LinuxServer-based install. Read [BREAKING-CHANGES.md](BREAKING-CHANGES.md) first.

## Why this repo (not just another compose file)

- **`./manage.sh`** control center — install, update, backup, status/doctor, uninstall
- Interactive colored install with step progress
- Auto-detects your OS and installs missing host tools
- Safe **`./manage.sh update`** with automatic pre-update backup
- Incremental hardlink **`./manage.sh backup`** + restore
- **Official upstream images only**

## What you need

- A Linux host (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine) or macOS with Homebrew
- `sudo` so `./manage.sh` can install missing tools (Docker, curl, openssl, rsync, …)
- Enough disk for your data

## Customize

Edit `.env` (created from `.env.example`):

| Variable | Default | Purpose |
|----------|---------|---------|
| `TZ` | `America/New_York` | Timezone |
| `HTTP_PORT` | `8080` | Host port (Docker users may set `80`) |
| `ALLOW_INTERNAL_REQUESTS` | `true` | Allow Heimdall to reach LAN app IPs |
| `APP_URL` | `http://localhost:8080` | Public URL (set this if you use a reverse proxy) |

## Update

```bash
./manage.sh update
```

Before updating, the script runs `./manage.sh backup` into `./backups` (incremental, SQLite-safe). Afterward it asks whether to keep that snapshot and how many copies to retain.

## Backup and restore

Prefer an external drive or NAS (hardlinks need one filesystem):

```bash
./manage.sh backup --dest /mnt/backup --keep 5
```

Each run writes `/mnt/backup/heimdall-docker/snapshots/...`.

Restore (this machine or a new one after `./manage.sh` / with compose present):

```bash
./manage.sh backup --restore --from /mnt/usb/heimdall-docker-backups
# or a local snapshot tree:
./manage.sh backup --restore --from ./backups
```

Each snapshot includes `SHA256SUMS` plus a `snapshot_sha256` key in `META.txt`. Restore **warns** (does not abort) if integrity is lost.

**Database safety:** Heimdall (SQLite) is stopped, WAL-checkpointed when `sqlite3` is available, integrity-checked, then copied. Incremental hardlinks apply to file trees; each dump is a full verified file with a SHA-256 in `META.txt`.

Older `backups/update-*` tarball folders (from previous script versions) are no longer used by `./manage.sh update`; use each folder's `RESTORE.txt` if you still need one, or delete them to free space.

Only for installs already on this repo's official-php image — see [BREAKING-CHANGES.md](BREAKING-CHANGES.md).

## Uninstall

```bash
docker compose down
# optional: delete local data
rm -rf data
```

Or use **Uninstall** in `./manage.sh`.

## Host ports

During `./manage.sh` (or Manage → Install / reconfigure), the script checks whether default host ports are free, lets you keep the defaults or choose different ports, and saves them in `.env`. Re-running install keeps your current ports unless you change them.

Non-interactive: set the port variables in `.env` (or the environment) and use `SKIP_PORT_PROMPTS=1`.

Defaults are kept unique across the johnycsf stacks so you can run several on one host without a clash:

| Stack | Variable | Default host port |
|-------|----------|-------------------|
| `heimdall-docker` | `HTTP_PORT` | `8080` |
| `vaultwarden-docker` | `PORT` | `8081` |
| `nextcloud-office-docker` | `NEXTCLOUD_PORT` | `8082` |
| `nextcloud-office-docker` | `COLLABORA_PORT` | `9980` |
| `immich-docker` | `IMMICH_PORT` | `2283` |

Install also refuses a port another stack checked out beside this one already claims in its `.env` — even when that stack is stopped — and offers the next free port instead.

All defaults are `>= 1024` because **rootless Podman cannot publish privileged ports** (`80`, `443`). On Docker you may still set `HTTP_PORT=80` if you want.

## Container engine

During `./manage.sh` → Install you can choose **Docker** or **Podman**. The choice is saved as `CONTAINER_ENGINE` in `.env` and reused for every manage action (`update`, `backup`, `restore`, status, …) via a shared `compose` helper. Restore preserves that host choice (and host ports) even if the backup’s `.env` is older.

## Backup exports

> **Note:** After containers start, some files under `data/` may be root-owned. Install/restore automatically fixes ownership for the invoking user so host-side `rsync` backup/restore does not fail with permission errors.

Local snapshots stay as incremental hardlink trees (fast rollback). Optionally create a compressed offsite copy with `./manage.sh backup --dest ./backups --archive tar.gz|tar.xz|zip` (add `--archive-password` for zip password or age-passphrase on tar). For stronger key-based encryption use `--encrypt` (age). See repo-framework `docs/BACKUP_ENCRYPTION.md`.

## Credits

This repo packages or configures upstream software. See [CREDITS.md](CREDITS.md) for the main developers and projects this work builds on.

## Disclaimer

This project is provided **as is**. The author is **not responsible** for any loss, damage, data corruption, downtime, security issues, or other consequences from using it. Full text: [DISCLAIMER.md](DISCLAIMER.md).

## Bug reports & contributions

If you hit an error, please [open a GitHub Issue](../../issues/new/choose) and follow [CONTRIBUTING.md](CONTRIBUTING.md). Fixes via Pull Request are welcome. GitHub Issues/PRs are the supported way to report problems—there is no private support channel.

## Security

See [SECURITY.md](SECURITY.md) for how to report vulnerabilities.

Sponsorship funds testing and maintenance: [github.com/sponsors/johnycsf](https://github.com/sponsors/johnycsf).
