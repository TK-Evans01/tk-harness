# Changelog

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
- `_docs/linter-configs/{typescript,python,rust}/` - bundled defaults
  (eslint-plugin-functional, dependency-cruiser, ruff, import-linter,
  mypy strict, clippy with unwrap-denied) + per-lang README + verify.toml
  snippets

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
- Linter configs bundle hardcoded example names (`myproject`, `billing`,
  `auth`, `notifications`) that scaffold needs to substitute when copying
  into a project.
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
- Slimmed `tk-verify` scope: thin `/verify` runner only, no per-language skills. Linter / typecheck / arch-lint configs bundled in `tk-house-style/_docs/linter-configs/<lang>/`, copied at project scaffold time.
- Roadmap renumbered: M2 = `tk-rpie` core, M3 = `tk-house-style`, M4 = `tk-verify`.

## [tk-harness] 0.1.0 — M0 Skeleton

Initial scaffolding for the tk-harness marketplace.

**New:**
- Marketplace manifest with six plugin stubs (tk-foundation, tk-research, tk-house-style, tk-verify, tk-rpie, tk-hooks)
- Per-plugin manifests and directory structure
- Repo conventions documented in CLAUDE.md (XML Task invocations, version sync, FP-primitives block, model defaults, skill/agent frontmatter, ASCII-only encoding)
- README with workflow overview, subagent roster, roadmap

No functional code yet. M1 begins porting from ed3d-plugins.
