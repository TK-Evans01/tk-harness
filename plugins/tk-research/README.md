# tk-research

Research subagents and supporting skills used during design and verification phases.

Status: M0 skeleton — manifest only.

## Planned Contents

### Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| `codebase-investigator` | sonnet | Read-only repo investigation; verifies file paths, patterns, dependencies |
| `internet-researcher`   | sonnet | External docs, library APIs, current best practices |
| `combined-researcher`   | sonnet | Both, when a single question needs both sources |

### Skills

- `investigating-a-codebase`
- `researching-on-the-internet`

## Behavior Adaptations vs ed3d

- `codebase-investigator` reads `docs/architecture.md` and module-level `AGENTS.md` files first when present, before grep/glob.
- Returns include explicit "files NOT found" list to prevent the agent from inventing locations.

## Provenance

Will be ported from [ed3dai/ed3d-plugins](https://github.com/ed3dai/ed3d-plugins) `ed3d-research-agents` in M1, with adaptations above.
