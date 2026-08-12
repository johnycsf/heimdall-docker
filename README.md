# heimdall-docker

Deploy [Heimdall](https://heimdall.site/) with Docker Compose — a simple application dashboard for your homelab links.

Kubernetes version: [heimdall-k8s](https://github.com/johnycsf/heimdall-k8s)

Uses the **official** [`php:8.4-apache`](https://hub.docker.com/_/php) image and builds Heimdall from the [upstream release](https://github.com/linuxserver/Heimdall/releases) (no LinuxServer container runtime).

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

```bash
docker compose build --pull
docker compose up -d
```

## Uninstall

```bash
docker compose down
# optional: delete local data
rm -rf data
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
