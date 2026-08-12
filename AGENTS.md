# skills — Agent Instructions

This repo authors [Agent Skills](https://agentskills.io/)-compatible bundles and installs them into whichever AI coding tools you use. It ships to npm as **`agent-skills-template`**.

Two things live here, and they change independently:

- **[`skills/`](skills/)** — the skills themselves, one directory per skill.
- **[`install`](install) + [`lib/`](lib/)** — the installer that places those directories where each tool looks for them.

A change to one is almost never a change to the other. Adding a skill touches no shell script; adding a platform touches no skill.

## Rules

- A skill is a directory under `skills/` containing `SKILL.md`. The `name:` in its YAML frontmatter must match the directory name, in kebab-case. The installer copies and registers by *directory* name while agents read the *frontmatter* name, so letting the two drift means the same skill goes by two names.
- `description:` states what the skill does **and when to use it**. That text is the only thing an agent sees when deciding whether to load the skill, so lead with the triggers, not the mechanics.
- Deep detail goes in files beside `SKILL.md` (`reference.md`, `examples.md`, `scripts/`), not in `SKILL.md` itself. The main file is what gets read every time; the rest is opened on demand.
- Scaffold with `./install new <name>` rather than copying by hand — it creates the directory and rewrites the template frontmatter to match the name.
- In platform scripts, never `cp` or `ln` directly and never hardcode a home directory. Go through `install_bundle` so both `copy` and `symlink` modes keep working.
- Never commit or push — the engineer handles git.

## Verifying a change to the installer

```bash
bash -n install && bash -n lib/*.sh          # syntax
./install --help                             # entry point resolves
CODEX_HOME=/tmp/skills-check ./install --yes \
  --platforms codex --skills <one-skill> --mode copy
```

Use `codex` for test installs. `CODEX_HOME` is the only destination override in the installer — every other platform writes to a fixed path under `$HOME`, so testing against them overwrites the skills you actually have installed.

## Where to look

| Question | File |
|---|---|
| How do I install this, and how is it released to npm? | [`README.md`](README.md) |
| How is the installer wired? How do I add a platform? | [`lib/README.md`](lib/README.md) |
| How do I start a new skill? | [`skill-template/SKILL.md`](skill-template/SKILL.md) |
