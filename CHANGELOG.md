# Changelog

## [tk-house-style] 0.2.0

Adds higher-level design vocabulary as glossary-style reminders. Section 0
Principles in the FP anchor; perf carve-out exception; design-phase skills
for system topology and architecture; tactical-patterns for GoF dissolution;
api-ergonomics with mandated caller-perspective comment; observability,
boundaries-deeper, and concurrency-deep sub-pages for production primitives.
Skills wired into writing-design-plans, writing-stubs-and-docs, and
body-implementor. Reviewer Steps 3b-3e wired with design-review gating.

**New skills:**
- `skills/api-ergonomics/` (SKILL + `_examples.md` + `caller-perspective.md`)
  - mandatory caller-perspective comment, error-shape positive guidance,
  five-question checklist, anti-vocab (boolean blindness, primitive obsession,
  train wreck, config explosion)
- `skills/system-topology/SKILL.md` - mandatory Topology Decision Record,
  seven-row catalogue (monolith, modular monolith, microservices, microkernel,
  event-driven, dataflow, FaaS), modular-monolith default
- `skills/architecture-patterns/` (SKILL + `_rare-shapes.md`) - mandatory
  Architecture Decision Record, five core patterns (FCIS/hexagonal, pipeline,
  state machine, event-sourced, interpreter), rare shapes split off
- `skills/tactical-patterns/` (SKILL + `typestate-builder.md`) - GoF
  dissolution table; smart constructor + typestate builder survive
- `skills/observability/SKILL.md` - effect-placement table (logger in core
  ok, metrics/spans only in shell), structured logging vocabulary,
  cardinality discipline

**New sub-pages under `nearly-pure-functional/`:**
- `laws-and-reasoning.md` - equational reasoning, algebraic laws,
  parametricity, memoization soundness
- `modeling-deep.md` - phantom/branded types, refinement types, typestate
- `tier-2-perf-carveouts.md` - observably-pure carve-out marker, permitted
  local techniques, equivalence-property test requirement
- `boundaries-deeper.md` - serialization out, schema evolution, canonical
  form, hashing-as-identity
- `concurrency-deep.md` - races, atomicity, channels over locks, back-
  pressure, structured concurrency, idempotent retry

**Changed:**
- `skills/nearly-pure-functional/SKILL.md` - section 0 Principles (12
  one-liners cross-linking primitives to principles); PURITY glossary
  extended with observably pure / local mutation / linear use / transient /
  equivalence property; BOUNDARIES extended with resource lifecycle,
  serialization, concurrency cross-links; section 2 forbidden-list extended
  with observably-pure carve-out exception block
- `skills/nearly-pure-functional/tier-3.md` - vocabulary section: effect vs
  side-effect, capability, determinism boundary, bracket, free monad,
  tagless final, structured concurrency, retry/timeout combinators
- `tk-rpie/agents/code-reviewer.md` - new Steps 3b (perf carve-out),
  3c (api ergonomics + caller-perspective drift), 3d (topology decision
  record, design-review only with REVIEW_TYPE gate), 3e (architecture
  decision record, design-review only with REVIEW_TYPE gate)
- `tk-rpie/skills/writing-design-plans/SKILL.md` - mandatory companions list
  pointing at system-topology, architecture-patterns, nearly-pure-functional,
  api-ergonomics
- `tk-rpie/skills/writing-stubs-and-docs/SKILL.md` - mandatory companion
  pointing at api-ergonomics
- `tk-rpie/agents/body-implementor.md` - Mandatory First Actions extended
  with on-temptation load of tactical-patterns

## [tk-harness] M3+M4+M5 — house-style, verify, hooks, ROADMAP, reconciliation

Six parallel agents landed the rest of the harness in one wave plus a
reconciliation sweep across wave-1 files for locked decisions.

**New (tk-house-style):**
- `skills/nearly-pure-functional/SKILL.md` (180) - Tier-2 anchor: glossary,
  forbidden list, smart constructors, parse-don't-validate
- `skills/nearly-pure-functional/{tier-1,tier-2,tier-3}.md` - tier sub-pages
- `skills/nearly-pure-functional/{typescript,python,rust}.md` - per-language
  quick cards with concrete tooling
- `CLAUDE.md` - plugin-level conventions
- Ported from ed3d-house-style: `writing-good-tests`, `property-based-testing`,
  `howto-code-in-typescript` (+ type-fest, typebox), `howto-code-in-rust`,
  `defense-in-depth`, `coding-effectively` (anchor adapted to point at
  nearly-pure-functional)
- `_docs/anthropic-best-practices.md` (ported)

**New (tk-verify):**
- `commands/verify.md` - slash command, fail-fast pipeline, anti-gaming
  output (subagents see PASS/FAIL + last 50 stderr lines only)
- `hooks/hooks.json` + `edit-validation.sh` + `edit-validation/parsers.sh`
  - PostToolUse parser-based reject for syntactically broken edits
- `_docs/example-verify.toml` + `_docs/README.md`

**New (tk-hooks):**
- `hooks/security-hardening/{check-bash-secrets.py,check-sensitive-file.py}`
  ported from ed3d-hook-security-hardening
- `hooks/claudemd-reminder/git-command-reminder.py` adapted: handles both
  CLAUDE.md and AGENTS.md, scans recent-commit diffs vs unstaged dirty list,
  fires only when context-anchor files are dirty but not staged for commit
- `hooks/skill-reinforcement/hook-reminder.sh` ported (already name-agnostic)
- Combined `hooks.json` + replacement README

**New (tk-rpie skill ports needed by librarian):**
- `skills/maintaining-project-context/SKILL.md`
- `skills/writing-claude-md-files/SKILL.md`

**New (docs):**
- `docs/CONTEXT.md` (376 lines) - comprehensive handoff doc for fresh sessions
- `docs/ROADMAP.md` (~360 lines) - milestone tracking + decision log

**Reconciliation across wave-1 files (locked decisions applied):**
- BLOCKED.md path normalized to `.tk-harness/blocked/<phase-id>-<UTC-timestamp>.md`
  with `YYYYMMDDTHHMMSSZ` timestamp format. Updated 8 files spanning
  stub-author, test-author, body-implementor, code-reviewer agents and
  writing-bodies-against-tests + executing-an-implementation-plan skills.
- STATUS sentinel format `STATUS: BLOCKED - <reason>` (ASCII hyphen, no
  em-dash) added to stub/test/body agent report templates;
  orchestrator regex `^STATUS: BLOCKED\b` specified in
  executing-an-implementation-plan.
- `find . -name '*.original'` replaced with `Glob('**/*.original')` in
  code-reviewer Step 2b; tool-usage-rules exception removed.
- README mentions of "RPIE" workflow normalized to "RPSTIE"; clarifying note
  added that "tk-rpie" remains the plugin namespace.

**Decisions locked in this wave:**
- RPSTIE retained as workflow acronym; tk-rpie is plugin namespace
- /verify is a real slash command in tk-verify (not shorthand)
- BLOCKED.md location standardized
- STATUS sentinel format standardized
- TS unimplemented marker `throw new Error("not implemented")` is the single
  allowed throw exception
- Glob over find for `.original` artifacts

**Known issues / parking lot:**
- `_docs/anthropic-best-practices.md` was ported verbatim and contains
  non-ASCII (box-drawing chars in diagrams). Reference doc only; can be
  scrubbed later if desired.
- TS edit-validation hook can false-positive on monorepos with path aliases
  (uses single-file tsc, no tsconfig). Documented in tk-verify _docs README.
- Refactor-task tagging convention not yet locked; recommended
  `<!-- TASK_TYPE: refactor -->` marker in phase file.
- M6 dogfood target not yet picked.

## [tk-harness] M2 (in progress) — tk-rpie verbatim ports

Mass port of ed3d-plan-and-execute commands and skills via cp+sed renames. References to ed3d plugin namespaces, model names, and `.ed3d/` rewritten to tk-harness equivalents. Provenance footer added to every ported file.

**New (ported):**
- Commands: `start-design-plan`, `start-implementation-plan`, `execute-implementation-plan`, `flesh-it-out`, `how-to-customize`
- Skills: `starting-a-design-plan`, `writing-design-plans`, `starting-an-implementation-plan`, `writing-implementation-plans`, `brainstorming`, `asking-clarifying-questions`, `requesting-code-review`, `verification-before-completion`, `test-driven-development`, `using-git-worktrees`, `finishing-a-development-branch`, `systematic-debugging`, `using-rpie` (renamed from `using-plan-and-execute`)
- Agents: `bug-fixer` (renamed from `task-bug-fixer`), `test-analyst`

**Renames applied via sed:**
- `ed3d-plan-and-execute:` -> `tk-rpie:`
- `ed3d-house-style:` -> `tk-house-style:`
- `ed3d-research-agents:` -> `tk-research:`
- `ed3d-basic-agents:` -> `tk-foundation:`
- `ed3d-extending-claude:` -> `tk-rpie:` (librarian moves into tk-rpie)
- `task-implementor-fast` -> `body-implementor`
- `task-bug-fixer` -> `bug-fixer`
- `project-claude-librarian` -> `librarian`
- `*-general-purpose` -> `*-general`
- `.ed3d/` -> `.tk-harness/`

**Pending (next pass, M2 part 2):**
- REWRITE `executing-an-implementation-plan` skill for stub-author -> test-author -> body-implementor chain (currently ports as-is with a TODO header; collapses our intended split)
- NEW agents: `stub-author`, `test-author`, `body-implementor`, `clarifying-questioner`
- ADAPT `code-reviewer` (FP-primitives check + old-vs-new diff for refactor mode)
- NEW skills: `writing-stubs-and-docs`, `writing-tests-against-stubs`, `writing-bodies-against-tests`, `preserving-original-during-refactor`
- PORT `librarian` agent from ed3d-extending-claude

## [tk-harness] M1 — Foundation + Research Ports

Ports tk-foundation and tk-research from ed3dai/ed3d-plugins (CC-BY-SA-4.0).

**New:**
- `tk-foundation`:
  - Agents: `haiku-general`, `sonnet-general`, `opus-general` (renamed from `*-general-purpose`)
  - Skills: `using-generic-agents`, `two-stage-fanout` (renamed from `doing-a-simple-two-stage-fanout`)
  - Hooks: `session-start` banner reminding to invoke `using-generic-agents` when dispatching generic subagents
- `tk-research`:
  - Agents: `codebase-investigator`, `internet-researcher`, `combined-researcher`, `remote-code-researcher`
  - Skills: `investigating-a-codebase`, `researching-on-the-internet`

**Adapted:**
- `codebase-investigator`: model bumped haiku -> sonnet; reads `docs/architecture.md`, root and module-level `AGENTS.md` / `CLAUDE.md`, and `docs/adr/` as priors before grep/glob; emits "Files NOT found" section for unverifiable assumptions.
- `internet-researcher`, `combined-researcher`, `remote-code-researcher`: model bumped haiku -> sonnet to match tk-harness sonnet-default policy.

**Changed (design adjustments):**
- Dropped triage gate from M2 scope; full RPIE for every task.
- Slimmed `tk-verify` scope: thin `/verify` runner only, no per-language skills. Linter configs are project-owned; the harness does not ship defaults.
- Roadmap renumbered: M2 = `tk-rpie` core, M3 = `tk-house-style`, M4 = `tk-verify`.

## [tk-harness] 0.1.0 — M0 Skeleton

Initial scaffolding for the tk-harness marketplace.

**New:**
- Marketplace manifest with six plugin stubs (tk-foundation, tk-research, tk-house-style, tk-verify, tk-rpie, tk-hooks)
- Per-plugin manifests and directory structure
- Repo conventions documented in CLAUDE.md (XML Task invocations, version sync, FP-primitives block, model defaults, skill/agent frontmatter, ASCII-only encoding)
- README with workflow overview, subagent roster, roadmap

No functional code yet. M1 begins porting from ed3d-plugins.
