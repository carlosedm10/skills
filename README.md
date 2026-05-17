# Agent skills template

[![npm version](https://img.shields.io/npm/v/agent-skills-template.svg)](https://www.npmjs.com/package/agent-skills-template)
[![npm downloads](https://img.shields.io/npm/dm/agent-skills-template.svg)](https://www.npmjs.com/package/agent-skills-template)

Author [**Agent Skills**](https://agentskills.io/)-compatible bundles once and install them to multiple AI coding tools.

## Published package

This repo ships **`agent-skills-template`** on npm:

**[npmjs.com/package/agent-skills-template](https://www.npmjs.com/package/agent-skills-template)**

Fastest path for most users:

```bash
npx agent-skills-template@latest install --help
```

## Repository layout

| Path | Purpose |
|------|---------|
| [`skills/`](skills/) | Your skills (`<name>/SKILL.md` plus optional files) |
| [`skill-template/`](skill-template/) | Starter files for `./install.sh new <name>` |
| [`install.sh`](install.sh) | Interactive installer (uses [gum](https://github.com/charmbracelet/gum) when available) |
| [`install/platforms/`](install/platforms/) | Per-target install scripts |

## Quick install

### npm / bun (recommended — uses the registry tarball)

The CLI name matches the package: **`agent-skills-template`**.

```bash
npx agent-skills-template@latest install --help
npx agent-skills-template@latest --yes --platforms cursor --skills all --mode copy
```

```bash
bunx agent-skills-template@latest install --help
```

Global install:

```bash
npm install -g agent-skills-template
agent-skills-template install --help
```

### Clone and run

```bash
git clone https://github.com/carlosedm10/skills.git
cd skills
./install.sh
```

### curl (remote — runs latest `main` installer script)

```bash
curl -fsSL https://raw.githubusercontent.com/carlosedm10/skills/main/install.sh | bash
```

> **npm vs curl:** `npx` installs the **same version** as the published package (skills + installer bundled in the tarball). `curl` always runs whatever is on **`main`** in GitHub.

### Local package folder (contributors)

```bash
cd /path/to/skills
npx .
```

### Non-interactive flags

```bash
./install.sh --yes \
  --platforms cursor,claude-code,opencode,pi,codex \
  --skills all \
  --mode copy
```

- **`--platforms`**: comma-separated: `cursor`, `claude-code`, `codex`, `opencode`, `pi`, `agents` (`~/.agents/skills`, shared by several tools)
- **`--skills`**: comma-separated names or `all`
- **`--mode`**: `copy` | `symlink` (`symlink` keeps installs in sync with this repo)
- **`--yes` / `-y`**: skip confirmations (default selections where needed)

## Install destinations

| Platform | Global path |
|----------|-------------|
| Cursor | `~/.cursor/skills/<skill>/` |
| Claude Code | `~/.claude/skills/<skill>/` |
| OpenCode | `~/.config/opencode/skills/<skill>/` |
| Pi | `~/.pi/agent/skills/<skill>/` |
| Shared `.agents` | `~/.agents/skills/<skill>/` |
| Codex | `~/.codex/skills/<skill>/` + `[[skills.config]]` entries in `~/.codex/config.toml` |

Codex follows official **`skills.config`** paths (folders containing `SKILL.md`). The installer appends blocks tagged with `# agent-skills-template: <skill>` so you can remove or edit them later.

## Authoring a skill

1. Copy [`skill-template/SKILL.md`](skill-template/SKILL.md) to `skills/<skill-name>/SKILL.md`.
2. Use a **`name`** in YAML frontmatter that matches the directory (`kebab-case`, ≤64 chars).
3. Write a **`description`** that states what the skill does and when to use it (≤1024 chars).
4. Add optional files beside `SKILL.md` (`examples.md`, `scripts/`, …).

Create a new skill skeleton:

```bash
./install.sh new my-skill-name
```

## Maintainer: releasing to npm

### Version tags → CI publish

1. Bump **`version`** in [`package.json`](package.json) (or run `npm version patch`).
2. Commit and push to `main`.
3. Push a **`v*`** tag (example: `v1.0.2`):

```bash
git push origin main && git push origin v1.0.2
```

That triggers [`.github/workflows/publish-npm.yml`](.github/workflows/publish-npm.yml).

### Trusted publishing (OIDC)

CI is configured for **[Trusted publishing](https://docs.npmjs.com/trusted-publishers)** (short-lived OIDC — **no long-lived `NPM_TOKEN`** in GitHub secrets). Requirements on npm’s side include matching **`publish-npm.yml`**, repo **`carlosedm10/skills`**, and (if you set it on npm) the **same GitHub Environment name** — uncomment `environment:` in the workflow to match.

Manual fallback from your laptop still works:

```bash
npm publish --access public
```

### Forking this template

Replace `carlosedm10/skills` and the npm **`name`** in [`README.md`](README.md) / [`package.json`](package.json), configure your own Trusted Publisher on npm (or use **`NPM_TOKEN`** in CI instead of OIDC), then publish under your scope if needed (`@you/agent-skills-template`).

## Customization

- **Fork-only workflow**: keep skills under [`skills/`](skills/) and run `./install.sh` after edits; use **`symlink`** mode so global installs always track your clone.
- **Per-project installs**: run the same installer from the repo checkout with **`copy`** mode, then copy specific bundles into a project’s `.cursor/skills/`, `.claude/skills/`, `.opencode/skills/`, etc., if you want repo-local versions instead of global ones.
- **Codex**: entries are appended to `~/.codex/config.toml` under `# agent-skills-template: <skill>` markers—delete those blocks to unregister without removing files from `~/.codex/skills/`.
- **Pi**: if your Pi settings use [`skills.customDirectories`](https://github.com/earendil-works/pi), add paths there when you prefer not to use the default Pi skill dirs.

## Troubleshooting

- **`npm` removed `bin` on publish**: older **v1.0.0** builds had an invalid `bin` mapping for some npm versions — use **v1.0.1+** from the registry.
- **Interactive UI**: install [gum](https://github.com/charmbracelet/gum) for multi-select menus (`brew install gum`). Without gum, the script falls back to plain prompts.
- **`gum choose` flags**: the installer tries `--limit 0`, then `--no-limit`, then `--limit 99` for compatibility across gum versions.
- **Sandboxed environments**: installing under `~/.cursor`, `~/.codex`, etc., requires a normal user home directory (some CI sandboxes block dot-directories).
- **Trusted publishing errors (`ENEEDAUTH`)**: confirm npm’s Trusted Publisher fields match this repo/workflow exactly (case-sensitive), use **GitHub-hosted runners**, and ensure the workflow grants **`id-token: write`** plus **npm ≥ 11.5.1** (see workflow).

## License

MIT
