---
name: makefile-operations
description: Manages Makefile-driven Docker Compose workflows with safe command ordering, container lifecycle hygiene, logs, terminal usage, and package manager tasks. Use when editing/running Makefile targets, troubleshooting compose commands, managing backend/frontend dependencies, standardizing local dev commands, or creating CI-facing make targets.
---

# Makefile Operations

## Scope

Use this skill when working on repositories that orchestrate development tasks from a central `Makefile`, especially with Docker Compose services like backend, frontend, and database.

## Core Rules

1. Prefer existing `Makefile` targets over ad-hoc shell commands.
2. Keep lifecycle ordering consistent:
   - Start/build before exec
   - Exec for running containers
   - Run `--rm` for one-off jobs
   - Stop/down with `--remove-orphans` when tearing down
3. Keep backend and frontend package managers isolated:
   - Backend: `uv` in backend container
   - Frontend: `bun` in frontend container
4. Use service-specific logs and shells instead of broad noisy commands.
5. If a command can be destructive, call it out clearly before proposing/running it.
6. **CI parity**: GitHub Actions must call `make <target>` — never duplicate lint/test/build commands in workflow YAML. If CI needs a step, add a Makefile target first.

## Command Ordering Standard

Follow this order unless the user asks otherwise:

1. **Bring stack up**
   - `make build` for rebuilds
   - `make start` for normal startup
2. **Run app tasks**
   - Django ops (`migrate`, `makemigrations`) or FastAPI/alembic ops (`alembic-upgrade`, `alembic-revision`)
   - Formatting/lint
   - Package changes (`uv-*`, `bun-*`)
3. **Inspect**
   - `make show-backend-logs`, `make show-frontend-logs`, `make show-postgres-logs`
   - `make backend-shell` / `make postgres-shell` for deeper checks
4. **Teardown**
   - `make stop` (must map to `docker compose down --remove-orphans`)

If a workflow needs one-off commands, keep them deterministic and container-scoped.

## CI-facing targets (required for every project)

Every scaffolded project must expose these aggregate targets for GitHub Actions:

| Target | Purpose |
|--------|---------|
| `lint` | Runs `lint-backend` + `lint-frontend` |
| `lint-backend` | `uv run ruff check` in backend container |
| `lint-frontend` | `bun run lint` in frontend container |
| `test` | Runs `test-backend` + `test-frontend` |
| `test-backend` | pytest or Django test runner in backend container |
| `test-frontend` | frontend test command (if configured) |
| `build` | `docker compose build` |

GitHub Actions workflows call only these targets. See **github-actions** skill.

## Docker Compose Guidance

### Startup

- Use detached mode for standard development startup.
- Use force recreate on full stack restart when consistency matters.
- Prefer one canonical startup target (`build` or `start`) instead of multiple overlapping variants.

### Teardown

- Always include `--remove-orphans` on `down`.
- For cleanup targets, differentiate clearly:
  - **Soft clean**: safe-ish cache/image/volume cleanup
  - **Hard clean**: includes builder prune / deeper cleanup
- Keep cleanup idempotent with `|| true` only where failure is expected and harmless.

### Run vs Exec

- Use `docker compose exec` for commands inside already-running containers.
- Use `docker compose run --rm` for one-off commands where container lifecycle should end immediately.
- For CI/non-interactive contexts, use `exec -T` to avoid TTY issues.

## Terminal and Logs Conventions

- Provide dedicated `*-shell` targets per critical service.
- Provide dedicated `show-*-logs` targets per service with `-f`.
- Avoid defaulting to global `docker compose logs -f` unless explicitly requested.
- When debugging:
  1. reproduce with the specific target
  2. stream service logs
  3. open service shell if needed
  4. rerun narrowly scoped command

## Standard Section Banners

Use standardized comment banners for top-level `Makefile` sections. Keep spacing, dashes, and capitalization consistent.

Use this exact format:

```makefile
# ----------------------------- Section Name ----------------------------- #
```

Required convention:

- One blank line before each section banner (except at file start).
- One blank line after each banner before targets.
- Use title case for section names.
- Keep one section per concern (Docker Compose, package managers, terminals, debugging, testing, danger zone).
- Preserve and reuse this exact debugging header:

```makefile
# ----------------------------- Debugging ----------------------------- #
```

Suggested section set for this repository style:

```makefile
# ------------------------------ Docker Compose ------------------------------ #
# ----------------------------- Backend Package Management ----------------------------- #
# ----------------------------- Frontend Package Management ----------------------------- #
# ----------------------------- Terminals ----------------------------- #
# ----------------------------- Debugging ----------------------------- #
# ----------------------------- Django ----------------------------- #
# ----------------------------- FastAPI / Alembic ----------------------------- #
# ----------------------------- Code Formatting ----------------------------- #
# ----------------------------- Testing ----------------------------- #
# ----------------------------- ⛔️ DANGER ZONE ⛔️ ----------------------------- #
```

Include **Django** or **FastAPI / Alembic** section based on backend type — not both unless the project genuinely uses both.

## Section `.PHONY` and Ordering Rules

After each section banner, add a `.PHONY` line that lists all targets in that section, in the exact same order they are defined below.

Rules:

- Place `.PHONY` immediately under the section banner (after optional section comments like `# Usage`).
- Keep target order in `.PHONY` synchronized with target declaration order.
- Update `.PHONY` every time targets are added, removed, or reordered.
- Do not include targets from other sections in the same `.PHONY`.

Pattern:

```makefile
# ----------------------------- Code Formatting ----------------------------- #
.PHONY: lint-backend lint-frontend lint
```

### Simple to Combined convention

Define targets from simple to complex:

- First: atomic targets (single service / single responsibility), e.g. `lint-backend`, `lint-frontend`.
- Last: combined/aggregate target that orchestrates previous ones, e.g. `lint`.

Example:

```makefile
lint-backend:
	docker compose exec -T backend-PROJECT_SLUG sh -c "uv run ruff check ."

lint-frontend:
	docker compose exec -T frontend-PROJECT_SLUG sh -c "bun run lint"

lint:
	make lint-backend
	make lint-frontend
```

## Backend operations by stack

### Django / DRF

```makefile
migrate:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py migrate

makemigrations:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py makemigrations

test-backend:
	docker compose exec -T backend-PROJECT_SLUG uv run python manage.py test
```

### FastAPI / Alembic

```makefile
alembic-upgrade:
	docker compose exec -T backend-PROJECT_SLUG uv run alembic upgrade head

alembic-revision:
	docker compose exec -T backend-PROJECT_SLUG uv run alembic revision --autogenerate -m "$(MSG)"

test-backend:
	docker compose exec -T backend-PROJECT_SLUG uv run pytest
```

## Package Manager Conventions

### Backend (`uv`)

- Keep lockfile actions explicit: lock, add/remove, full upgrade vs single-package upgrade, lock regenerate/refresh.
- Run backend package commands in backend service context, usually with `run --rm`.

### Frontend (`bun`)

- Run bun commands in frontend service context.
- Keep lockfile regeneration explicit and reproducible.
- Pair frontend formatting and project-specific checks in one target when practical.

## Package Management Target Patterns

### Required operations

Every package-management section should provide explicit targets for:

- lock / freeze dependencies
- add dependency
- update all dependencies
- update one dependency
- remove dependency
- regenerate or refresh lockfile

### Variable conventions

- Use `PKG` for the package name input.
- Support both:
  - no `PKG` -> bulk update
  - with `PKG` -> single-package update
- Document usage immediately above the targets with short examples.

### Concrete example (`uv`)

```makefile
.PHONY: uv-lock uv-add uv-update uv-remove uv-lock-regenerate

# Usage:
#   make uv-add PKG="package[extras]==version"
#   make uv-update            # update all
#   make uv-update PKG=foo    # update specific package
#   make uv-remove PKG=foo
#   make uv-lock-regenerate   # refresh lock from scratch
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
```

### Concrete example (`bun`)

```makefile
.PHONY: bun-add bun-update bun-remove

# Usage:
#   make bun-add PKG=package
#   make bun-update PKG=package
#   make bun-remove PKG=package
bun-add:
	docker compose exec -T frontend-PROJECT_SLUG bun add $(PKG)

bun-update:
	docker compose exec -T frontend-PROJECT_SLUG bun update $(PKG)

bun-remove:
	docker compose exec -T frontend-PROJECT_SLUG bun remove $(PKG)
```

## Target Design Checklist

When creating/updating `Makefile` targets:

- [ ] Is the target name explicit and consistent with existing naming?
- [ ] Does it choose `run --rm` vs `exec` correctly?
- [ ] Does teardown include orphan cleanup when relevant?
- [ ] Are logs and shell access available for involved services?
- [ ] Is the command safe for repeated local runs?
- [ ] Are `lint`, `test`, and `build` aggregate targets present for CI?
- [ ] Is dangerous behavior isolated in clearly marked "danger zone" targets?
- [ ] Are user-facing echoes concise and useful?

## Recommended Review Flow

When asked to review a `Makefile`:

1. Verify startup/teardown ordering and orphan handling.
2. Verify `run` vs `exec` usage per target.
3. Verify package manager boundaries (`uv` backend, `bun` frontend).
4. Verify CI-facing targets (`lint`, `test`, `build`) exist and are used by GitHub Actions.
5. Verify logs/shell targets cover all core services.
6. Flag duplicate or conflicting targets and suggest consolidation.
7. Flag dangerous cleanup/database reset tasks and ensure warnings are explicit.

## Additional resources

- Full Makefile starter templates: [reference.md](reference.md)
