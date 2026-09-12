# Hetzner deploy — templates

Replace every `APP_SLUG`, `APP_HOSTNAME`, `WEB_LOOPBACK_PORT`, `API_LOOPBACK_PORT`,
and `ACME_EMAIL` before writing files. Never leave a real IP, hostname, or secret
in these templates.

## Repo layout (app)

```
repo-root/
├── compose.yaml                         # local dev — dockerization-template
├── compose.prod.yaml                    # this skill
├── deploy/
│   ├── bootstrap.sh                     # once per VPS (first app only)
│   ├── remote-deploy.sh
│   ├── env.production.example
│   └── host/edge/
│       ├── compose.yaml
│       ├── Caddyfile
│       ├── .env.example
│       └── sites/
│           └── APP_SLUG.caddy
└── .github/workflows/
    ├── ci.yml                           # github-actions skill
    └── deploy.yml                       # this skill
```

Edge files under `deploy/host/edge/` are the **source** copied onto
`/opt/apps/edge` during bootstrap. Later apps only add a snippet under `sites/`.

---

## compose.prod.yaml

Publish only on loopback. Prefix networks and volumes with `APP_SLUG`. Do not
publish Postgres (or other data stores) on the host.

### Frontend-only (e.g. Next on 3000)

```yaml
name: APP_SLUG

services:
  web:
    container_name: APP_SLUG_web
    build:
      context: .
      dockerfile: docker/frontend.Dockerfile
      target: production
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "127.0.0.1:WEB_LOOPBACK_PORT:3000"
    networks:
      - appnet_APP_SLUG

networks:
  appnet_APP_SLUG:
```

### Full-stack (web + API)

```yaml
name: APP_SLUG

services:
  web:
    container_name: APP_SLUG_web
    build:
      context: .
      dockerfile: docker/frontend.Dockerfile
      target: production
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "127.0.0.1:WEB_LOOPBACK_PORT:3000"
    depends_on:
      - api
    networks:
      - appnet_APP_SLUG

  api:
    container_name: APP_SLUG_api
    build:
      context: .
      dockerfile: docker/backend.Dockerfile
      target: production
    restart: unless-stopped
    env_file:
      - .env
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
    ports:
      - "127.0.0.1:API_LOOPBACK_PORT:8000"
    depends_on:
      db:
        condition: service_healthy
    networks:
      - appnet_APP_SLUG

  db:
    container_name: APP_SLUG_db
    image: postgres:16-alpine
    restart: unless-stopped
    env_file:
      - .env
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data_APP_SLUG:/var/lib/postgresql/data
    networks:
      - appnet_APP_SLUG
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    # no ports: — db is not reachable from the host or the internet

volumes:
  postgres_data_APP_SLUG:

networks:
  appnet_APP_SLUG:
```

Use a **production** Docker target (no bind mounts, no `--reload`). The local
**dockerization-template** images are for `bun run dev` / uvicorn `--reload`;
do not ship those as prod. Add a `production` stage (examples below). Adapt
internal container ports if the app does not listen on 3000/8000.

### Static

Same as frontend-only: a tiny image that serves the built files (Caddy or nginx
in the app container) on an internal port, published as
`127.0.0.1:WEB_LOOPBACK_PORT:80`.

### Production Docker stages

Add a `production` target to the existing Dockerfiles (keep the current default
stage for local compose). `compose.prod.yaml` uses `target: production`.

**Frontend (Next, Bun)** — build then `bun run start`; bind `0.0.0.0` inside the
container (host publish is still loopback):

```dockerfile
FROM oven/bun:1.2.5 AS deps
WORKDIR /code
COPY frontend/package.json frontend/bun.lock* ./
RUN bun install --frozen-lockfile

FROM deps AS production
COPY frontend/ .
RUN bun run build
ENV NODE_ENV=production
EXPOSE 3000
CMD ["bun", "run", "start", "--", "--hostname", "0.0.0.0", "--port", "3000"]
```

**Frontend (Vite static)** — build, then serve `dist/` with Caddy:

```dockerfile
FROM oven/bun:1.2.5 AS build
WORKDIR /code
COPY frontend/package.json frontend/bun.lock* ./
RUN bun install --frozen-lockfile
COPY frontend/ .
RUN bun run build

FROM caddy:2-alpine AS production
COPY --from=build /code/dist /usr/share/caddy
COPY deploy/Caddyfile.static /etc/caddy/Caddyfile
EXPOSE 80
```

`deploy/Caddyfile.static`:

```caddy
:80 {
	root * /usr/share/caddy
	encode gzip
	file_server
	try_files {path} /index.html
}
```

**Backend (FastAPI + uv)** — no `--reload`, no bind-mount:

```dockerfile
FROM python:3.12-slim AS production
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
ENV UV_PROJECT_ENVIRONMENT=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY backend/pyproject.toml backend/uv.lock* ./
RUN uv sync --frozen --no-install-project --no-dev \
  || (uv lock && uv sync --no-install-project --no-dev)
COPY backend/ .
EXPOSE 8000
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Adjust the ASGI path and, for DRF, the `CMD` (`gunicorn` or
`uvicorn config.asgi:application` — not `runserver`).

---

## Caddy snippet — `deploy/host/edge/sites/APP_SLUG.caddy`

Edge Caddy reaches loopback-published ports via `host.docker.internal`.

### Frontend-only or static

```caddy
APP_HOSTNAME {
	encode gzip
	reverse_proxy host.docker.internal:WEB_LOOPBACK_PORT
}
```

### Full-stack (hostname + API hostname)

```caddy
APP_HOSTNAME {
	encode gzip
	reverse_proxy host.docker.internal:WEB_LOOPBACK_PORT
}

api.APP_HOSTNAME {
	encode gzip
	reverse_proxy host.docker.internal:API_LOOPBACK_PORT
}
```

### Full-stack (path-based API)

```caddy
APP_HOSTNAME {
	encode gzip
	handle /api/* {
		reverse_proxy host.docker.internal:API_LOOPBACK_PORT
	}
	handle {
		reverse_proxy host.docker.internal:WEB_LOOPBACK_PORT
	}
}
```

TLS is automatic (Caddy ACME) as long as DNS for `APP_HOSTNAME` points at the
VPS and ports 80/443 are open.

---

## Shared edge (first app on a new VPS)

Copied to `/opt/apps/edge` by bootstrap. Later apps do not recreate this.

### `deploy/host/edge/Caddyfile`

```caddy
{
	email {$ACME_EMAIL}
}

import /etc/caddy/sites/*.caddy
```

### `deploy/host/edge/compose.yaml`

```yaml
name: edge

services:
  caddy:
    image: caddy:2
    container_name: edge_caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      ACME_EMAIL: ${ACME_EMAIL}
    env_file:
      - .env
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./sites:/etc/caddy/sites:ro
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
```

`host-gateway` is required on Linux so Caddy can proxy to `127.0.0.1` on the VM.

### `deploy/host/edge/.env.example`

```env
ACME_EMAIL=ops@example.com
```

On the server: `cp .env.example .env` under `/opt/apps/edge` and set a real
contact email. Do not commit the server `.env`.

---

## `deploy/remote-deploy.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_SLUG="$(basename "$APP_DIR")"
EDGE_DIR="/opt/apps/edge"
SNIPPET="${APP_DIR}/deploy/host/edge/sites/${APP_SLUG}.caddy"

cd "${APP_DIR}"

if [[ ! -f .env ]]; then
  echo "missing ${APP_DIR}/.env — copy deploy/env.production.example and edit on the server" >&2
  exit 1
fi

docker compose -f compose.prod.yaml --env-file .env up -d --build --remove-orphans

if [[ -f "${SNIPPET}" ]]; then
  mkdir -p "${EDGE_DIR}/sites"
  cp "${SNIPPET}" "${EDGE_DIR}/sites/${APP_SLUG}.caddy"
  docker compose -f "${EDGE_DIR}/compose.yaml" --env-file "${EDGE_DIR}/.env" \
    exec -T caddy caddy reload --config /etc/caddy/Caddyfile
fi
```

Make it executable in git: `chmod +x deploy/remote-deploy.sh`.

The snippet filename must match the directory name (`APP_SLUG`). If they differ,
set `APP_SLUG` explicitly at the top of the script instead of using `basename`.

---

## `deploy/env.production.example`

Document keys with placeholders only. Real values go in `/opt/apps/APP_SLUG/.env`.

```env
# Copy to /opt/apps/APP_SLUG/.env on the server. Never commit that file.

# APP_HOSTNAME=app.example.com
# Public URL the frontend uses, if needed:
# NEXT_PUBLIC_SITE_URL=https://app.example.com

# Full-stack / database (omit for frontend-only / static):
POSTGRES_USER=app
POSTGRES_PASSWORD=change-me
POSTGRES_DB=app
# DATABASE_URL is composed in compose.prod.yaml from the above when possible.
```

Keep this file in sync with **env-secrets** (`.env` gitignored). Prefer
`env.production.example` over putting production-only keys in `.env_template`.

---

## `.github/workflows/deploy.yml`

Does not duplicate lint/test (those stay in `ci.yml` via **github-actions**).
Rsync **must** exclude `.env`.

Default: deploy on push to `main`. Gate with branch protection (required CI
checks) so a red `ci.yml` cannot merge. Alternatives below if you cannot use
branch protection.

```yaml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: deploy-production
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://APP_HOSTNAME
    env:
      DEPLOY_HOST: ${{ secrets.DEPLOY_HOST || vars.DEPLOY_HOST }}
      DEPLOY_USER: ${{ secrets.DEPLOY_USER || vars.DEPLOY_USER }}
      DEPLOY_PATH: ${{ vars.DEPLOY_PATH }}
      DEPLOY_SSH_PORT: ${{ vars.DEPLOY_SSH_PORT || 22 }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup SSH
        run: |
          install -m 700 -d ~/.ssh
          printf '%s\n' "${{ secrets.DEPLOY_SSH_KEY }}" > ~/.ssh/deploy_key
          chmod 600 ~/.ssh/deploy_key
          ssh-keyscan -p "${DEPLOY_SSH_PORT}" -H "${DEPLOY_HOST}" >> ~/.ssh/known_hosts

      - name: Rsync
        run: |
          rsync -az --delete \
            --exclude '.git/' \
            --exclude '.env' \
            --exclude '.env.*' \
            --exclude 'node_modules/' \
            --exclude '.next/' \
            --exclude '__pycache__/' \
            -e "ssh -i ~/.ssh/deploy_key -p ${DEPLOY_SSH_PORT}" \
            ./ "${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/"

      - name: Remote deploy
        run: |
          ssh -i ~/.ssh/deploy_key -p "${DEPLOY_SSH_PORT}" \
            "${DEPLOY_USER}@${DEPLOY_HOST}" \
            "bash ${DEPLOY_PATH}/deploy/remote-deploy.sh"
```

Never print `DEPLOY_SSH_KEY`. Never rsync a local `.env`.

**Optional — wait for CI in-workflow** (requires `on.workflow_call` on `ci.yml`):

```yaml
jobs:
  ci:
    uses: ./.github/workflows/ci.yml
  deploy:
    needs: ci
    # ...same deploy job
```

**Optional — `workflow_run`** (no change to `ci.yml`):

```yaml
on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]
```

Skip the deploy job unless `github.event.workflow_run.conclusion == 'success'`.

---

## Bootstrap — `deploy/bootstrap.sh` (once per machine)

Run as root (or with sudo) from a checkout on the VPS **or** after copying this
directory. Idempotent enough to re-run: it should not wipe `authorized_keys` or
edge `.env`.

```bash
#!/usr/bin/env bash
set -euo pipefail

DEPLOY_USER="${DEPLOY_USER:-deploy}"
APPS_ROOT="${APPS_ROOT:-/opt/apps}"
EDGE_DIR="${APPS_ROOT}/edge"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EDGE_SRC="${SCRIPT_DIR}/host/edge"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "bootstrap as root" >&2
  exit 1
fi

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git rsync ufw

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi

if ! id -u "${DEPLOY_USER}" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "${DEPLOY_USER}"
fi
usermod -aG docker "${DEPLOY_USER}"

install -d -m 755 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" "${APPS_ROOT}"
install -d -m 700 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" "/home/${DEPLOY_USER}/.ssh"
AUTH_KEYS="/home/${DEPLOY_USER}/.ssh/authorized_keys"
touch "${AUTH_KEYS}"
chown "${DEPLOY_USER}:${DEPLOY_USER}" "${AUTH_KEYS}"
chmod 600 "${AUTH_KEYS}"

install -d -m 755 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" "${EDGE_DIR}"
install -d -m 755 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" "${EDGE_DIR}/sites"
if [[ -d "${EDGE_SRC}" ]]; then
  cp "${EDGE_SRC}/compose.yaml" "${EDGE_DIR}/compose.yaml"
  cp "${EDGE_SRC}/Caddyfile" "${EDGE_DIR}/Caddyfile"
  if [[ ! -f "${EDGE_DIR}/.env" && -f "${EDGE_SRC}/.env.example" ]]; then
    cp "${EDGE_SRC}/.env.example" "${EDGE_DIR}/.env"
    chmod 600 "${EDGE_DIR}/.env"
    echo "edit ${EDGE_DIR}/.env (ACME_EMAIL) before starting Caddy" >&2
  fi
  chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${EDGE_DIR}"
fi

ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "bootstrap ok. Add the Actions public key to ${AUTH_KEYS}"
echo "Then: su - ${DEPLOY_USER} -c 'cd ${EDGE_DIR} && docker compose up -d'"
```

Do **not** append a public key from this script unless the operator passes it
explicitly (e.g. `DEPLOY_PUBKEY` env). Prefer a manual append so a stray key
never lands in git.

After bootstrap, start edge as `deploy`:

```bash
cd /opt/apps/edge
# edit .env — ACME_EMAIL
docker compose up -d
```

---

## rsync exclude contract

Always exclude at least:

```
.git/
.env
.env.*
node_modules/
.next/
__pycache__/
```

`--delete` keeps the server tree aligned with git **except** excluded files.
Because `.env` is excluded, `--delete` will not remove it.

---

## Firewall

| Open | Closed |
|------|--------|
| 22, 80, 443 | `WEB_LOOPBACK_PORT`, `API_LOOPBACK_PORT`, Postgres, Docker-published app ports |

Loopback binds are not reachable from the internet even if ufw is misconfigured
for that port; still do not publish them on `0.0.0.0`.

---

## SSH key generation (operator laptop)

Actions private key stays in GitHub Secrets. Public key goes in
`/home/deploy/.ssh/authorized_keys`.

```bash
ssh-keygen -t ed25519 -f ./deploy_actions -C "github-actions-APP_SLUG" -N ""
# public → server authorized_keys
# private → GitHub secret DEPLOY_SSH_KEY  (contents of ./deploy_actions)
```

Do not commit `deploy_actions` or `deploy_actions.pub` into the app repo if the
private key was generated in the working tree — generate under `~/.ssh/` or
delete local files after storing the secret.

A separate **personal** key is for interactive SSH. It is not `DEPLOY_SSH_KEY`.
