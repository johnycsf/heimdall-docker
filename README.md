# heimdall-docker

Deploy [Heimdall](https://heimdall.site/) with Docker Compose — a simple application dashboard for your homelab links.

Kubernetes version: [heimdall-k8s](https://github.com/johnycsf/heimdall-k8s)

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
docker compose up -d
```

Open `http://YOUR_IP/` (or the `HTTP_PORT` from `.env`).

## Customize

Edit `.env`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `TZ` | `America/New_York` | Timezone |
| `PUID` / `PGID` | `1000` | File ownership (`id -u` / `id -g`) |
| `HTTP_PORT` / `HTTPS_PORT` | `80` / `443` | Host ports |
| `ALLOW_INTERNAL_REQUESTS` | `true` | Allow Heimdall to reach LAN app IPs |

## Update

```bash
docker compose pull
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
