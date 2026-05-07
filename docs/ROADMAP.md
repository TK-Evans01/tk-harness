# tk-harness Roadmap and Handoff

Last updated: 2026-05-06

This document is the single source of truth for tk-harness status, remaining
work, and the decision log. It is intended as a handoff for any future session
(human or agent). Read this first.

## TL;DR

- **What it is.** A Claude Code plugin marketplace implementing a strict
  Research-Plan-Stub-Test-Implement-Eval (**RPSTIE**) workflow with Tier-2
  nearly-pure functional discipline.
- **Where we are.** M0-M2 essentially done; M3-M5 in progress via parallel
  agents in this same milestone wave; M6 (dogfood) not started.
- **What is unique.** Stubs/tests/bodies are three separate subagents (vs ed3d's
  single TDD implementor). Worktree mandatory. 3-strike fix-loop cap with
  auto-escalation to a structured BLOCKED report. FP-primitives block injected
  into every coding subagent dispatch.
- **Provenance.** Inspired by and partially derived from
  [ed3dai/ed3d-plugins](https://github.com/ed3dai/ed3d-plugins) (CC-BY-SA-4.0)
  which itself derives from [obra/superpowers](https://github.com/obra/superpowers)
  (MIT). Per-file/per-plugin provenance footers maintained.

## Status

### Commit log

The shell environment used to author this roadmap denied direct `git log`
access. To reconstruct the commit history in a fresh session run:

```bash
git -C /home/tk/Projects/harness log --oneline
git -C /home/tk/Projects/harness log --stat --all | head -200
```

The CHANGELOG.md at the repo root captures the same milestones in human form
and is the canonical narrative log. Three changelog blocks exist as of
2026-05-06:

1. `[tk-harness] 0.1.0 - M0 Skeleton` - marketplace scaffolding, manifests,
   CLAUDE.md conventions.
2. `[tk-harness] M1 - Foundation + Research Ports` - ports tk-foundation and
   tk-research from ed3d-plugins with adaptations.
3. `[tk-harness] M2 (in progress) - tk-rpie verbatim ports` - mass port of
   ed3d-plan-and-execute commands and skills via cp+sed renames; provenance
   footer added to every ported file.

### Per-plugin status

| Plugin            | Manifest | Agents          | Skills          | Commands | Hooks  | Overall    |
|-------------------|----------|-----------------|-----------------|----------|--------|------------|
| tk-foundation     | done     | 3 done          | 2 done          | n/a      | 1 done | DONE (M1)  |
| tk-research       | done     | 4 done          | 2 done          | n/a      | n/a    | DONE (M1)  |
| tk-rpie           | done     | 8 done          | 19 (incl. 2 librarian-deps just landed) | 5 done | n/a | DONE (M2) pending small reconciliation already applied |
| tk-house-style    | done     | empty           | 4 placeholder + tier files | n/a | n/a | PARTIAL (M3 in flight) |
| tk-verify         | done     | n/a             | empty           | 1 done   | 1 done | PARTIAL (M4 in flight) |
| tk-hooks          | done     | n/a             | n/a             | n/a      | 3 stubs | PARTIAL (M5 in flight) |

## M0 - Skeleton (DONE)

Shipped as `[tk-harness] 0.1.0`.

What was scaffolded:

- Marketplace manifest (`.claude-plugin/marketplace.json`) listing six plugin
  stubs: tk-foundation, tk-research, tk-house-style, tk-verify, tk-rpie,
  tk-hooks.
- Per-plugin `.claude-plugin/plugin.json` manifests with semver and
  description.
- Empty plugin directory layouts following ed3d's structure conventions
  (`agents/`, `skills/<name>/SKILL.md`, `commands/`, `hooks/`).
- Repo-wide conventions in `/home/tk/Projects/harness/CLAUDE.md`:
  - XML-style Task invocations (adopted from ed3d).
  - Version-sync discipline tying plugin.json bumps to marketplace.json and
    CHANGELOG.
  - FP-primitives active block format for coding subagent dispatch.
  - Subagent model defaults (opus for code-reviewer, sonnet for everything
    else, haiku unused).
  - Skill and agent frontmatter shapes.
  - ASCII-only encoding rule (no em-dashes, no smart quotes).
- README with workflow overview, subagent roster, attribution, license.
- LICENSE: CC-BY-SA-4.0 default; per-plugin/per-file MIT for ported obra/
  superpowers content.

## M1 - Foundation + Research (DONE)

Shipped as `[tk-harness] M1`.

### tk-foundation

- **Agents** (renamed from ed3d `*-general-purpose` -> `*-general`):
  - `haiku-general.md`
  - `sonnet-general.md`
  - `opus-general.md`
- **Skills**:
  - `using-generic-agents/SKILL.md`
  - `two-stage-fanout/SKILL.md` (renamed from
    `doing-a-simple-two-stage-fanout`) plus `compute_layout.py` and
    `diagram-templates.md`.
- **Hooks**:
  - `session-start.sh` banner reminding the model to invoke
    `using-generic-agents` when dispatching generic subagents.

### tk-research

- **Agents**:
  - `codebase-investigator.md` - bumped haiku -> sonnet; reads
    `docs/architecture.md`, root and module-level `AGENTS.md` / `CLAUDE.md`,
    and `docs/adr/` as priors before grep/glob; emits a "Files NOT found"
    section for unverifiable assumptions.
  - `internet-researcher.md` - bumped haiku -> sonnet.
  - `combined-researcher.md` - bumped haiku -> sonnet.
  - `remote-code-researcher.md` - bumped haiku -> sonnet.
- **Skills**:
  - `investigating-a-codebase/SKILL.md`
  - `researching-on-the-internet/SKILL.md`

### Adaptations applied during M1

- Dropped triage gate from M2 scope; full RPSTIE for every task currently.
- Slimmed tk-verify scope: thin `/verify` runner only, no per-language skills.
  Linter configs are project-owned; the harness does not ship defaults.
- Roadmap renumbered: M2 = tk-rpie core, M3 = tk-house-style, M4 = tk-verify.

## M2 - tk-rpie (DONE pending small reconciliation)

Shipped (in progress block) as `[tk-harness] M2`.

### Mass ports (sed renames + provenance footer)

Renames applied uniformly:

| ed3d                              | tk-harness                  |
|-----------------------------------|-----------------------------|
| `ed3d-plan-and-execute:`          | `tk-rpie:`                  |
| `ed3d-house-style:`               | `tk-house-style:`           |
| `ed3d-research-agents:`           | `tk-research:`              |
| `ed3d-basic-agents:`              | `tk-foundation:`            |
| `ed3d-extending-claude:`          | `tk-rpie:` (librarian moves into tk-rpie) |
| `task-implementor-fast`           | `body-implementor`          |
| `task-bug-fixer`                  | `bug-fixer`                 |
| `project-claude-librarian`        | `librarian`                 |
| `*-general-purpose`               | `*-general`                 |
| `.ed3d/`                          | `.tk-harness/`              |

### Commands

- `start-design-plan.md`
- `start-implementation-plan.md`
- `execute-implementation-plan.md`
- `flesh-it-out.md`
- `how-to-customize.md`

### Skills (workflow)

- `using-rpie/SKILL.md` (renamed from `using-plan-and-execute`)
- `asking-clarifying-questions/SKILL.md`
- `starting-a-design-plan/SKILL.md`
- `writing-design-plans/SKILL.md`
- `starting-an-implementation-plan/SKILL.md`
- `writing-implementation-plans/SKILL.md`
- `executing-an-implementation-plan/SKILL.md` - REWRITTEN for the
  stub-author -> test-author -> body-implementor chain (vs ed3d's single TDD
  implementor).
- `using-git-worktrees/SKILL.md`
- `preserving-original-during-refactor/SKILL.md`
- `requesting-code-review/SKILL.md` (+ `code-reviewer.md` reference doc)
- `verification-before-completion/SKILL.md`
- `systematic-debugging/SKILL.md` (+ creation log + 3 pressure tests +
  academic test)
- `finishing-a-development-branch/SKILL.md`
- `brainstorming/SKILL.md`
- `test-driven-development/SKILL.md`

### Skills (discipline, NEW for tk-harness)

- `writing-stubs-and-docs/SKILL.md`
- `writing-tests-against-stubs/SKILL.md`
- `writing-bodies-against-tests/SKILL.md`

### Skills (librarian deps, ported in this wave)

- `maintaining-project-context/SKILL.md` - ported from
  ed3d-extending-claude with sed renames and provenance footer.
- `writing-claude-md-files/SKILL.md` - ported from ed3d-extending-claude with
  sed renames and provenance footer.

### Subagent roster (final, M2)

| Stage              | Agent                  | Model  | Notes |
|--------------------|------------------------|--------|-------|
| Orchestrate        | main thread            | opus   | runs `executing-an-implementation-plan` |
| Research           | codebase-investigator  | sonnet | from tk-research |
| Research           | internet-researcher    | sonnet | from tk-research |
| Clarify            | clarifying-questioner  | sonnet | batches up to 5 questions before design |
| Stubs              | stub-author            | sonnet | typechecks, commits |
| Tests              | test-author            | sonnet | red against stubs (NotImplementedError, not ImportError); commits |
| Bodies             | body-implementor       | sonnet | one fn at a time, red->green; commits |
| Review (per phase) | code-reviewer          | opus   | FP-primitives + refactor old-vs-new diff |
| Fix                | bug-fixer              | sonnet | capped at 3 cycles |
| Final tests        | test-analyst           | sonnet | AC coverage; emits human test plan |
| Docs               | librarian              | sonnet | runs `maintaining-project-context` |

### Reconciliation edits applied 2026-05-06

These resolve decisions locked during conversation:

- **BLOCKED report path normalized.** All references to "BLOCKED.md at repo
  root" / "BLOCKED.md in working dir" rewritten to
  `.tk-harness/blocked/<phase-id>-<UTC-timestamp>.md` (timestamp format
  `YYYYMMDDTHHMMSSZ`, e.g. `20260506T143022Z`). Files touched:
  - `agents/body-implementor.md`
  - `agents/code-reviewer.md`
  - `agents/stub-author.md` (new section appended to report template)
  - `agents/test-author.md` (new section appended to report template)
  - `skills/writing-bodies-against-tests/SKILL.md`
  - `skills/executing-an-implementation-plan/SKILL.md`
  - `README.md`
- **STATUS sentinel format specified.** stub-author, test-author,
  body-implementor must emit `STATUS: BLOCKED - <one-line reason>` (ASCII
  hyphen, spaces) on the LAST LINE of their report when blocked. The
  orchestrator regex is `^STATUS: BLOCKED\b`. Specified in
  `executing-an-implementation-plan/SKILL.md`.
- **Glob over find for .original artifacts.** `code-reviewer.md` Step 2b
  rewritten to use `Glob('**/*.original')`; the find-as-exception note in
  Tool Usage Rules removed.
- **/verify clarified as a real slash command.** No file said "/verify is
  shorthand"; nothing to fix. The command is in `tk-verify/commands/verify.md`.
- **RPSTIE retained as workflow acronym; tk-rpie as plugin namespace.**
  README.md (root and per-plugin) gained a one-paragraph note clarifying the
  split. `RPIE` references in skill prose corrected to `RPSTIE` (the only one
  that materialised was in `writing-stubs-and-docs`).

## M3 - tk-house-style (IN PROGRESS - parallel agents)

Three parallel agents are landing M3 in this same wave:

### Parallel agent G - nearly-pure-functional anchor + tier files + 3 lang cards

- `skills/nearly-pure-functional/SKILL.md` - anchor with 10-section glossary,
  tier ladder, FP-primitives forbidden list (the source of truth for the
  dispatch-time `<fp-primitives-active>` block).
- `skills/nearly-pure-functional/tier-1.md` - "FP-curious" (least strict).
- `skills/nearly-pure-functional/tier-2.md` - "nearly-pure" (default for this
  harness).
- `skills/nearly-pure-functional/tier-3.md` - "near-Haskell strict".
- Per-language quick cards under `skills/nearly-pure-functional/` with
  TypeScript, Python, Rust mappings (Result/Option idioms, smart constructors,
  branded primitives, exhaustive match shape).

### Parallel agent H - 6 ported house-style skills

Currently in tree as placeholders:

- `skills/defense-in-depth/SKILL.md`
- `skills/property-based-testing/SKILL.md`
- `skills/writing-good-tests/SKILL.md`

Plus three more ports inbound from ed3d-house-style. All ports get the sed
renames + provenance footer.

### Linter configs - REMOVED from harness scope (2026-05-06)

The harness no longer ships default linter / typecheck / arch-lint configs.
Each project sets up its own linter configuration. `/verify` reads
`.tk-harness/verify.toml` (or auto-detects from package manifests) to know
what commands to run; the contents of those linters are project-owned.

## M4 - tk-verify (IN PROGRESS - parallel agent J)

Slim by design (decision locked: no per-language skills; configs live in
tk-house-style; tk-verify is a thin runner only).

Already in tree:

- `commands/verify.md` - the `/verify` slash command. Reads
  `.tk-harness/verify.toml` or auto-detects from `package.json` /
  `pyproject.toml` / `Cargo.toml`. Runs typecheck, lint, arch-lint, purity,
  tests fail-fast. Internals hidden from agents (anti-gaming).
- `hooks/edit-validation.sh` + `hooks/edit-validation/parsers.sh` - PostToolUse
  hook on Edit/Write. Cheap parser-level checks at edit time before `/verify`
  ever runs. The full gate catches semantic issues.
- `README.md` describing scope and the contract with tk-house-style.

Inbound from agent J: an example `verify.toml` covering TypeScript and Python
project shapes.

## M5 - tk-hooks (IN PROGRESS - parallel agent K)

Three hooks ported into one bundled plugin.

Currently scaffolded:

- `hooks/security-hardening/check-sensitive-file.py`
- `hooks/skill-reinforcement/hook-reminder.sh`
- `hooks/claudemd-reminder/` (empty so far)

Inbound from agent K: filled-in `claudemd-reminder` hook, `hooks.json` wiring
all three to the right Claude Code lifecycle events, README.

## M6 - Dogfood (NOT STARTED)

Pick a real project and run the full chain end-to-end. Candidates discussed:

- `oxidize-idle` - Rust idle game; small, fully owned, FP-friendly
  modeling target.
- `fpinscala` - Scala FP exercises; tests the workflow's FP-primitives bias
  but Scala-flavored.
- `sandbox` - generic playground; lowest-stakes way to shake out ergonomics.

Plan, regardless of which:

1. Skip `/triage` (deferred). Every task goes full RPSTIE.
2. `/start-design-plan` from a one-paragraph rough idea.
3. Clear context. `/start-implementation-plan @<design>` -> worktree + phase
   files + test-requirements.md.
4. Clear context. `/execute-implementation-plan @<plan>` -> stub-author,
   test-author, body-implementor per task; code-reviewer + bug-fixer per
   phase; librarian + code-reviewer + test-analyst at end.
5. `/finish-branch` -> merge / PR / discard.
6. Note pain points in a `dogfood-notes.md` and tighten the harness.

Open: which project. Decision deferred to the user when M3-M5 complete.

## Decision Log

Format: `<date> | <decision> | <one-line resolution>`

- 2026-05-06 | tk-harness name | tk-harness, public marketplace; mirrors ed3d
  plugin structure for portability.
- 2026-05-06 | Tier default | Tier 2 nearly-pure functional. Projects may
  override via `.tk-harness/style.md`.
- 2026-05-06 | Subagent models | Opus for orchestrator + code-reviewer;
  Sonnet for everything else; Haiku unused by default. Override in agent
  frontmatter with a justification comment.
- 2026-05-06 | Per-task split | Three subagents: stub-author -> test-author
  -> body-implementor. Diverges from ed3d's single TDD implementor. Honest
  red->green TDD with clear authorship boundaries; stubs/tests are frozen at
  commit SHA on handoff.
- 2026-05-06 | Worktree-mandatory | for any non-trivial task. ed3d makes it
  optional.
- 2026-05-06 | 3-strike fix-loop cap | with auto-escalation. The bug-fixer
  gets at most three cycles before the orchestrator emits a structured
  BLOCKED report and stops.
- 2026-05-06 | Triage gate | DEFERRED. Every task currently routes through
  full RPSTIE. Re-evaluate after M6 dogfood reveals friction points.
- 2026-05-06 | tk-verify scope | slim. `/verify` runner + edit-validation
  hook only; no per-language skills.
- 2026-05-06 | Linter configs | removed from harness scope. The harness
  does not ship defaults. Each project owns its lint setup.
- 2026-05-06 | RPSTIE retained | as the workflow acronym (six stages:
  Research, Plan, Stub, Test, Implement, Eval). The plugin namespace is
  `tk-rpie`, kept short for ergonomics. Plugin name not changing (would
  cascade).
- 2026-05-06 | /verify | a real slash command, not a shorthand. Lives in
  tk-verify/commands/verify.md.
- 2026-05-06 | BLOCKED.md location | `.tk-harness/blocked/<phase-id>-<UTC-timestamp>.md`.
  Timestamp format `YYYYMMDDTHHMMSSZ`. Directory created if missing.
- 2026-05-06 | STATUS sentinel | `STATUS: BLOCKED - <one-line reason>` on
  the LAST LINE of stub-author / test-author / body-implementor reports
  when blocked. ASCII hyphen with spaces, never em-dash. Orchestrator regex:
  `^STATUS: BLOCKED\b`.
- 2026-05-06 | TS unimplemented marker | `throw new Error("not implemented")`
  is the single allowed `throw` in stubs. Tests pin against this exact
  failure mode; ImportError or AttributeError means the stubs are broken
  and the chain halts.
- 2026-05-06 | Glob over find | for `.original` artifacts in code-reviewer
  Step 2b. Consistent with the broader Glob/Grep tool-usage rules; no
  exceptions kept.
- 2026-05-06 | Refactor tag source | OPEN. Recommendation: a phase file
  marker `<!-- TASK_TYPE: refactor -->` that code-reviewer Step 2b checks.
  Final convention not locked.

### Open questions still pending

- **Refactor tag source.** What surface does code-reviewer scan to know a
  task is `refactor:` mode? Recommendation above.
- **Dogfood target.** Which project (oxidize-idle / fpinscala / sandbox) is
  M6's pilot. User pick.
- **Triage revival.** Whether to bring back a triage gate after dogfood
  surfaces friction with full-RPSTIE-on-every-task.

## Open Tasks

### Wave 2 (this same milestone, expected from parallel agents)

- Agent G: nearly-pure-functional anchor + tier files + 3 lang cards.
- Agent H: 6 ported house-style skills with sed renames + provenance.
- Agent J: example `verify.toml` for TS and Python.
- Agent K: filled-in `claudemd-reminder` hook + `hooks.json` wiring.

### Cross-cuts

- **Skill reinforcement hook cross-check.** After tk-house-style lands, the
  skill names referenced by the skill-reinforcement hook in tk-hooks must
  align. Specifically: the hook's reminder list must use the canonical
  tk-house-style skill names (e.g. `tk-house-style:nearly-pure-functional`)
  not stale ed3d names.
- **CHANGELOG discipline.** Maintain a CHANGELOG entry per release going
  forward (one is already in place). The version-sync rule in
  `CLAUDE.md` requires plugin.json bump + marketplace.json bump + CHANGELOG
  entry as a single atomic change.
- **Provenance footer audit.** Every ported file should end with the
  provenance footer specified in `CLAUDE.md`. Spot-check after Wave 2.
- **ASCII audit.** Every `.md` should be ASCII only. Spot-check after Wave 2;
  ed3d burned on em-dashes and smart quotes.

## How to resume in a fresh session

1. Read `/home/tk/Projects/harness/docs/ROADMAP.md` (this file). It is the
   single source of truth for status and decisions.
2. Read `/home/tk/Projects/harness/CLAUDE.md`. It encodes repo-wide
   conventions (XML Task invocations, version sync, FP-primitives block,
   model defaults, frontmatter shapes, ASCII-only).
3. Read `/home/tk/Projects/harness/README.md`. It encodes the public-facing
   workflow shape and plugin roster.
4. Read `/home/tk/Projects/harness/CHANGELOG.md`. It is the canonical
   narrative log of milestones.
5. Run `git -C /home/tk/Projects/harness log --stat` for recent activity not
   yet captured here.

Then proceed with M6 dogfood (or whatever the user picks). Do not start work
without confirming the dogfood target with the user.

## File and path reference

- Marketplace root: `/home/tk/Projects/harness/`
- Plugins: `/home/tk/Projects/harness/plugins/`
- Repo conventions: `/home/tk/Projects/harness/CLAUDE.md`
- Public README: `/home/tk/Projects/harness/README.md`
- Changelog: `/home/tk/Projects/harness/CHANGELOG.md`
- This file: `/home/tk/Projects/harness/docs/ROADMAP.md`
- BLOCKED reports (generated at runtime, project-side):
  `<project>/.tk-harness/blocked/<phase-id>-<YYYYMMDDTHHMMSSZ>.md`
- Verify config (generated at scaffold time, project-side):
  `<project>/.tk-harness/verify.toml`

## Reference: external sources

- ed3dai/ed3d-plugins: https://github.com/ed3dai/ed3d-plugins
- obra/superpowers: https://github.com/obra/superpowers

Local checkout used for ports:
`/home/tk/Projects/External/ed3d-plugins/`.
