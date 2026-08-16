# heimdall-docker

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/56187ad981a21b6f4e83617ea52721341d344acc.svg "Repobeats analytics image")

[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/johnycsf)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Issues](https://img.shields.io/badge/issues-welcome-lightgrey.svg)](../../issues/new/choose)

Deploy [Heimdall](https://heimdall.site/) with Docker Compose — a simple application dashboard for your homelab links.

Kubernetes version: [heimdall-k8s](https://github.com/johnycsf/heimdall-k8s)

Uses the **official** [`php:8.4-apache`](https://hub.docker.com/_/php) image and builds Heimdall from the [upstream release](https://github.com/linuxserver/Heimdall/releases) (no LinuxServer container runtime).

> **Updating an older clone?** `git pull` alone will not wipe data. Re-running install/compose **can** break a LinuxServer-based install. Read [BREAKING-CHANGES.md](BREAKING-CHANGES.md) first.

**One-command Heimdall dashboard** — official PHP build of upstream Heimdall, interactive install, backups.

> **Choose your path:** **Docker Compose (this repo)** · [Kubernetes](https://github.com/johnycsf/heimdall-k8s)

## Who this is for

**Good fit:** a simple start-page for your self-hosted apps on Docker.

**Not for:** reusing old LinuxServer `/config` volumes — see BREAKING-CHANGES if migrating.

## Why this repo (not just another compose file)

- **`./manage.sh`** control center — install, update, backup, status/doctor, uninstall
- Interactive colored install with step progress
- Auto-detects your OS and installs missing host tools
- Safe **`./update.sh`** with automatic pre-update backup
- Incremental hardlink **`./backup.sh`** + restore
- **Official upstream images only**

## Support this work

If this stack saved you setup time, please consider sponsoring — it funds:

- Keeping install/update/backup scripts working across common Linux distros
- Testing safe upgrades against **official** upstream images
- Building more beginner-friendly stacks that share the same `./manage.sh` UX

[![Sponsor johnycsf](https://img.shields.io/badge/GitHub%20Sponsors-Donate-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/johnycsf)

👉 **[github.com/sponsors/johnycsf](https://github.com/sponsors/johnycsf)**

## What you need

- A Linux host (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine) or macOS with Homebrew
- `sudo` so `./install.sh` can install missing tools (Docker, curl, openssl, rsync, …)
- Enough disk for your data

`./install.sh` is interactive (colors + step progress), detects your OS, and installs host dependencies automatically.

## Install

```bash
git clone https://github.com/johnycsf/heimdall-docker.git
cd heimdall-docker
chmod +x manage.sh install.sh
./manage.sh          # interactive control center
# or: ./install.sh
```

Or:

```bash
cp .env.example .env
docker compose up -d --build
```

Open `http://YOUR_IP/` (or the `HTTP_PORT` from `.env`).

Liked the install? Star the repo or [sponsor johnycsf](https://github.com/sponsors/johnycsf) so more stacks stay maintained.

## Customize

Edit `.env`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `TZ` | `America/New_York` | Timezone |
| `HTTP_PORT` | `80` | Host port |
| `ALLOW_INTERNAL_REQUESTS` | `true` | Allow Heimdall to reach LAN app IPs |
| `APP_URL` | `http://localhost` | Public URL (set this if you use a reverse proxy) |

## Update

Keep the stack current (safe while running; brief recreate downtime):

```bash
chmod +x update.sh
./update.sh
```

Before changing anything, the script runs `./backup.sh` into `./backups` (incremental, database-safe). After a successful update it asks whether to **keep** or **delete** that snapshot, and how many local copies to retain (older ones are pruned). Copy important backups to an external drive, NAS, or cloud so they do not fill this disk.

To roll back later (same tool as disaster recovery):

```bash
./backup.sh --restore --from ./backups
# or from an external copy:
./backup.sh --restore --from /mnt/usb/my-backups
```

Older `backups/update-*` tarball folders (from previous script versions) are no longer used by `./update.sh`; use each folder's `RESTORE.txt` if you still need one, or delete them to free space.

This pulls/rebuilds images, recreates containers as needed, and runs `docker image prune` for **dangling** (untagged) images only — it will not wipe other projects' images or your `data/` volume.

Only for installs already on this repo's official-php image — see [BREAKING-CHANGES.md](BREAKING-CHANGES.md).

## Disaster recovery (full backup / restore)

Incremental snapshots via `rsync` hardlinks (unchanged files are not re-copied). `./update.sh` uses this same `backup.sh` before updating (into `./backups`).

```bash
chmod +x backup.sh

# Backup to USB/NAS/external path (repeat anytime; later runs are incremental)
./backup.sh --dest /mnt/usb/heimdall-docker-backups
./backup.sh --dest /mnt/usb/heimdall-docker-backups --keep 5   # optional: retain only newest N

# On a brand-new machine/cluster after ./install.sh:
./backup.sh --restore --from /mnt/usb/heimdall-docker-backups
# or a specific snapshot:
./backup.sh --restore --from /mnt/usb/heimdall-docker-backups/snapshots/YYYYMMDD-HHMMSS
```

Each snapshot includes `SHA256SUMS` plus a `snapshot_sha256` key in `META.txt`. Restore verifies these and **warns** (does not abort) if integrity is lost.

Keep the backup root on **one filesystem** so hardlinks work. Prefer an external drive, NAS, or cloud sync of that folder.

**Database safety:** Nextcloud uses a verified MariaDB *logical* dump (`mariadb-dump --single-transaction`) — the live `data/db` / DB PVC files are never rsync'd. SQLite apps (Heimdall, Vaultwarden) are stopped or scaled to 0, WAL-checkpointed when `sqlite3` is available, integrity-checked, then copied. Incremental hardlinks apply to file trees; each SQL dump is a full verified file with a SHA-256 in `META.txt`.

## Uninstall

```bash
docker compose down
# optional: delete local data
rm -rf data
```

## Credits

This repo packages or configures upstream software. See [CREDITS.md](CREDITS.md) for the main developers and projects this work builds on.

## Disclaimer

This project is provided **as is**. The author is **not responsible** for any loss, damage, data corruption, downtime, security issues, or other consequences from using it. Full text: [DISCLAIMER.md](DISCLAIMER.md).

## Bug reports & contributions

If you hit an error, please [open a GitHub Issue](../../issues/new/choose) and follow [CONTRIBUTING.md](CONTRIBUTING.md). Fixes via Pull Request are welcome. GitHub Issues/PRs are the supported way to report problems—there is no private support channel.

## Encrypted backups

Local snapshots stay as incremental hardlink trees (fast rollback). For offsite/USB/NAS confidentiality, create an **age**-encrypted export (`./backup.sh --dest ./backups --encrypt`). SHA256 checksums cover integrity; age covers confidentiality. See upstream docs in repo-framework `docs/BACKUP_ENCRYPTION.md`.

## Security

See [SECURITY.md](SECURITY.md) for how to report vulnerabilities.
