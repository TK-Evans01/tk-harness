# Python linter configs

Scaffold-time defaults. Copy into the project root; project-owned
afterward.

## Files

| File                          | Purpose                                                |
|-------------------------------|--------------------------------------------------------|
| `ruff.toml`                   | Ruff rule selection (lint + import order + purity)     |
| `importlinter.ini`            | Architectural contracts: layered, forbidden, indep.    |
| `mypy.strict.ini`             | `--strict` mypy config                                 |
| `pyproject-snippet.toml`      | Equivalent `[tool.*]` blocks for `pyproject.toml`      |
| `example-verify.toml.snippet` | The `[verify.python]` block                            |

## Install

```
pip install ruff mypy import-linter
# or with uv:
uv add --dev ruff mypy import-linter
```

Drop the configs into the project root, **or** merge `pyproject-snippet.toml`
into the project's `pyproject.toml`.

## Run

```
ruff check .
ruff format --check .
mypy --config-file mypy.strict.ini src
lint-imports --config importlinter.ini
```

For `/verify`, expose these as scripts in `pyproject.toml` (e.g. via
`hatch`, `pdm`, or a `[project.scripts]` wrapper) or rely on the
`[verify.python]` snippet which invokes the binaries directly.

## Tier-2 notes

- **No global mutation** — Ruff `PLW0603` flags `global` statements.
- **No mutable defaults** — `B006`.
- **No bare except** — `E722`. Tier-2 forbids `except` in core entirely;
  Ruff cannot scope by file path beyond globs, so `core/**` has
  `BLE001`/`E722` set to error and `try/except` itself is caught by the
  reviewer's grep pass (Step 3a).
- **`Any` requires justification** — `ANN401` errors; suppress with
  `# noqa: ANN401  <reason>` on the line.
- **Frozen dataclasses** — convention, not lintable. Use
  `@dataclass(frozen=True, slots=True)` or `pydantic.BaseModel(frozen=True)`.
- **Match on `Literal`** — convention; mypy's exhaustiveness check
  catches missing cases in `match` only when the discriminant has a
  finite type.
