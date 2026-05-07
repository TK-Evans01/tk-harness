# Changelog

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
