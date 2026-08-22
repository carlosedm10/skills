# Makefile reference templates

Replace `PROJECT_SLUG` with the project slug.

These templates obey the conventions in `SKILL.md`: compose-named lifecycle (`up`/`down`/`build`,
never `start`/`stop`), a logs ladder with no `show-` prefix, DBs excluded from app logs, DB
targets named for the operation, atomic-before-aggregate ordering, and a nuclear `clean` in the
danger zone.

## Starter Makefile — FastAPI stack

```makefile
# ------------------------------ Docker Compose ------------------------------ #
.PHONY: build up down restart

build:
	@echo ":: build: ."
	docker compose build

up:
	@echo ":: up: ."
	docker compose up -d

down:
	@echo ":: down: ."
	docker compose down --remove-orphans

restart:
	@echo ":: restart: ."
	docker compose restart

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

# Usage:
#   make bun-add PKG=package
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
.PHONY: logs-backend logs-frontend logs-db logs

# App logs never include the database — that is logs-db.
logs-backend:
	docker compose logs -f backend-PROJECT_SLUG

logs-frontend:
	docker compose logs -f frontend-PROJECT_SLUG

logs-db:
	docker compose logs -f postgres-PROJECT_SLUG

logs:
	docker compose logs -f backend-PROJECT_SLUG frontend-PROJECT_SLUG

# ----------------------------- FastAPI / Alembic ----------------------------- #
.PHONY: migrate alembic-revision db-load-schema-test

# migrate is deliberately bare — the verb the framework's own docs use.
migrate:
	docker compose exec -T backend-PROJECT_SLUG uv run alembic upgrade head

alembic-revision:
	docker compose exec -T backend-PROJECT_SLUG uv run alembic revision --autogenerate -m "$(MSG)"

db-load-schema-test:
	docker compose exec -T -e ENV=test backend-PROJECT_SLUG uv run alembic upgrade head

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

# ----------------------------- ⛔️ DANGER ZONE ⛔️ ----------------------------- #
.PHONY: clean

# NUCLEAR: drops named volumes, database included. `make up` + `make migrate` rebuilds from zero.
clean:
	docker compose down --volumes --remove-orphans
```

## Starter Makefile — DRF stack

Same as FastAPI except replace the **FastAPI / Alembic** section with:

```makefile
# ----------------------------- Django ----------------------------- #
.PHONY: migrate migrate-seed makemigrations db-load-schema-test

migrate:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py migrate

migrate-seed: migrate
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py loaddata seeds

makemigrations:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py makemigrations

db-load-schema-test:
	docker compose exec -T -e DJANGO_SETTINGS_MODULE=config.settings.test backend-PROJECT_SLUG uv run python manage.py migrate
```

And change `test-backend`:

```makefile
test-backend:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py test
```

## Backend-only variant

Omit frontend sections, drop `logs-frontend`, and change the aggregates:

```makefile
logs:
	docker compose logs -f backend-PROJECT_SLUG

lint:
	make lint-backend

test:
	make test-backend
```

## Fractal variant — one Makefile per deployable

When the repo holds more than one deployable, split the single file above along the tree. The
root keeps only forwards and cross-child ordering; each child owns bare verbs.

Root `Makefile`:

```makefile
# ------------------------------ Docker Compose ------------------------------ #
.PHONY: build-backend build-frontend build up down

build-backend:
	$(MAKE) -C backend build

build-frontend:
	$(MAKE) -C frontend build

build: build-backend build-frontend

up:
	$(MAKE) -C backend up
	$(MAKE) -C frontend up

down:
	$(MAKE) -C frontend down
	$(MAKE) -C backend down

# ----------------------------- Testing ----------------------------- #
.PHONY: test-backend test-frontend test

test-backend:
	$(MAKE) -C backend test

test-frontend:
	$(MAKE) -C frontend test

test: test-backend test-frontend
```

`frontend/Makefile` — bare verbs only, and it narrates its own phases:

```makefile
.PHONY: build up down logs shell lint test

build:
	@echo ":: build: frontend"
	docker compose build frontend-PROJECT_SLUG

up:
	@echo ":: up: frontend"
	docker compose up -d frontend-PROJECT_SLUG

down:
	@echo ":: down: frontend"
	docker compose down --remove-orphans

logs:
	docker compose logs -f frontend-PROJECT_SLUG

shell:
	docker compose exec frontend-PROJECT_SLUG sh

lint:
	docker compose exec -T frontend-PROJECT_SLUG bun run lint

test:
	docker compose exec -T frontend-PROJECT_SLUG bun run test
```

Sibling services of the same shape (`backend/api/`, `backend/worker/`) keep identity variables
plus a guarded `include` of `backend/makefiles/service.mk`, where the recipes live once:

```makefile
SERVICE      := api
SERVICE_ROOT := $(CURDIR)

ifneq (,$(wildcard ../makefiles/service.mk))
include ../makefiles/service.mk
else
shell:                         # in-pod fallback: the engine is outside the build context
	sh
endif
```

## Transport switch (CI/local parity)

Put this at the top of the shared engine so every recipe is written once and CI runs it natively:

```makefile
ifneq ($(filter true 1,$(CI) $(NATIVE)),)
define run_backend
cd $(SERVICE_ROOT) && $(1)
endef
else
define run_backend
docker compose run --rm backend-PROJECT_SLUG sh -c '$(1)'
endef
endif

test:
	@echo ":: test: $(SERVICE)"
	$(call run_backend,uv run pytest)
```
