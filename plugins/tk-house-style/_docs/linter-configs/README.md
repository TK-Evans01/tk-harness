# tk-house-style linter configs

Scaffold-time defaults for Tier-2 functional-core / imperative-shell projects.

## Model

These configs are **scaffold-time defaults**: when a project is bootstrapped
through tk-house-style, the relevant files under `<lang>/` are **copied**
into the project root. After that copy they are **project-owned** — edit
freely, the harness will not overwrite them.

The harness only ensures sane defaults exist. It is not a runtime ruleset.

## /verify auto-detection

`/verify` lives in the `tk-verify` plugin and runs against **the project's**
config, not this bundle. It auto-detects which linters/typecheckers to run
by reading:

- `package.json` scripts (`lint`, `typecheck`, `arch:lint`)
- `pyproject.toml` `[tool.ruff]`, `[tool.mypy]`, `[tool.importlinter]`
- `Cargo.toml` `[lints]` and `[workspace.lints]`
- a top-level `verify.toml` if present (see each lang's
  `example-verify.toml.snippet`)

The snippets in each language directory show the exact `[verify.<lang>]`
block to drop into a project's `verify.toml`.

## Layout

```
linter-configs/
  README.md                <- you are here
  typescript/
    README.md
    dependency-cruiser.cjs
    eslint.functional.cjs
    tsconfig.strict.json
    ts-pattern-note.md
    example-verify.toml.snippet
  python/
    README.md
    ruff.toml
    importlinter.ini
    mypy.strict.ini
    pyproject-snippet.toml
    example-verify.toml.snippet
  rust/
    README.md
    clippy.toml
    workspace-lints.toml.snippet
    visibility-audit.sh
    example-verify.toml.snippet
```

## Tier-2 coverage matrix

| Rule (Tier-2 forbidden)        | TS                              | Python                  | Rust                            |
|--------------------------------|---------------------------------|-------------------------|---------------------------------|
| throw / raise / panic in core  | functional/no-throw-statements  | grep + reviewer (3a)    | clippy::panic deny              |
| try/catch / except in core     | reviewer (3a) — boundary-only   | reviewer (3a)           | n/a                             |
| null/undefined leaks           | strict-boolean-expressions      | mypy strict + Optional  | clippy::unwrap/expect deny      |
| Date.now / Math.random / uuid  | dep-cruiser (no-impure-in-core) | ruff custom (grep)      | reviewer (3a)                   |
| mutation of arguments          | functional/immutable-data       | ruff B006 + reviewer    | borrow-checker                  |
| mutable global state           | functional/no-let               | ruff PLW0603            | clippy + reviewer               |
| for/while over collections     | functional/no-loop-statements   | ruff PERF / reviewer    | clippy::needless_for_each (warn)|
| any / unknown unjustified      | no-explicit-any                 | ruff ANN401             | reviewer (3a)                   |
| partial functions              | switch-exhaustiveness-check     | reviewer (3a)           | non_exhaustive_omitted_patterns |

Cells marked "reviewer (3a)" rely on the code-reviewer's grep pass — no
linter rule fully covers them.

## Conventions

- ASCII only.
- Configs are syntactically valid; nothing here needs to install or run
  inside this repo.
- Each `<lang>/README.md` lists install commands and the exact
  `lint` / `typecheck` / `arch:lint` invocations.
