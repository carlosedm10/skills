---
name: makefile-operations
description: Manages Makefile-driven Docker Compose workflows with safe command ordering, container lifecycle hygiene, logs, terminal usage, and package manager tasks. Use when editing/running Makefile targets, troubleshooting compose commands, managing backend/frontend dependencies, or standardizing local dev commands.
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
   - Frontend: `npm` in frontend container
4. Use service-specific logs and shells instead of broad noisy commands.
5. If a command can be destructive, call it out clearly before proposing/running it.

## Command Ordering Standard

Follow this order unless the user asks otherwise:

1. **Bring stack up**
   - `make build` for rebuilds
   - `make start` for normal startup
2. **Run app tasks**
   - Django ops (`migrate`, `makemigrations`, tests)
   - Formatting/lint
   - Package changes (`uv-*`, `npm-*`)
3. **Inspect**
   - `make show-backend-logs`, `make show-frontend-logs`, `make show-postgres-logs`
   - `make backend-shell` / `make postgres-shell` for deeper checks
4. **Teardown**
   - `make stop` (must map to `docker compose down --remove-orphans`)

If a workflow needs one-off commands, keep them deterministic and container-scoped.

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
# ----------------------------- Django/Or similar ----------------------------- #
# ----------------------------- Code Formatting ----------------------------- #
# ----------------------------- Testing ----------------------------- #
# ----------------------------- ⛔️ DANGER ZONE ⛔️ ----------------------------- #
```

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
	docker compose exec -T backend-finkelly sh -c "uv run ruff check api/"

lint-frontend:
	docker compose exec -T frontend-finkelly sh -c "npm run lint"

lint:
	make lint-backend
	make lint-frontend
```

## Package Manager Conventions

### Backend (`uv/poetry/pipenv/... whatever the project uses`)

- Keep lockfile actions explicit:
  - lock
  - add/remove
  - full upgrade vs single-package upgrade
  - lock regenerate/refresh
- Run backend package commands in backend service context, usually with `run --rm`.

### Frontend (`npm/pnpm/bun/... whatever the project uses`)

- Run npm commands in frontend service context.
- Keep lockfile regeneration explicit and reproducible.
- Pair frontend formatting and project-specific checks in one target when practical.

## Package Management Target Patterns (Flexible)

Use this section to define package workflows in any project, regardless of package manager.

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

### Container execution rules

- Use one-off commands with `docker compose run --rm <service> ...` when package operations do not require a long-running container session.
- Keep package operations scoped to the service that owns the lockfile.
- Prefer deterministic commands that modify lockfiles in a predictable way.

### Template (manager-agnostic)

```makefile
# Usage:
#   make <pm>-add PKG="package[extras]==version"
#   make <pm>-update
#   make <pm>-update PKG=foo
#   make <pm>-remove PKG=foo
#   make <pm>-lock-regenerate
<pm>-lock:
	docker compose run --rm <service> <pm-cmd> <lock-command>

<pm>-add:
	docker compose run --rm <service> <pm-cmd> <add-command> $(PKG)

<pm>-update:
ifeq ($(PKG),)
	docker compose run --rm <service> <pm-cmd> <update-all-command>
else
	docker compose run --rm <service> <pm-cmd> <update-one-command> $(PKG)
endif

<pm>-remove:
	docker compose run --rm <service> <pm-cmd> <remove-command> $(PKG)

<pm>-lock-regenerate:
	docker compose run --rm <service> <pm-cmd> <lock-regenerate-command>
```

### Concrete example from this repository (`uv`)

```makefile
.PHONY: uv-lock uv-add uv-update uv-remove uv-lock-regenerate

# Usage:
#   make uv-add PKG="package[extras]==version"
#   make uv-update            # update all
#   make uv-update PKG=foo    # update specific package
#   make uv-remove PKG=foo
#   make uv-lock-regenerate   # refresh lock from scratch
uv-lock:
	docker compose run --rm backend-finkelly uv lock

uv-add:
	docker compose run --rm backend-finkelly uv add $(PKG)

uv-update:
ifeq ($(PKG),)
	docker compose run --rm backend-finkelly uv lock --upgrade
else
	docker compose run --rm backend-finkelly uv lock --upgrade-package $(PKG)
endif

uv-remove:
	docker compose run --rm backend-finkelly uv remove $(PKG)

uv-lock-regenerate:
	docker compose run --rm backend-finkelly uv lock --refresh
```

### Adaptation notes by ecosystem

- Python (`uv`, `poetry`, `pip-tools`): treat lock refresh as a first-class target.
- Node (`npm`, `pnpm`, `yarn`, `bun`): keep add/remove/update and lock regeneration explicit.
- Mixed monorepos: split targets by service and package manager rather than mixing commands in one target.

## Target Design Checklist

When creating/updating `Makefile` targets:

- [ ] Is the target name explicit and consistent with existing naming?
- [ ] Does it choose `run --rm` vs `exec` correctly?
- [ ] Does teardown include orphan cleanup when relevant?
- [ ] Are logs and shell access available for involved services?
- [ ] Is the command safe for repeated local runs?
- [ ] Is dangerous behavior isolated in clearly marked "danger zone" targets?
- [ ] Are user-facing echoes concise and useful?

## Recommended Review Flow

When asked to review a `Makefile`:

1. Verify startup/teardown ordering and orphan handling.
2. Verify `run` vs `exec` usage per target.
3. Verify package manager boundaries (`uv` backend, `npm` frontend).
4. Verify logs/shell targets cover all core services.
5. Flag duplicate or conflicting targets and suggest consolidation.
6. Flag dangerous cleanup/database reset tasks and ensure warnings are explicit.
