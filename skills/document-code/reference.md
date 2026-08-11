# document-code — triage rubric, templates & checklists

Fill every template from **Phase 0 findings only** — each line must be something you verified in the code. And triage before you type: most existing docs need a few lines changed, not a rewrite.

---

## The triage rubric (Phase 1)

Score each doc on these six signals. **All six clean → `KEEP` (change nothing).** One or two failing → `UPDATE` (surgical). Structure/level failing → `RESTRUCTURE`. Absent or mostly-wrong → `CREATE`.

| Signal | Clean looks like | Failing looks like |
|---|---|---|
| **Truth** | Spot-checked claims verify against code. | Claims contradict the code, or reference deleted/moved files. |
| **Altitude** | Taxonomy, flows, principles, decisions. | Column names, method signatures, step-by-step recipes. |
| **One question** | The whole file answers the question its title implies. | Rules + explanation + status mixed in one file. |
| **Level** | Sits at the lowest scope containing everything it mentions. | Root-level file about one domain, or a domain file explaining two. |
| **Budget** | Entry point ≤ one screen; domain doc ~5 min. | Sprawls; or the doc set blows the 10-minute total. |
| **Completeness** | Covers what shipped, including recent subsystems. | A whole subsystem the code has but the doc never mentions. |

**Signals a doc is already polished — treat as `KEEP` and do not "improve" it:**
- Hand-written caveats and "why not X" asides that could only come from experience.
- Decisions with their *why* and their cost, not just the what.
- Deliberate, non-generic wording and section ordering.
- Concrete gotchas with dates, versions, or captured payloads.

If the only thing you can say against a doc is that you would have written it differently, the verdict is `KEEP`.

**`UPDATE` well:**
- Change only the affected lines; the rest of the file stays byte-identical.
- Add a new bullet to an existing list rather than rewriting the list.
- New subsystem → one new bullet/row in the existing section, in the established voice.
- Match the file's existing conventions (wrapping, heading depth, table style) even if you would choose otherwise.
- Never reflow, reorder, or re-voice as a side effect of a fact fix.

---

## Template — `AGENTS.md` (entry point, one screen, per scope)

Rules and routing only. If it starts explaining, the content belongs in the domain doc.

```markdown
# <Scope name> — Agent Instructions

<1–3 lines: what this scope is and what it owns.>

Read before changing anything:

1. [docs/README.md](docs/README.md) — the one doc: taxonomy, architecture, data flows, key decisions. **Keep its "Key decisions" list updated when a change makes or supersedes one.**
2. [<code-adjacent README, if any>](<path>) — <what it covers>. Read before touching <that area>.

Known code flaws: [INCONSISTENCIES.md](INCONSISTENCIES.md) — check before fixing something already tracked; delete entries you resolve. Working artifacts (tracking, not reference): `<artifact paths>`.

## Non-negotiable rules

- **<Rule>** — <the constraint, one line. State it as a rule, not an explanation.>
- **<Rule>** — <…>

## Local verification

- <How to run the tests / lint / typecheck for this scope, including the non-obvious gotcha.>
```

Plus the relay file for tools that only auto-load their own name — `CLAUDE.md` containing exactly:

```markdown
@./AGENTS.md
```

---

## Template — `docs/README.md` (the one doc, ~5-minute read, per domain)

The only place that *explains*. Sections in this order; drop any that does not apply (a domain with no store has no data-flow section).

```markdown
# <Domain> — The One Doc

<What it does, for whom, in 2–4 lines. Name the external dependency and whether it is swappable.>

## The layers            ← only if the domain spans more than one deployable

```
<ASCII diagram of who calls whom. Show the contract, not the classes.>
```

- **<Layer>** — <what it owns, one line, with the path.>
- **<Layer>** — <…> **<The boundary rule that must never be broken.>**

## The taxonomy

<One line on why this vocabulary matters — it repeats across folders, API names, routing.>

| Domain | Covers | <Where data lives / owner> |
|---|---|---|
| **<Name>** | <scope> | <…> |

## How it's built

One path for every operation:

```
<layer> → <layer> → <layer> → <external>
```

### The principles that matter

- **<Principle>** — <why it holds and what it buys.>
- **<Principle>** — <…>

## How data flows

<The one paragraph a newcomer needs: what is stored where and why.>

- **Reads**: <…>
- **Writes**: <…>
- **Sync / background**: <…>

### Entities

- **<Entity>**: <one line — what it is, not its columns.>

### One example, end to end

<A real user action, numbered, 4–6 steps, ending where the user sees the result.>

## Key decisions and caveats (why it is this way)

- **<Decision>**: <what we chose> — <why, and what it cost.>
- **<Decision>**: <…>

## Where the details live

- [<code-adjacent README>](<path>) — <mechanics + quirks>, next to <its artifacts>.
- The code — <where the models / logic / config actually are>.
- Working artifacts: `<file>` (<what it tracks>).
```

---

## Template — code-adjacent `README.md`

Only for a genuinely tricky folder. Lives **inside** that folder, beside its artifacts.

```markdown
# <Folder purpose>

<What this is and the boundary: what may know about it, what may not.>

## How it works

```
<file/dir>        <its job, one line>
  → <file/dir>    <…>
```

<The flow for the most common change, in one sentence.>

## <Dependency> quirks (read before <the common change>)

- **<Surprising behavior>** — <what actually happens, and what breaks if you assume otherwise.>
- **<…>**
```

---

## Template — `plans/<name>.md`

```markdown
# <Feature> — <plan | progress + decisions>

> Status (<date>): <draft | active | shipped>. <One line on what is real vs intended.>
> Delete once distilled into the domain doc.
```

---

## Template — `INCONSISTENCIES.md`

```markdown
# <Scope> — Known Inconsistencies

Findings from a code audit (<date>), grouped by priority. Each verified by reading the code. Fix opportunistically; delete entries as they land.

## Must fix

1. **<One-line title>** — `<path:line>`. <What is wrong and what it breaks.>

## Should fix

2. **<…>**

## Worth a look

3. **<…>**

## Checked and clean

- **<Thing you verified was fine>** — <so the next person does not re-audit it.>
```

---

## Checklist — verification (Phase 4)

- [ ] Every relative link resolves (verified, not assumed); anchors exist in their targets.
- [ ] ~5 factual claims spot-checked against code — record true/false with evidence.
- [ ] Total word count ÷ 200 wpm ≤ 10 minutes; note the per-file breakdown.
- [ ] No two docs contradict each other; no references to deleted files.
- [ ] No passage reads like code documentation (quote any that does).
- [ ] No undefined terms or used-before-defined jargon for a newcomer.
- [ ] Entry points still one screen; domain doc still ~5 minutes.
- [ ] Each file still has exactly one update gesture (no rules+history+status mixing).
- [ ] **Diff is minimal** — every changed line is a fact fix, an addition, or a justified deletion. No incidental rewording, reflowing, or reordering.
- [ ] Every `KEEP` file is genuinely untouched (`git diff --stat` shows it absent).

---

## Worked example — the shape of a finished tree

```
<repo>/
├── AGENTS.md                       # orientation + routing (one screen)
│   └── CLAUDE.md → AGENTS.md       # relay for tools that only read their own name
├── docs/
│   └── README.md                   # the documentation convention (root routes, never hosts)
├── <deployable-a>/
│   ├── AGENTS.md (+ relay)         # this deployable's rules
│   └── docs/ARCHITECTURE.md        # its one doc
└── <deployable-b>/
    ├── AGENTS.md (+ relay)
    └── <domains>/<domain>/
        ├── AGENTS.md (+ relay)     # rules + pointers
        ├── INCONSISTENCIES.md      # tracked code flaws (not documentation)
        ├── docs/README.md          # THE ONE DOC (~5 min)
        └── <tricky-folder>/
            ├── README.md           # code-adjacent: mechanics + quirks
            └── <artifact>.csv      # tracking sheet, beside what it tracks
```

Growth path for a small scope: start with **one** `docs/README.md` carrying `## Architecture`, `## Data flow`, `## Key decisions` as sections. A section graduates to its own file only when it outgrows a screen *and* something needs to link to it independently.
