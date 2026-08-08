---
name: backend-drf
description: Scaffolds Django REST Framework backends with uv, ruff, pyproject.toml, and per-app tests/ directories. Django project initialization is human-only — the agent creates folder stubs and provides exact official commands. Use when creating DRF backends or when project-scaffold selects DRF over FastAPI.
---

# Backend DRF

## When to use

- Projects needing Django admin
- Complex permissions, serializers, and ORM-heavy workflows
- Teams already invested in the Django ecosystem

Use **backend-fastapi** for lightweight APIs without admin or heavy Django infrastructure.

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
uv add --dev ruff pytest-django

# Create Django project
uv run django-admin startproject config .

# Create apps (repeat per feature)
uv run python manage.py startapp users api/users
```

Adjust app names and paths to match the project. The `startproject` and `startapp` commands **must** be run by the human — the agent cannot execute them.

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
]

[tool.ruff]
target-version = "py312"
line-length = 100
```

## Agent may write

- `pyproject.toml` stub before human init
- Settings, URLs, serializers, views after human init
- `tests/` directories and test files (via django-test-generation)

## Agent must NOT execute

- `django-admin startproject`
- `python manage.py startapp`
- `python manage.py migrate` (unless user explicitly requests and containers are running)

## Testing conventions

- Use Django native unit tests: `APITestCase` + `APIClient`
- Tests live in `tests/` inside each app, not a top-level `tests/` folder
- See **django-test-generation** skill for detailed patterns

## Integration with sibling skills

| Skill | When |
|-------|------|
| dockerization-template | Docker setup with `runserver` dev command |
| makefile-operations | `migrate`, `makemigrations`, `test-backend` (manage.py test) |
| django-test-generation | Writing DRF endpoint tests |
| github-actions | CI calls `make lint` / `make test` |

## Additional resources

- Settings and URL templates: [reference.md](reference.md)
