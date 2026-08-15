# heimdall-docker

Deploy [Heimdall](https://heimdall.site/) with Docker Compose — a simple application dashboard for your homelab links.

Kubernetes version: [heimdall-k8s](https://github.com/johnycsf/heimdall-k8s)

Uses the **official** [`php:8.4-apache`](https://hub.docker.com/_/php) image and builds Heimdall from the [upstream release](https://github.com/linuxserver/Heimdall/releases) (no LinuxServer container runtime).

> **Updating an older clone?** `git pull` alone will not wipe data. Re-running install/compose **can** break a LinuxServer-based install. Read [BREAKING-CHANGES.md](BREAKING-CHANGES.md) first.

## What you need

- Docker with Compose plugin (`docker compose`)

## Install

```bash
git clone https://github.com/johnycsf/heimdall-docker.git
cd heimdall-docker
chmod +x install.sh
./install.sh
```

Or:

```bash
cp .env.example .env
docker compose up -d --build
```

Open `http://YOUR_IP/` (or the `HTTP_PORT` from `.env`).

## Customize

Edit `.env`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `TZ` | `America/New_York` | Timezone |
| `HTTP_PORT` | `80` | Host port |
| `ALLOW_INTERNAL_REQUESTS` | `true` | Allow Heimdall to reach LAN app IPs |
| `APP_URL` | `http://localhost` | Public URL (set this if you use a reverse proxy) |

## Update

Only for installs that **already** use this repo’s official-php image.

```bash
docker compose build --pull
docker compose up -d
```

If you previously used LinuxServer Heimdall, do **not** run the commands above after a pull — see [BREAKING-CHANGES.md](BREAKING-CHANGES.md).

## Uninstall

```bash
docker compose down
# optional: delete local data
rm -rf data
```

## Repository activity

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/56187ad981a21b6f4e83617ea52721341d344acc.svg "Repobeats analytics image")

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
