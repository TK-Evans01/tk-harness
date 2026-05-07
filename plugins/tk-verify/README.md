# tk-verify

Verification gate. The atomic primitive the rest of the harness builds on.

Status: M0 skeleton — manifest only.

## Planned Contents

### Command

- `/verify` — runs the full gate against the current working directory. Pass/fail summary + last 50 lines stderr per failed step. Internals hidden from agents (anti-gaming).

### Skills

- `running-the-verify-gate` — how subagents invoke and interpret /verify
- `architectural-lint` — per-language dependency/layer enforcement
- `purity-checks` — Tier-2 FP linter rules

### Hooks

- `edit-validation` — PostToolUse hook on Edit/Write. Runs language parser; rejects syntactically broken edits before they hit disk. Inspired by SWE-agent.

## Verify Pipeline

Default order (fail-fast):

```
1. typecheck       (tsc --noEmit / mypy --strict / cargo check)
2. lint            (eslint / ruff / clippy)
3. architectural   (dep-cruiser / import-linter / crate visibility)
4. purity          (eslint-plugin-functional / ruff custom / clippy lints)
5. tests           (vitest / pytest / cargo test)
```

Stop condition for completion: all green AND todo list empty AND no uncommitted changes.

## Per-Language Configs

Skill drops these into the project on first run:

- TypeScript: `.dependency-cruiser.cjs`, `eslint.config.js` extension
- Python: `.importlinter`, `ruff.toml` overlay
- Rust: `clippy.toml`, workspace visibility audit script

Configs are project-tunable; the harness only ensures they exist with sane defaults.
