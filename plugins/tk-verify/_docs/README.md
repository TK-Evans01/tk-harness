# tk-verify

The verification gate for tk-harness projects. Two pieces:

1. The `/verify` slash command -- a fail-fast pipeline of typecheck,
   lint, arch-lint, purity, and tests. Run by humans and subagents
   to confirm the working tree is in a good state.
2. The edit-validation PostToolUse hook -- a parser-level probe that
   runs after every Edit or Write tool use and rejects writes that
   would leave a file syntactically broken. Cheap, language-aware,
   and intentionally narrower than `/verify`.

The two layer: the hook catches "you put a stray brace in" before it
hits disk; `/verify` catches "your code parses but is wrong."

## Installing

The plugin's `hooks/hooks.json` is picked up automatically when the
plugin is installed; no per-project setup is needed for the
edit-validation hook. The slash command becomes available the same
way.

To configure `/verify` for a project:

1. Create a `.tk-harness/` directory at the project root.
2. Copy the example into it:

   ```
   cp <plugin-root>/_docs/example-verify.toml \
       .tk-harness/verify.toml
   ```

3. Edit the table that matches your language. Drop or empty-string
   any step you don't want to run.
4. Commit `.tk-harness/verify.toml` so the rest of the team and any
   subagents see the same gate.

If you skip step 2 entirely, `/verify` falls back to auto-detection
based on which manifests and configs it finds. That works for simple
projects but is less explicit -- prefer the toml.

## Linter configs

The actual rule sets used by `lint` and `purity` come from the
`tk-house-style` plugin:

- TypeScript: `eslint.functional.cjs` (Tier 2 nearly-pure FP)
- Python:     `ruff.toml` (Tier 2 forbidden-list)
- Rust:       clippy preset (Tier 2 covered inside the standard
              lint step; no separate purity command needed)

Copy or symlink the config you need from the `tk-house-style` plugin
into your project. `verify.toml` then points at that local copy.

## What the edit-validation hook does

For every file written by Edit or Write, the hook picks a probe
based on extension:

| Extension              | Probe                                      |
|------------------------|--------------------------------------------|
| .ts .tsx .mts .cts     | `tsc --noEmit --allowJs --skipLibCheck`    |
| .js .cjs .mjs .jsx     | `node --check`                             |
| .py                    | `python3 -m py_compile`                    |
| .rs                    | `rustc --emit=metadata` (parse errors only)|
| .json                  | `json.load` via python3                    |
| .toml                  | `tomllib.load` via python3 (3.11+)         |
| .yml .yaml             | `yaml.safe_load` via python3 (if PyYAML)   |
| anything else          | allow                                      |

Design rules:

- **Warn-and-allow on missing tools.** If `tsc` isn't installed,
  the hook skips the probe and prints a one-line warning to stderr.
  It does NOT block the write. The user's `/verify` step is the
  real backstop for type errors.
- **Parse errors only.** For Rust in particular, isolated rustc
  rejects nearly any real file (cross-module imports fail). The
  hook only treats clear parse-level diagnostics as hard rejects;
  resolution errors fall through to allow.
- **Tier 2 purity is NOT here.** The forbidden-list scan is heavier
  than a parser probe; it lives in `/verify`'s `purity` step.

## When the hook gets in your way

If a hook rejection is wrong, you have three escape hatches:

1. Re-issue the edit with the fix.
2. Disable the hook for one session by removing
   `${CLAUDE_PLUGIN_ROOT}/hooks/edit-validation.sh` from
   `hooks.json` -- restart the session to pick up the change.
3. Open an issue with the offending file so we can tighten the
   probe's heuristics.

False positives are possible (especially for Rust); false negatives
are fine because `/verify` will catch them.

## Files

- `commands/verify.md` -- the slash command body
- `hooks/hooks.json` -- PostToolUse registration
- `hooks/edit-validation.sh` -- entry point
- `hooks/edit-validation/parsers.sh` -- per-language probes
- `_docs/example-verify.toml` -- copy this into your project
