---
name: backend-drf
description: Scaffolds Django REST Framework backends with uv, ruff, pyproject.toml, per-app tests/, and Makefile Django targets (migrate, makemigrations, startapp, createsuperuser, coverage, migration reset). Django project initialization is human-only — the agent creates folder stubs and provides exact official commands. Use when creating DRF backends, adding manage.py Make targets, or when project-scaffold selects DRF over FastAPI.
---

# Backend DRF

## When to use

- Projects needing Django admin
- Complex permissions, serializers, and ORM-heavy workflows
- Teams already invested in the Django ecosystem

Use **backend-fastapi** for lightweight APIs without admin or heavy Django infrastructure.

## Environment

Settings read from env vars (`DATABASE_URL`, `SECRET_KEY`, etc.) via `python-dotenv` in `config/settings.py`. Locally, **env-secrets** loads them via `.envrc`/direnv from gitignored `.env`. In Docker, Compose passes the same `.env` via `env_file`.

## Stack

| Tool | Purpose |
|------|---------|
| uv | Package manager and virtual env |
| ruff | Linting and formatting |
| pyproject.toml | Project config and dependencies |
| Django + DRF | Web framework and REST API |
| PostgreSQL | Database (via psycopg) |
| Django TestCase / APITestCase | Testing (see django-test-generation) |

## Directory layout (after human init)

```
backend/
├── pyproject.toml
├── uv.lock
├── manage.py
├── config/              # Django project package (settings, urls, wsgi)
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── api/
    └── <app>/
        ├── __init__.py
        ├── models.py
        ├── serializers.py
        ├── views.py
        ├── urls.py
        └── tests/
            ├── __init__.py
            └── test_<area>.py
```

Each Django app has its own `tests/` directory.

## Scaffold workflow

### Phase 1 — Agent creates stubs only

1. **Create** empty `backend/` directory.
2. **Create** `backend/pyproject.toml` with Django/DRF deps (see [reference.md](reference.md)).
3. **Create** `.gitkeep` or placeholder files as needed.
4. **Print** the human-init commands below — do NOT execute them.

### Phase 2 — Human runs official Django commands

Provide these exact commands for the user to run inside `backend/`:

```bash
cd backend

# Initialize uv project (if not already done)
uv init --no-readme

# Add dependencies
uv add django djangorestframework psycopg[binary] python-dotenv
uv add --dev ruff pytest-django factory-boy coverage

# Create Django project
uv run django-admin startproject config .

# Create apps (repeat per feature)
uv run python manage.py startapp users api/users
```

Adjust app names and paths to match the project. `startproject` **must** be run by the human.
After Compose exists, further apps use `make startapp APP=name` (not a host `manage.py`).

### Phase 3 — Agent continues after human init

Once the user confirms Django init is done:

1. **Configure** `config/settings.py`: add `rest_framework`, database from `DATABASE_URL`, installed apps.
2. **Configure** `config/urls.py`: include app URL patterns under `/api/`.
3. **Set up** ruff in `pyproject.toml`.
4. **Create** `tests/` directories inside each app.
5. **Point** to **django-test-generation** for writing tests.

## pyproject.toml essentials

```toml
[project]
name = "PROJECT_SLUG"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "django>=5.1",
    "djangorestframework>=3.15",
    "psycopg[binary]>=3.2",
    "python-dotenv>=1.0",
]

[dependency-groups]
dev = [
    "ruff>=0.8",
    "pytest-django>=4.9",
    "factory-boy>=3.3",
    "coverage>=7.6",
]

[tool.ruff]
target-version = "py312"
line-length = 100
```

## Makefile — Django section

**makefile-operations** owns lifecycle (`up`/`down`/`build`, never `start`/`stop`), `uv-*` /
`bun-*`, shells, `logs-*` (never `show-*-logs`), `lint` / `format` / `lint-fix`, and nuclear `clean`.
This skill owns every `manage.py` target. Copy the full section from [reference.md](reference.md).

| Target | Notes |
|--------|--------|
| `startapp` | `APP=name`; always created at `api/$(APP)`. `run --rm`. After Docker exists, this is how new apps are added — not a raw `manage.py` on the host. |
| `createsuperuser` | `exec` **without** `-T` so the interactive prompts work. |
| `migrate` | Bare verb. `exec -T` when the stack is up; `run --rm` if it is not. |
| `migrate-seed` | `migrate` then `loaddata seeds`. |
| `makemigrations` | Same transport as `migrate`. |
| `db-load-schema-test` | Test-settings migrate; CI calls this before the suite. |
| `test-backend` | `manage.py test --verbosity=1 --force-color --noinput --failfast`. Filter with `TEST=` (Django label/path), not a second `tests` target and not pytest `-k`. |
| `coverage` / `coverage-html` | `coverage run manage.py test` then `report` or `html`. HTML lands in `backend/htmlcov/`. |
| `delete-migrations` | Danger zone. Deletes `backend/api/*/migrations/*.py` except `__init__.py`. |
| `db-reset-full` | Danger zone. `delete-migrations`, drop/recreate `public` schema, `makemigrations`, `migrate`. Do not chain `format` into it. |

After `make up` / `make build`, echo:

```
Django Admin: http://localhost:8000/admin/
Swagger:      http://localhost:8000/api/docs/
ReDoc:        http://localhost:8000/api/redoc/
Frontend:     http://localhost:3000/
```

(`api/docs` / `api/redoc` assume spectacular or equivalent is wired; still print them so the
local surface is discoverable.)

## Agent may write

- `pyproject.toml` stub before human init
- Settings, URLs, serializers, views after human init
- `tests/` directories and test files (via django-test-generation)
- The Django Makefile section (via **makefile-operations** conventions)

## Agent must NOT execute

- `django-admin startproject`
- `python manage.py startapp` on the host — use `make startapp APP=…` once Compose exists
- `python manage.py migrate` / `db-reset-full` / `delete-migrations` unless the user explicitly
  requests them and containers are running

## Testing conventions

- Use Django native unit tests: `APITestCase` + `APIClient`
- Tests live in `tests/` inside each app, not a top-level `tests/` folder
- Run via `make test-backend` or `make test-backend TEST=api.users`
- See **django-test-generation** skill for detailed patterns

## Integration with sibling skills

| Skill | When |
|-------|------|
| dockerization-template | Docker setup with `runserver` dev command |
| makefile-operations | Generic `up`/`down`/`uv-*`/`bun-*`/`lint`/`logs-*`/`clean`; splice this skill's Django section in |
| django-test-generation | Writing DRF endpoint tests |
| github-actions | CI calls `make lint` / `make test` |

## Additional resources

- Settings, URLs, and the Django Makefile section: [reference.md](reference.md)
