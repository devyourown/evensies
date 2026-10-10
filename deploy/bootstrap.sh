#!/usr/bin/env bash
# One-time server setup for a fresh Ubuntu 24.04 host. Idempotent. Run as root:
#   curl -sSL https://raw.githubusercontent.com/devyourown/evensies/main/deploy/bootstrap.sh | bash -s -- evensies.nariinfo.dev
set -euo pipefail
DOMAIN="${1:?usage: bootstrap.sh <domain>}"
APP_DIR=/opt/evensies

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q ca-certificates curl git ufw unattended-upgrades

# Docker (official repo)
if ! command -v docker >/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -q
  apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

# Firewall: SSH, HTTP, HTTPS only
ufw allow OpenSSH >/dev/null
ufw allow 80/tcp >/dev/null
ufw allow 443/tcp >/dev/null
ufw --force enable >/dev/null

# Automatic security updates
dpkg-reconfigure -f noninteractive unattended-upgrades

# Code
if [ ! -d "$APP_DIR/.git" ]; then
  git clone -q https://github.com/devyourown/evensies.git "$APP_DIR"
else
  git -C "$APP_DIR" pull -q --ff-only
fi

# Secrets: generated here, never printed
ENV="$APP_DIR/deploy/.env"
if [ ! -f "$ENV" ]; then
  cat > "$ENV" <<ENVEOF
EVENSIES_DOMAIN=$DOMAIN
EVENSIES_PUBLIC_URL=https://$DOMAIN
EVENSIES_JWT_SECRET=$(openssl rand -hex 48)
POSTGRES_USER=evensies
POSTGRES_PASSWORD=$(openssl rand -hex 24)
POSTGRES_DB=evensies
EVENSIES_APPLE_CLIENT_ID=dev.nariinfo.evensies
EVENSIES_GOOGLE_CLIENT_IDS=
EVENSIES_AUTH_DEV_LOGIN=false
#EVENSIES_FCM_CREDENTIALS_FILE=/secrets/fcm.json
ENVEOF
  chmod 600 "$ENV"
  echo "wrote $ENV"
fi
echo "bootstrap done"
