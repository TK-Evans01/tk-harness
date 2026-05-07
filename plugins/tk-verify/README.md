# tk-verify

Verification gate. The atomic primitive the rest of the harness builds on.

Status: M0 skeleton — manifest only.

## Planned Contents

### Command

- `/verify` — runs the full gate against the current working directory. Pass/fail summary + last 50 lines stderr per failed step. Internals hidden from agents (anti-gaming).

### Hooks

- `edit-validation` — PostToolUse hook on Edit/Write. Runs language parser; rejects syntactically broken edits before they hit disk. Inspired by SWE-agent.

No per-language skills. `/verify` is a thin runner. Linter / typecheck / arch-lint configs live in `tk-house-style/_docs/linter-configs/<lang>/` and are copied into projects at scaffold time. Each project owns its configs after that.

## Verify Pipeline

`/verify` reads `.tk-harness/verify.toml` (or auto-detects from `package.json` / `pyproject.toml` / `Cargo.toml`) and runs the configured commands fail-fast in this order:

```
1. typecheck   (e.g., tsc --noEmit / mypy --strict / cargo check)
2. lint        (e.g., eslint / ruff / clippy)
3. arch-lint   (e.g., depcruise / lint-imports / clippy with visibility lints)
4. purity      (e.g., eslint-plugin-functional / ruff custom / clippy)
5. tests       (e.g., vitest / pytest / cargo test)
```

Each step is optional. Subagents see only `pass | fail` + last 50 lines of stderr per failed step (anti-gaming).

Stop condition for completion: all green AND todo list empty AND no uncommitted changes.

## Linter Defaults

Bundled in `plugins/tk-house-style/_docs/linter-configs/<lang>/`. Copied into a project once at scaffold time. The project owns them after that.
