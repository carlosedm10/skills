# Project Scaffold reference

## Intake question template

Use these when starting a new project:

```
I'll scaffold a new project. A few questions first:

1. **Project slug** (lowercase, no spaces — e.g. `acme`): ?
2. **Backend**: FastAPI (default, lightweight API) or DRF (Django admin, complex permissions)?
3. **Frontend**: React/Vite (webapp), Next (landing/SSR), or none (backend-only)?
4. **Docker + Postgres**: yes (default) or no?
```

## Backend-only scaffold

Omit `frontend/` and frontend Docker service. Adjust Makefile aggregates:

```makefile
lint:
	make lint-backend

test:
	make test-backend
```

Adjust compose.yaml to remove `frontend-PROJECT_SLUG` service.

## No-Docker scaffold

Skip steps 4 (dockerization) partially:

- Do not create `docker/`, `compose.yaml`
- Makefile targets run tools directly (no `docker compose exec`)
- GitHub Actions runs `make lint` / `make test` without Docker setup steps

## .gitignore (full)

```
# Environment
.env

# Python
__pycache__/
*.pyc
*.pyo
.venv/
*.egg-info/
.eggs/
dist/
build/
.pytest_cache/
.ruff_cache/
.mypy_cache/
htmlcov/
.coverage

# Node
node_modules/
dist/
.next/
.turbo/
out/

# Docker
postgres_data_*/

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# Alembic
alembic/versions/*.pyc
```

## Post-scaffold verification checklist

```
- [ ] backend/ has pyproject.toml
- [ ] frontend/ exists (if applicable)
- [ ] docker/ has 3 Dockerfiles (if Docker enabled)
- [ ] compose.yaml at repo root (if Docker enabled)
- [ ] Makefile has lint, test, build targets
- [ ] .github/workflows/ci.yml calls only make targets
- [ ] .env_template exists, .env in .gitignore
- [ ] Human-init checklist printed
```
