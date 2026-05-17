# Agent skills template

Author [**Agent Skills**](https://agentskills.io/)-compatible bundles once and install them to multiple AI coding tools.

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
git clone https://github.com/YOUR_USERNAME/agent-skills-template.git
cd agent-skills-template
./install.sh
```

### curl (remote — publish first)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/agent-skills-template/main/install.sh | bash
```

### npm / bun (from a published package or local path)

```bash
npx agent-skills-template install
# or
bunx agent-skills-template install
```

Global CLI name: **`skills`** (see [`package.json`](package.json) `bin`).

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

## Publishing your fork

1. Replace `YOUR_USERNAME` / repo URLs in [`README.md`](README.md) and [`package.json`](package.json).
2. Optionally publish to npm: `npm publish --access public`.
3. Point curl installs at your `main` branch `install.sh`.

## Customization

- **Fork-only workflow**: keep skills under [`skills/`](skills/) and run `./install.sh` after edits; use **`symlink`** mode so global installs always track your clone.
- **Per-project installs**: run the same installer from the repo checkout with **`copy`** mode, then copy specific bundles into a project’s `.cursor/skills/`, `.claude/skills/`, `.opencode/skills/`, etc., if you want repo-local versions instead of global ones.
- **Codex**: entries are appended to `~/.codex/config.toml` under `# agent-skills-template: <skill>` markers—delete those blocks to unregister without removing files from `~/.codex/skills/`.
- **Pi**: if your Pi settings use [`skills.customDirectories`](https://github.com/earendil-works/pi), add paths there when you prefer not to use the default Pi skill dirs.

## Troubleshooting

- **Interactive UI**: install [gum](https://github.com/charmbracelet/gum) for multi-select menus (`brew install gum`). Without gum, the script falls back to plain prompts.
- **`gum choose` flags**: the installer tries `--limit 0`, then `--no-limit`, then `--limit 99` for compatibility across gum versions.
- **Sandboxed environments**: installing under `~/.cursor`, `~/.codex`, etc., requires a normal user home directory (some CI sandboxes block dot-directories).

## License

MIT
