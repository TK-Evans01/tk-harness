---
description: Run the project verification gate (typecheck, lint, arch-lint, purity, tests). Reads .tk-harness/verify.toml or auto-detects from package manifests.
argument-hint: [step]
---

# /verify

Run the project verification gate. The pipeline is fail-fast: each step
must pass before the next runs. If any step fails, stop and report.

## Argument

Optional single step name. If supplied, run only that step:

- typecheck
- lint
- arch-lint
- purity
- tests

If no argument is supplied, run the full pipeline in order.

## Procedure

### 1. Resolve configuration

Look for `.tk-harness/verify.toml` in the current working directory.

If present, parse the `[verify.<lang>]` table for the active language.
Active language is selected by which manifest exists (in priority order):

1. `Cargo.toml` -> `[verify.rust]`
2. `pyproject.toml` -> `[verify.python]`
3. `package.json` -> `[verify.typescript]`

If `.tk-harness/verify.toml` is missing, auto-detect using the rules
below. Auto-detection only configures a step when the underlying tool
or config file is actually present; missing tools mean the step is
skipped silently.

### 2. Pipeline order (fail-fast)

1. typecheck
2. lint
3. arch-lint
4. purity
5. tests

A step with no command configured is skipped silently (printed as
`SKIP: <step>` to your own scratch buffer, not to subagents).

### 3. Per-step execution

For each step in order:

- Announce: `RUN: <step> -- <command>`
- Execute the command in the project root.
- Capture stdout and stderr separately.
- On non-zero exit:
  - Print the last 50 lines of stderr (or stdout if stderr empty).
  - Stop the pipeline.
  - Mark overall status FAIL.
- On zero exit:
  - Print `OK: <step>`.
  - Continue.

### 4. Final report

Print one of:

- `VERIFY: PASS` if all configured steps succeeded.
- `VERIFY: FAIL (<step>)` if a step failed; include the last 50 lines
  of stderr from that step.

On FAIL, exit with a non-zero status so callers can branch on it.

### 5. Output to subagents (anti-gaming)

When this command's output will be read by a subagent, restrict the
visible output to:

- The single line `VERIFY: PASS` or `VERIFY: FAIL (<step>)`.
- On FAIL, the last 50 lines of stderr from the failing step only.

Do NOT echo the full stdout of internal commands. Subagents should not
see verbose tool output -- they could otherwise learn to pattern-match
their way past the gate.

## Auto-detection rules

### TypeScript / JavaScript (package.json present)

- `typecheck`: if `tsconfig.json` exists -> `tsc --noEmit`
- `lint`: if `.eslintrc*` or `eslint.config.*` exists -> `eslint .`
- `arch-lint`: if `.dependency-cruiser.cjs` (or `.js`) exists ->
  `depcruise --config .dependency-cruiser.cjs src`
- `purity`: if `eslint.functional.cjs` exists ->
  `eslint -c eslint.functional.cjs .`
- `tests`: if `vitest.config.*` exists -> `vitest run`; else if
  `jest.config.*` exists -> `jest`; else if `package.json` has a
  `test` script -> `npm test --silent`

### Python (pyproject.toml present)

- `typecheck`: if `mypy` available -> `mypy --strict src` (or `.`
  if no `src/`)
- `lint`: if `ruff` available -> `ruff check .`
- `arch-lint`: if `.importlinter` exists -> `lint-imports`
- `purity`: if `.tk-harness/ruff.toml` exists ->
  `ruff check --config .tk-harness/ruff.toml src`
- `tests`: if `pytest` available -> `pytest`

### Rust (Cargo.toml present)

- `typecheck`: `cargo check --workspace`
- `lint`: `cargo clippy --workspace --all-targets -- -D warnings`
- `arch-lint`: if `.tk-harness/scripts/visibility-audit.sh` exists ->
  `bash .tk-harness/scripts/visibility-audit.sh`
- `purity`: skipped (clippy config covers Tier 2 forbidden-list)
- `tests`: `cargo test --workspace`

## Tier 2 purity scan

The `purity` step is where the Tier 2 nearly-pure FP forbidden-list
runs. This is heavier than a parser probe (it's a full lint pass with
a stricter config), which is why it lives here and not in the
edit-validation hook.

The forbidden-list is enforced via the language-native linter using a
config bundled with `tk-house-style`. Point your `purity` command at
that config file.

## Examples

Run the full gate:

```
/verify
```

Run only typecheck:

```
/verify typecheck
```

Run only tests:

```
/verify tests
```

## Notes

- Configuration lives in `.tk-harness/verify.toml`. See
  `_docs/example-verify.toml` in this plugin for a template.
- Linter configs (eslint functional rules, ruff Tier 2, clippy
  presets) come from the `tk-house-style` plugin.
- The edit-validation PostToolUse hook catches syntax breakage at
  edit time, before /verify ever runs. /verify catches semantic
  problems: type errors, lint violations, architectural breaches,
  purity violations, test failures.
