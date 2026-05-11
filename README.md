# devops-starter-kit

Production-ready Docker stack with automated CI/CD, monitoring, and server hardening.

## Stack

- Docker Compose (dev + prod)
- GitHub Actions (build → push → deploy)
- Nginx with SSL termination and security headers
- PostgreSQL 16 + Redis 7
- Prometheus + Grafana + Node Exporter + cAdvisor
- Automated backups to S3

## Requirements

- Ubuntu 22.04+ VPS (Hetzner CX21 or equivalent)
- Docker 24+
- GitHub account

## Quick start

```bash
git clone https://github.com/YOUR_USERNAME/devops-starter-kit
cd devops-starter-kit
cp .env.example .env
make up
```

App runs at `http://localhost:3000`.

## Production setup

On a fresh Ubuntu server (as root):

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/devops-starter-kit/main/scripts/setup.sh | bash
```

This installs Docker, creates a `deploy` user, configures UFW, fail2ban, SSH hardening, and unattended security upgrades.

Copy your SSH public key to the server:

```bash
ssh-copy-id deploy@YOUR_SERVER_IP
```

Clone the repo on the server:

```bash
su - deploy
git clone https://github.com/YOUR_USERNAME/devops-starter-kit /opt/app
cd /opt/app && cp .env.example .env
```

Edit `/opt/app/.env` with production values.

## CI/CD

Add these secrets in GitHub → Settings → Secrets → Actions:

| Secret | Value |
|--------|-------|
| `PROD_HOST` | Server IP |
| `PROD_USER` | `deploy` |
| `PROD_SSH_KEY` | Contents of `~/.ssh/id_ed25519` |

Pipeline on push to `main`:
1. Build Docker image
2. Push to GitHub Container Registry
3. SSH into server, pull, restart

Rollback to a previous commit:

```bash
make rollback TAG=abc1234
```

## Monitoring

```bash
make monitoring
```

Grafana at `http://YOUR_IP:3001`. Credentials in `.env`.

Import dashboard ID `1860` (Node Exporter Full) from grafana.com.

## Commands

```
make up            start dev stack
make down          stop
make build         rebuild images
make logs          tail logs
make shell         shell into app container
make clean         remove containers + volumes
make deploy        deploy to production
make rollback      rollback (TAG=<sha>)
make monitoring    start monitoring stack
```

## Automated backups

Set environment variables and add a cron job:

```bash
crontab -e
# Daily backup at 2am
0 2 * * * S3_BUCKET=your-bucket POSTGRES_URL=your-url /opt/app/scripts/backup.sh >> /var/log/backup.log 2>&1
```

Backups are compressed, uploaded to S3 (STANDARD_IA), and pruned after 30 days.

## Architecture

```
push to main
    └── GitHub Actions (CI)
            └── build Docker image
            └── push to GHCR
            └── GitHub Actions (Deploy)
                    └── SSH to server
                    └── docker compose pull + up
                    └── health check

internet → nginx (80 → 443, SSL) → app:3000 → postgres / redis
                                            └── /metrics → prometheus → grafana
```
