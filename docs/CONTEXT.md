# tk-harness Context Plan

This is the **handoff doc** for resuming work on tk-harness in a fresh Claude Code session. It captures everything from the conversation that produced this repo so a new session can pick up without re-deriving design decisions.

Pair with `README.md` (top-level shape), `CLAUDE.md` (repo conventions), `CHANGELOG.md` (commit-level log), and `docs/ROADMAP.md` (milestone tracking).

---

## 1. What this is

tk-harness is a Claude Code plugin marketplace implementing a strict, opinionated software-engineering workflow on top of subagents and skills. It is a greenfield design that takes structural inspiration from `ed3dai/ed3d-plugins` (which itself derives from `obra/superpowers` by Jesse Vincent) but diverges in several load-bearing ways.

### Core thesis

The harness, not the model, is the binding constraint on real-world coding-agent quality. Concrete primitives in the prompt narrow the model's output distribution; abstract directives don't. Therefore tk-harness:

- Names exact FP primitives (Result, Option, ADT, smart constructor, ...) instead of saying "use functional style"
- Splits the implementer into three sequential subagents (stub-author, test-author, body-implementor) instead of collapsing TDD into one
- Persists state to disk (todos, progress logs, plan artifacts, BLOCKED.md) instead of trusting compaction
- Validates every edit syntactically before it lands (PostToolUse hook)
- Enforces verification through a project-level `/verify` command that is hidden-internals to subagents (anti-gaming)

### Workflow shape

```
Rough Idea
    |
    v
/start-design-plan          ---> Design Document (committed)
    | (clear context)
    v
/start-implementation-plan  ---> Phase files + worktree
    | (clear context)
    v
/execute-implementation-plan ---> per task: stub-author -> test-author -> body-implementor
                                  per phase: code-reviewer -> bug-fixer (3-strike cap)
                                  end: librarian -> code-reviewer -> test-analyst
    |
    v
/finish-branch               ---> merge / PR / discard
```

Acronym: **RPSTIE** (Research-Plan-Stub-Test-Implement-Eval). Plugin namespace is `tk-rpie` (kept short).

---

## 2. Architecture

### Plugins (six)

| Plugin | Role |
|--------|------|
| `tk-foundation`  | Generic-purpose subagents (haiku-general, sonnet-general, opus-general) and base skills |
| `tk-research`    | Research subagents: codebase-investigator, internet-researcher, combined-researcher, remote-code-researcher |
| `tk-house-style` | Tier-2 nearly-pure functional style; per-language quick cards; bundled linter configs |
| `tk-rpie`        | The RPSTIE workflow: commands + 8+ subagents + 18+ skills |
| `tk-verify`      | Thin `/verify` runner + PostToolUse edit-validation hook |
| `tk-hooks`       | Cross-cutting: security-hardening, claudemd-reminder, skill-reinforcement |

### Subagent roster (the core innovation)

| Stage | Agent | Model | Notes |
|-------|-------|-------|-------|
| Orchestrate | main thread | opus | Top-line; user interacts here |
| Research | `codebase-investigator` | sonnet | Reads docs/architecture.md + AGENTS.md/CLAUDE.md priors before grep |
| Research | `internet-researcher` | sonnet | |
| Research | `combined-researcher` | sonnet | Synthesizes both |
| Research | `remote-code-researcher` | sonnet | Clones to stable cache, cites file:line |
| Design | `clarifying-questioner` | sonnet | Single-shot, max 5 questions, type-tagged |
| **Stubs** | **stub-author** | sonnet | Writes signatures + contract docs; typechecks; commits "stubs:" |
| **Tests** | **test-author** | sonnet | Writes tests vs frozen stubs; "see red first" mandatory; commits "tests:" |
| **Bodies** | **body-implementor** | sonnet | One fn at a time; full /verify at end; commits "impl:" |
| Review | `code-reviewer` | **opus** | Per-phase; FP-primitives scan; refactor old-vs-new diff; 3-strike BLOCKED.md |
| Fix | `bug-fixer` | sonnet | Consumes review punch list; capped 3 cycles |
| Final tests | `test-analyst` | sonnet | AC coverage validation; emits human test plan |
| Docs | `librarian` | sonnet | Updates CLAUDE.md / module AGENTS.md when contracts change |

**Models:** Opus only for orchestrator + code-reviewer. Sonnet default everywhere else. Haiku unused by default.

**Sequencing:** Single-thread agent. Reads parallel-safe; writes serialized. Per Cognition's "Don't Build Multi-Agents" — implicit-decision conflicts kill multi-writer fan-out.

### Per-task chain (the divergence from ed3d)

ed3d collapses TDD into one task-implementor-fast (haiku) that writes test, then code, then commits. We split:

```
Per task:
  stub-author      -> commits stubs (signatures + docstrings + types)  [STUBS_SHA]
  test-author      -> commits tests vs frozen stubs (must fail unimplemented, NOT ImportError)  [TESTS_SHA]
  body-implementor -> commits bodies, fns one at a time; full /verify  [IMPL_SHA]

Per phase (after all task chains):
  code-reviewer (opus) -> punch list (Critical / Important / Minor)
  bug-fixer (loop, 3-strike) -> fixes; re-review
  if 3 cycles same issues -> BLOCKED.md, escalate

After all phases:
  librarian -> updates CLAUDE.md / AGENTS.md
  code-reviewer -> final pass + AC coverage
  test-analyst -> human test plan
  finishing-a-development-branch -> merge / PR / discard
```

**Invariants:**
- Stubs frozen at STUBS_SHA when test-author runs.
- Tests frozen at TESTS_SHA when body-implementor runs.
- body-implementor MUST NOT edit stubs or tests. If wrong, escalate via BLOCKED.md.
- Each subagent prints full response back to user before next dispatch (human-transparency rule).

---

## 3. House style — Tier-2 nearly-pure functional

### Tier model

| Tier | Name | Enforcement |
|------|------|-------------|
| 1 | FCIS-light | Pure core / I/O shell, file pattern comment (ed3d baseline) |
| 2 | **Nearly-pure** (DEFAULT) | Tier 1 + Result/Option, no exceptions in core, ADTs + exhaustive match, immutability, total functions, smart constructors |
| 3 | Effect-typed | Tier 2 + effects modeled (IO/Task/Reader-equivalent in lang) |

Project may override via `.tk-harness/style.md`.

### FP Primitives Glossary (the "fresh in mind" priming)

```
PURITY
  - referential transparency
  - total function (handles every input, no panic/throw)
  - determinism (no Date.now/Math.random/UUID in core)
  - idempotent

DATA
  - immutable (no mutation, no &mut, no let-rebinding)
  - algebraic data type (ADT): sum (discriminated union) + product (record)
  - newtype / branded type for domain primitives
  - persistent data structure (structural sharing for "updates")

CONTROL
  - higher-order function
  - composition: compose / pipe (|> or pipe())
  - map / filter / fold (reduce) — NOT for/while loops in core
  - recursion / fold over manual iteration
  - pattern matching with exhaustiveness check

ERROR & ABSENCE
  - Result<T,E> / Either<E,A>  — fallible operations
  - Option<T> / Maybe<T>       — absence
  - NEVER: try/catch in core, thrown exceptions, null/undefined leaks, partial functions

BOUNDARIES
  - parse-don't-validate: parse at edge, trust internally
  - smart constructor returning Result<Domain, ParseError>
  - make illegal states unrepresentable
  - effects at edges only (Imperative Shell)
```

### Forbidden in functional core (machine-greppable list — code-reviewer Step 3a)

- `throw` / `raise` / `panic`
- `try` / `catch` / `except` (use Result)
- `null` / `undefined` returns (use Option)
- `Date.now` / `Math.random` / `crypto.randomUUID` (inject as parameter)
- mutation of arguments
- mutable class fields
- `this` / instance state outside shell
- global / module-level mutable state
- void return on logic functions (compute returns a value)
- `for` / `while` loops over collections (use map/filter/fold)
- `any` / `unknown` without justification comment
- partial functions (must handle all inputs total)

### FP-Primitives Active Block (dispatch-time priming)

Injected into every coding-subagent prompt at dispatch time:

```
<fp-primitives-active>
Tier: 2 (nearly-pure)
Language: <lang>
Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
Forbidden: throw, null, any, mutation, Date.now in core
</fp-primitives-active>
```

Rationale: chaos-theory framing. Naming concrete primitives narrows output entropy more than abstract directives.

### TS unimplemented marker exception

The single allowed `throw` in tk-harness is the stub marker:

```typescript
throw new Error("not implemented")
```

Used only in stub bodies, must be replaced by body-implementor. Documented exception.

---

## 4. Conventions

### File structure

```
tk-harness/
  .claude-plugin/marketplace.json
  README.md           (workflow + plugin table + roadmap)
  CLAUDE.md           (this repo's conventions)
  CHANGELOG.md
  LICENSE             (CC-BY-SA-4.0; ports retain MIT for obra/superpowers descendants)
  docs/
    CONTEXT.md        (this file)
    ROADMAP.md        (milestone tracking)
    adr/              (decisions, append-only — empty for now)
  plugins/
    tk-<name>/
      .claude-plugin/plugin.json
      README.md
      LICENSE
      agents/<agent>.md
      skills/<skill-name>/SKILL.md (+ supporting .md / scripts)
      commands/<cmd>.md
      hooks/hooks.json + scripts
      _docs/<reference>.md
```

### Frontmatter

**Skill:**
```yaml
---
name: skill-name-with-hyphens
description: Use when <trigger> - <what it does, third person>
---
```

Optional: `user-invocable: false` for internal-only skills.

**Agent:**
```yaml
---
name: agent-name
model: sonnet  # or opus / haiku
color: cyan    # frontend hint
description: One-line summary of when to dispatch
---
```

Agent body must START with "Mandatory First Actions" listing skills to invoke.

### XML Task invocations (not prose)

```
<invoke name="Task">
<parameter name="subagent_type">tk-rpie:stub-author</parameter>
<parameter name="description">Stubs for Phase X Task Y: <desc></parameter>
<parameter name="prompt">
<fp-primitives-active>
Tier: 2 (nearly-pure)
Language: typescript
Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
Forbidden: throw, null, any, mutation, Date.now in core
</fp-primitives-active>

Phase file: /worktree/docs/implementation-plans/.../phase_02.md
Task: 3
Working dir: /worktree
Language: typescript
</parameter>
</invoke>
```

Adopted from ed3d for on-rails fidelity.

### Version sync discipline

Bumping a plugin's `.claude-plugin/plugin.json` version requires:
1. Match version in root `.claude-plugin/marketplace.json`
2. Add CHANGELOG.md entry under `## [<plugin>] <version>` heading

### ASCII-only encoding

Every `.md` file. Use `->` not arrow chars, straight quotes, plain hyphens. ed3d burned on this; we hold the line.

### Provenance footers

Files ported from ed3d get a footer:

```

---
Provenance: ported from ed3d-plugins/<source-plugin> (CC-BY-SA-4.0); ultimately derived from obra/superpowers (MIT) [if applicable].
```

---

## 5. Decision Log

Date | Decision | Detail
---- | -------- | ------
2026-05-06 | Project name | `tk-harness`. Public on github. https://github.com/TK-Evans01/tk-harness
2026-05-06 | License | CC-BY-SA-4.0 for original; MIT for files derived from obra/superpowers
2026-05-06 | Marketplace structure | Mirror ed3d (one repo, plugins/ subdir, .claude-plugin/marketplace.json)
2026-05-06 | Tier default | Tier 2 nearly-pure functional
2026-05-06 | Subagent models | Opus for orchestrator + code-reviewer; Sonnet for everything else; Haiku unused by default
2026-05-06 | Per-task split | Three subagents: stub-author -> test-author -> body-implementor (vs ed3d's single TDD implementor)
2026-05-06 | Worktree-mandatory | for non-trivial tasks; ed3d makes it optional
2026-05-06 | 3-strike fix-loop cap | with auto-escalation to BLOCKED.md
2026-05-06 | Triage gate | DEFERRED. Every task currently routes through full RPSTIE.
2026-05-06 | tk-verify scope | Slim. Only `/verify` runner + edit-validation hook. No per-language skills. Linter configs bundled in tk-house-style.
2026-05-06 | Acronym | RPSTIE retained as workflow name. Plugin namespace is `tk-rpie` (kept short for ergonomics).
2026-05-06 | /verify | Real slash command (not shorthand for typecheck+lint+test).
2026-05-06 | BLOCKED.md location | `.tk-harness/blocked/<phase-id>-<UTC-timestamp>.md`
2026-05-06 | STATUS sentinel | Last line of agent report when blocked: `STATUS: BLOCKED - <one-line reason>`. Orchestrator regex: `^STATUS: BLOCKED\b`.
2026-05-06 | TS unimplemented marker | `throw new Error("not implemented")` — single allowed throw exception in stubs only.
2026-05-06 | Glob over find | for `.original` artifacts; consistent with tool-usage rules.
2026-05-06 | Refactor tag source | OPEN. Recommend `<!-- TASK_TYPE: refactor -->` marker in phase file. Not yet locked.
2026-05-06 | Project dogfood target | OPEN. Candidates: `oxidize-idle`, `fpinscala`, fresh sandbox. Not picked.

---

## 6. Plugin Status (as of last commit)

Run `git -C /home/tk/Projects/harness log --oneline` for current commit list.

### tk-foundation — DONE (M1)

Files:
- `agents/haiku-general.md`, `sonnet-general.md`, `opus-general.md` (renamed from `*-general-purpose`)
- `skills/using-generic-agents/SKILL.md`
- `skills/two-stage-fanout/SKILL.md` + `compute_layout.py` + `diagram-templates.md`
- `hooks/hooks.json` + `session-start.sh`

All ported from ed3d-basic-agents. Provenance footers in place.

### tk-research — DONE (M1)

Files:
- `agents/codebase-investigator.md` (ADAPTED — reads docs/architecture.md + AGENTS.md priors first; emits "Files NOT found" section; bumped haiku -> sonnet)
- `agents/internet-researcher.md`, `combined-researcher.md`, `remote-code-researcher.md` (sonnet)
- `skills/investigating-a-codebase/SKILL.md`, `researching-on-the-internet/SKILL.md`

Ports from ed3d-research-agents.

### tk-rpie — DONE pending wave-2 reconciliation (M2)

**Commands** (all ported from ed3d, sed-renamed):
- `start-design-plan.md`
- `start-implementation-plan.md`
- `execute-implementation-plan.md` (REWRITTEN body)
- `flesh-it-out.md`
- `how-to-customize.md`

**Agents:**
- `stub-author.md` (NEW, 118 lines)
- `test-author.md` (NEW, 116 lines)
- `body-implementor.md` (NEW, 200 lines)
- `code-reviewer.md` (ADAPTED, 426 lines — opus, +Step 2b refactor diff, +Step 3a FP-primitives scan, +Step 7 BLOCKED.md)
- `bug-fixer.md` (ported, renamed from `task-bug-fixer`)
- `clarifying-questioner.md` (NEW, 126 lines)
- `librarian.md` (PORTED from ed3d-extending-claude:project-claude-librarian; depends on two skills below)
- `test-analyst.md` (ported)

**Skills:**
- Ported (sed-renamed + provenance):
  - `starting-a-design-plan/`, `writing-design-plans/`
  - `starting-an-implementation-plan/`, `writing-implementation-plans/`
  - `brainstorming/`, `asking-clarifying-questions/`
  - `requesting-code-review/` (with code-reviewer.md cross-link)
  - `verification-before-completion/`, `test-driven-development/`
  - `using-git-worktrees/`, `finishing-a-development-branch/`
  - `systematic-debugging/` (multiple files including test fixtures)
  - `using-rpie/` (renamed from `using-plan-and-execute`)
- New:
  - `writing-stubs-and-docs/SKILL.md` (216 lines)
  - `writing-tests-against-stubs/SKILL.md` (276 lines)
  - `writing-bodies-against-tests/SKILL.md` (219 lines)
  - `preserving-original-during-refactor/SKILL.md` (166 lines)
- Rewritten:
  - `executing-an-implementation-plan/SKILL.md` (740 lines — orchestrates the 3-agent chain)

**Pending wave-2 ports (dependencies of librarian):**
- `maintaining-project-context/SKILL.md`
- `writing-claude-md-files/SKILL.md`

### tk-house-style — IN PROGRESS (M3)

In flight via parallel agents:
- Anchor + tier files + per-language cards (`nearly-pure-functional/SKILL.md`, `tier-1.md`, `tier-2.md`, `tier-3.md`, `typescript.md`, `python.md`, `rust.md`)
- 6 ported skills (writing-good-tests, property-based-testing, howto-code-in-typescript, howto-code-in-rust, defense-in-depth, coding-effectively + anthropic-best-practices doc)
- Bundled linter configs in `_docs/linter-configs/{typescript,python,rust}/`

### tk-verify — IN PROGRESS (M4)

In flight:
- `commands/verify.md` (slash command)
- `hooks/hooks.json` + `edit-validation.sh` (PostToolUse parser-based reject)
- `_docs/example-verify.toml` + `_docs/README.md`

### tk-hooks — IN PROGRESS (M5)

In flight:
- Bundle three hooks under one plugin: `security-hardening/`, `claudemd-reminder/`, `skill-reinforcement/`
- Combined `hooks.json` mapping events
- skill-reinforcement adapted to tk-harness skill names
- claudemd-reminder extended to also notice AGENTS.md changes

### M6 — Dogfood — NOT STARTED

Pick a real project. Run `/start-design-plan` ... `/finish-branch` end-to-end. Note pain. Tighten harness based on observed failures. Could be `~/Projects/oxidize-idle`, `~/Projects/fpinscala`, or a fresh sandbox.

---

## 7. Open Questions / Parking Lot

| Q | Status |
|---|--------|
| Refactor task tagging — `<!-- TASK_TYPE: refactor -->` marker in phase file? | Recommended; not locked |
| Dogfood target | Not picked |
| Optional `tools:` whitelist on agent frontmatter | Deferred. Add later if security or perf shows need |
| Should `/verify` write its own report file (e.g., `.tk-harness/verify/<timestamp>.json`)? | Open. ed3d doesn't. Probably yes for postmortem replay |
| Triage gate | Deferred — not in scope this round |
| ADR (architecture decision record) workflow | Mentioned in docs structure; no skills yet |

---

## 8. Skipped from ed3d (intentional)

| ed3d component | Reason |
|----------------|--------|
| `ed3d-playwright` | Browser automation. Out of scope. |
| `ed3d-session-reflection` | Experimental conversation review. |
| `ed3d-00-getting-started` | Will write `tk-getting-started` separately if needed. |
| `ed3d-extending-claude` (most) | Meta-knowledge. Only ported librarian + 2 skills. |
| `ed3d-house-style/programming-in-react` | Not language-agnostic. |
| `ed3d-house-style/howto-develop-with-postgres` | Domain-specific. |
| `ed3d-house-style/writing-for-a-technical-audience` | Off-topic for code harness. |
| `ed3d-house-style/_docs/persuasion-principles.md` | Skipped. |

---

## 9. Resume Protocol (fresh session)

1. Read this file.
2. Read `/home/tk/Projects/harness/CLAUDE.md` (repo conventions).
3. Read `/home/tk/Projects/harness/README.md` (workflow + plugin shape).
4. Read `/home/tk/Projects/harness/CHANGELOG.md` (commit-level log).
5. Read `/home/tk/Projects/harness/docs/ROADMAP.md` (milestones, granular tasks).
6. Run `git -C /home/tk/Projects/harness log --oneline --decorate` for commit graph.
7. Run `git -C /home/tk/Projects/harness status` for any uncommitted state.
8. Reference repo `~/Projects/External/ed3d-plugins/` is read-only; cribbed for ports.

If wave 2 is still in flight (tk-house-style, tk-verify, tk-hooks, ROADMAP, librarian skill deps), the most recent commit message + `git status --short` will show what's missing. Resume by waiting for or running those agents, committing, then proceeding to M6 dogfood.

---

## 10. Reference repo

`~/Projects/External/ed3d-plugins/` (cloned shallow, never edited).

```
ed3d-plugins/
  plugins/
    ed3d-00-getting-started/
    ed3d-plan-and-execute/      <- the workflow plugin we forked
    ed3d-house-style/           <- our tk-house-style derives from this
    ed3d-basic-agents/          <- our tk-foundation derives from this
    ed3d-research-agents/       <- our tk-research derives from this
    ed3d-extending-claude/      <- librarian + 2 skills only
    ed3d-playwright/            <- skipped
    ed3d-hook-skill-reinforcement/   <- our tk-hooks bundles this
    ed3d-hook-claudemd-reminder/     <- our tk-hooks bundles this
    ed3d-hook-security-hardening/    <- our tk-hooks bundles this
    ed3d-session-reflection/    <- skipped
```

ed3d itself derives many skills from `obra/superpowers` (Jesse Vincent, MIT). Both attribution chains preserved per file.

---

## 11. Key conversation insights worth retaining

- **Why three agents per task, not one:** stubs frozen at SHA before tests; tests frozen at SHA before bodies. Reviewer can diff each commit. Test-author cannot bias toward implementation it hasn't seen. Body-implementor cannot drift from contract because tests enforce it.
- **Why opus only on reviewer + main:** review catches subtle bugs (sustained focus); orchestrator owns dispatch decisions. Implementation roles are well-scoped enough for sonnet.
- **Why sonnet not haiku for stub/test/body:** ed3d uses haiku for task-implementor-fast. We bumped to sonnet because Tier-2 FP discipline is non-trivial; haiku rationalizes shortcuts. Cost trade-off accepted.
- **Why grep + tree-sitter map over embeddings:** embeddings retrieve wrong chunks silently. Aider's PageRank-style symbol map proven; ed3d follows same. We do too.
- **Why write to disk over compaction summaries:** compaction is lossy. AGENTS.md, todos, progress.md, BLOCKED.md, plan files survive. Compaction summarizes prompts; artifacts survive.
- **Why slim tk-verify:** linter configs are project-owned after scaffold. Verify is a thin runner; per-language skills bloat context with no benefit. Configs ship in tk-house-style/_docs/linter-configs/.
- **Why FP-primitives active block injection at dispatch:** chaos-theory narrowing. Naming concrete primitives in the prompt biases output more than abstract style directives. Empirical effect.
- **Why human-transparency rule:** orchestrator must print every subagent's full response. Otherwise user loses visibility into their own codebase. Adopted from ed3d.

---

End of CONTEXT.md.
