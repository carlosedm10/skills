# Agent skills template

Author [**Agent Skills**](https://agentskills.io/)-compatible bundles once and install them to multiple AI coding tools.

**npm:** [`agent-skills-template`](https://www.npmjs.com/package/agent-skills-template)

## Repository layout

| Path | Purpose |
|------|---------|
| [`skills/`](skills/) | Your skills (`<name>/SKILL.md` plus optional files) |
| [`skill-template/`](skill-template/) | Starter files for `./install.sh new <name>` |
| [`install.sh`](install.sh) | Interactive installer (uses [gum](https://github.com/charmbracelet/gum) when available) |
| [`install/platforms/`](install/platforms/) | Per-target install scripts |

## Quick install

### Clone and run

```bash
git clone https://github.com/carlosedm10/skills.git
cd skills
./install.sh
```

### curl (remote)

```bash
curl -fsSL https://raw.githubusercontent.com/carlosedm10/skills/main/install.sh | bash
```

### npm / bun (published package)

The CLI executable name matches the package name (`agent-skills-template`).

```bash
npx agent-skills-template install --help
# optional verb — forwarded to install.sh as well
npx agent-skills-template --yes --platforms cursor --skills all --mode copy
```

```bash
bunx agent-skills-template install --help
```

Global install (optional):

```bash
npm install -g agent-skills-template
agent-skills-template install --help
```

### Local package folder (no publish)

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

## Publishing to npm

### Manual release

1. Bump **`version`** in [`package.json`](package.json).
2. Commit and push.
3. Create and push a matching git tag (workflow below uses this):

```bash
git tag v1.0.1
git push origin v1.0.1
```

Or publish locally:

```bash
npm publish --access public
```

### Automated release (GitHub Actions)

Pushing a version tag **`v*`** runs [`.github/workflows/publish-npm.yml`](.github/workflows/publish-npm.yml).

1. In the GitHub repo: **Settings → Secrets and variables → Actions → New repository secret**
   - Name: **`NPM_TOKEN`**
   - Value: an npm [**granular access token**](https://docs.npmjs.com/about-access-tokens) or [**automation token**](https://docs.npmjs.com/creating-and-viewing-access-tokens) with **publish** permission for this package.
2. Bump `package.json` **`version`**, commit to `main`, then tag and push:

```bash
npm version patch   # or edit package.json manually
git push origin main && git push origin --tags
```

The workflow runs **`npm pkg fix`** before publish so `repository` / `bin` metadata stays valid.

## Forking this template

Replace `carlosedm10/skills` with your GitHub user and repo name in [`README.md`](README.md) and [`package.json`](package.json), pick an unused npm **`name`**, then publish under your scope if needed (`@you/agent-skills-template` + `npm publish --access public`).

## Customization

- **Fork-only workflow**: keep skills under [`skills/`](skills/) and run `./install.sh` after edits; use **`symlink`** mode so global installs always track your clone.
- **Per-project installs**: run the same installer from the repo checkout with **`copy`** mode, then copy specific bundles into a project’s `.cursor/skills/`, `.claude/skills/`, `.opencode/skills/`, etc., if you want repo-local versions instead of global ones.
- **Codex**: entries are appended to `~/.codex/config.toml` under `# agent-skills-template: <skill>` markers—delete those blocks to unregister without removing files from `~/.codex/skills/`.
- **Pi**: if your Pi settings use [`skills.customDirectories`](https://github.com/earendil-works/pi), add paths there when you prefer not to use the default Pi skill dirs.

## Troubleshooting

- **`npm` removed `bin` on publish**: older `package.json` builds used `"bin": { "skills": "./bin/cli.js" }`, which some npm versions normalize incorrectly. This repo uses `"bin": "./bin/cli.js"` so the CLI name matches the package (**`agent-skills-template`**). Use **v1.0.1+** on npm.
- **Interactive UI**: install [gum](https://github.com/charmbracelet/gum) for multi-select menus (`brew install gum`). Without gum, the script falls back to plain prompts.
- **`gum choose` flags**: the installer tries `--limit 0`, then `--no-limit`, then `--limit 99` for compatibility across gum versions.
- **Sandboxed environments**: installing under `~/.cursor`, `~/.codex`, etc., requires a normal user home directory (some CI sandboxes block dot-directories).

## License

MIT
