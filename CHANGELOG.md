# Changelog

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
