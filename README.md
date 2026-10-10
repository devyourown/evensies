# Tally

Open-source expense splitting for friends, roommates and trips. A Splitwise alternative with **no daily limits, no ads, and no data lock-in**. Native iOS/Android app (Flutter) + a small server (Spring Boot, Kotlin, PostgreSQL) you can self-host with one command.

> Status: pre-release. Working name "Tally"; the store name will be decided before launch.

## Why
Splitwise caps free users at a few expenses per day — exactly on the first day of a trip. Open-source alternatives are mostly web apps. Tally is a native app with offline-first sync, and the server is yours if you want it.

## Promises (sustainability rules)
These are commitments, written down so they can't quietly change later:
1. **No input limits, ever.** Not per day, not per group.
2. **Self-hosting is free forever.** Same Docker image as the hosted service.
3. **Export is always available** (JSON and CSV). Your data leaves whenever you do.
4. **Existing features never move behind a paywall.**
5. If hosting the public server costs more than €30/month, we will first **limit new sign-ups**, and only then add an optional *supporter* tier **for the hosted server only**.

## Features (release 1)
- Groups with invite links; placeholder members for friends who haven't installed the app yet
- Expenses with equal / exact / percentage splits, per-expense currency
- Balances and simplified settlement (minimum transfers), "mark as paid"
- Offline-first: add expenses without signal, sync later, conflicts resolved per field
- Sign in with Apple / Google; account deletion
- Export JSON/CSV, import a Splitwise CSV
- Self-hostable: `docker compose up`

## Repository layout
```
app/      Flutter app (iOS, Android)
server/   Spring Boot (Kotlin) API + sync server
shared/   JSON test cases both implementations must pass (split, settlement, sync)
deploy/   Docker Compose, Caddy, .env.example
docs/     API contract (docs/API.md), design spec, plans
```

## Self-host
```bash
git clone https://github.com/devyourown/tally && cd tally/deploy
cp .env.example .env     # set TALLY_DOMAIN, TALLY_JWT_SECRET, DB password, Apple/Google client ids
docker compose up -d
```
Caddy obtains TLS automatically for `TALLY_DOMAIN`. In the app, open Settings → Server URL and point it at your domain. See [docs/API.md](docs/API.md) for environment variables.

## Develop
```bash
# database
docker compose -f deploy/docker-compose.dev.yml up -d
# server (dev profile enables /auth/dev and naive sync)
cd server && ./gradlew bootRun --args='--spring.profiles.active=dev'
# app (iOS simulator)
cd app && flutter run --dart-define=DEV_LOGIN=true --dart-define=TALLY_SERVER_URL=http://localhost:8080
```
Tests: `cd server && ./gradlew test` · `cd app && flutter test --exclude-tags hyojun`.

## Design
- Money is stored as integers in the currency's minor unit; splits are stored as final per-member amounts.
- Sync is an append-only event log per group with a server-assigned sequence; pushes are idempotent via `(group_id, client_id)`.
- The app keeps a full local copy (SQLite) and computes balances locally, so it works offline.
- Contract: [docs/API.md](docs/API.md). Spec: [docs/superpowers/specs](docs/superpowers/specs).

## License
[AGPL-3.0](LICENSE). You can run, modify and redistribute Tally; if you offer a modified server to others over a network, you must publish your changes.
