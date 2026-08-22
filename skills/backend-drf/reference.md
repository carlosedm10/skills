# Backend DRF reference templates

Replace `PROJECT_SLUG` with the project slug.

## config/settings.py (database + DRF additions)

```python
import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ.get("SECRET_KEY", "dev-only-change-me")
DEBUG = os.environ.get("DEBUG", "true").lower() == "true"
ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "*").split(",")

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    # "api.users",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("POSTGRES_DB", "PROJECT_SLUG"),
        "USER": os.environ.get("POSTGRES_USER", "postgres"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD", "postgres"),
        "HOST": os.environ.get("POSTGRES_HOST", "postgres-PROJECT_SLUG"),
        "PORT": os.environ.get("POSTGRES_PORT", "5432"),
    }
}

REST_FRAMEWORK = {
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
}

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True
STATIC_URL = "static/"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
```

## config/urls.py

```python
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    # path("api/users/", include("api.users.urls")),
]
```

## Human-init command block (copy-paste for user)

```bash
cd backend
uv init --no-readme
uv add django djangorestframework psycopg[binary] python-dotenv
uv add --dev ruff factory-boy coverage
uv run django-admin startproject config .
uv run python manage.py startapp users api/users
```

Adjust app names to match the project structure.

## Makefile — Django section

Splice this into the project Makefile in place of a FastAPI/Alembic section. Replace
`PROJECT_SLUG`. Lifecycle, package managers, shells, logs, lint, and `clean` stay in
**makefile-operations**.

After `up` / `build`, echo:

```makefile
	@echo "Django Admin: http://localhost:8000/admin/"
	@echo "Swagger:      http://localhost:8000/api/docs/"
	@echo "ReDoc:        http://localhost:8000/api/redoc/"
	@echo "Frontend:     http://localhost:3000/"
```

```makefile
# ----------------------------- Django ----------------------------- #
.PHONY: startapp createsuperuser migrate migrate-seed makemigrations db-load-schema-test

# Usage: make startapp APP=app_name  — always created under api/
startapp:
	docker compose run --rm backend-PROJECT_SLUG uv run python manage.py startapp $(APP) api/$(APP)

createsuperuser:
	docker compose exec backend-PROJECT_SLUG uv run python manage.py createsuperuser

migrate:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py migrate

migrate-seed: migrate
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py loaddata seeds

makemigrations:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py makemigrations

db-load-schema-test:
	docker compose exec -T -e DJANGO_SETTINGS_MODULE=config.settings.test backend-PROJECT_SLUG uv run python manage.py migrate

# ----------------------------- Testing ----------------------------- #
# Keep test-frontend / test aggregates from makefile-operations. Replace test-backend with:

.PHONY: test-backend coverage coverage-html

# Usage:
#   make test-backend
#   make test-backend TEST=api.users
test-backend:
	docker compose exec -T backend-PROJECT_SLUG sh -ceu 'cd /app && uv run python manage.py test --verbosity=1 --force-color --noinput --failfast $(TEST)'

coverage:
	docker compose exec -T backend-PROJECT_SLUG sh -ceu 'cd /app && uv run coverage run manage.py test --verbosity=1 --noinput && uv run coverage report'

coverage-html:
	docker compose exec -T backend-PROJECT_SLUG sh -ceu 'cd /app && uv run coverage run manage.py test --verbosity=1 --noinput && uv run coverage html'

# ----------------------------- ⛔️ DANGER ZONE ⛔️ ----------------------------- #
# Keep `clean` / `clean-builder` from makefile-operations. Add these Django-only atomics:

.PHONY: delete-migrations db-reset-full

delete-migrations:
	find ./backend/api/*/migrations -type f -name "*.py" ! -name "__init__.py" -delete

db-reset-full: delete-migrations
	@echo "WARNING: drops ALL tables in the compose Postgres and recreates migrations."
	docker compose exec -T postgres-PROJECT_SLUG psql -U postgres -d postgres -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO postgres; GRANT ALL ON SCHEMA public TO public;" || true
	docker compose run --rm backend-PROJECT_SLUG uv run python manage.py makemigrations
	docker compose run --rm backend-PROJECT_SLUG uv run python manage.py migrate
```

