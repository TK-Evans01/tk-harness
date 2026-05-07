# tk-foundation

Generic-purpose subagents and base skills used across the rest of the tk-harness marketplace.

Status: M0 skeleton — manifest only.

## Planned Contents

### Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| `haiku-general`  | haiku  | Cheap fan-out, simple lookups |
| `sonnet-general` | sonnet | Default workhorse for delegated tasks |
| `opus-general`   | opus   | Reserved for hard reasoning when reviewer not appropriate |

### Skills

- `using-generic-agents` — when to dispatch which generic agent
- `two-stage-fanout` — research-then-synthesize pattern (ported from ed3d)

## Provenance

`haiku-general`, `sonnet-general`, `opus-general`, `using-generic-agents`, and `two-stage-fanout` will be ported from [ed3dai/ed3d-plugins](https://github.com/ed3dai/ed3d-plugins) `ed3d-basic-agents` plugin in M1, with attribution preserved.
