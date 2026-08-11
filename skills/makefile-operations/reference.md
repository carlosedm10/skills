# Makefile reference templates

Replace `PROJECT_SLUG` with the project slug.

## Starter Makefile — FastAPI stack

```makefile
# ------------------------------ Docker Compose ------------------------------ #
.PHONY: build start stop

build:
	docker compose build

start:
	docker compose up -d

stop:
	docker compose down --remove-orphans

# ----------------------------- Backend Package Management ----------------------------- #
.PHONY: uv-lock uv-add uv-update uv-remove uv-lock-regenerate

# Usage:
#   make uv-add PKG="package[extras]==version"
#   make uv-update
#   make uv-update PKG=foo
#   make uv-remove PKG=foo
uv-lock:
	docker compose run --rm backend-PROJECT_SLUG uv lock

uv-add:
	docker compose run --rm backend-PROJECT_SLUG uv add $(PKG)

uv-update:
ifeq ($(PKG),)
	docker compose run --rm backend-PROJECT_SLUG uv lock --upgrade
else
	docker compose run --rm backend-PROJECT_SLUG uv lock --upgrade-package $(PKG)
endif

uv-remove:
	docker compose run --rm backend-PROJECT_SLUG uv remove $(PKG)

uv-lock-regenerate:
	docker compose run --rm backend-PROJECT_SLUG uv lock --refresh

# ----------------------------- Frontend Package Management ----------------------------- #
.PHONY: bun-add bun-update bun-remove

bun-add:
	docker compose exec -T frontend-PROJECT_SLUG bun add $(PKG)

bun-update:
	docker compose exec -T frontend-PROJECT_SLUG bun update $(PKG)

bun-remove:
	docker compose exec -T frontend-PROJECT_SLUG bun remove $(PKG)

# ----------------------------- Terminals ----------------------------- #
.PHONY: backend-shell frontend-shell postgres-shell

backend-shell:
	docker compose exec backend-PROJECT_SLUG sh

frontend-shell:
	docker compose exec frontend-PROJECT_SLUG sh

postgres-shell:
	docker compose exec postgres-PROJECT_SLUG psql -U $${POSTGRES_USER:-postgres} -d $${POSTGRES_DB:-PROJECT_SLUG}

# ----------------------------- Debugging ----------------------------- #
.PHONY: show-backend-logs show-frontend-logs show-postgres-logs

show-backend-logs:
	docker compose logs -f backend-PROJECT_SLUG

show-frontend-logs:
	docker compose logs -f frontend-PROJECT_SLUG

show-postgres-logs:
	docker compose logs -f postgres-PROJECT_SLUG

# ----------------------------- FastAPI / Alembic ----------------------------- #
.PHONY: alembic-upgrade alembic-revision

alembic-upgrade:
	docker compose exec -T backend-PROJECT_SLUG uv run alembic upgrade head

alembic-revision:
	docker compose exec -T backend-PROJECT_SLUG uv run alembic revision --autogenerate -m "$(MSG)"

# ----------------------------- Code Formatting ----------------------------- #
.PHONY: lint-backend lint-frontend lint

lint-backend:
	docker compose exec -T backend-PROJECT_SLUG uv run ruff check .

lint-frontend:
	docker compose exec -T frontend-PROJECT_SLUG bun run lint

lint:
	make lint-backend
	make lint-frontend

# ----------------------------- Testing ----------------------------- #
.PHONY: test-backend test-frontend test

test-backend:
	docker compose exec -T backend-PROJECT_SLUG uv run pytest

test-frontend:
	docker compose exec -T frontend-PROJECT_SLUG bun run test

test:
	make test-backend
	make test-frontend
```

## Starter Makefile — DRF stack

Same as FastAPI except replace the **FastAPI / Alembic** section with:

```makefile
# ----------------------------- Django ----------------------------- #
.PHONY: migrate makemigrations

migrate:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py migrate

makemigrations:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py makemigrations
```

And change `test-backend`:

```makefile
test-backend:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py test
```

## Backend-only variant

Omit frontend sections and change aggregates:

```makefile
lint:
	make lint-backend

test:
	make test-backend
```
