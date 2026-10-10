#!/usr/bin/env bash
# Redeploy the latest main: pull, rebuild the server image, restart. Run on the server as root.
set -euo pipefail
cd /opt/evensies
git pull -q --ff-only
cd deploy
docker compose build --pull server
docker compose up -d
docker image prune -f >/dev/null
docker compose ps
