# TypeScript linter configs

Scaffold-time defaults. Copy these files into the project root at
scaffold; the project owns them after.

## Files

| File                       | Purpose                                                     |
|----------------------------|-------------------------------------------------------------|
| `eslint.functional.cjs`    | Flat-config ESLint with eslint-plugin-functional + ts rules |
| `dependency-cruiser.cjs`   | Architectural lint: layered rules, core/shell separation    |
| `tsconfig.strict.json`     | `--strict` plus exactOptionalPropertyTypes, etc.            |
| `ts-pattern-note.md`       | One-pager: install ts-pattern, prefer exhaustive `match`    |
| `example-verify.toml.snippet` | The `[verify.typescript]` block                          |

## Install

```
pnpm add -D \
  eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin \
  eslint-plugin-functional \
  dependency-cruiser \
  typescript ts-pattern
```

(npm / yarn equivalents work fine.)

Then drop these files at the project root:

```
cp eslint.functional.cjs    <project>/eslint.config.cjs
cp dependency-cruiser.cjs   <project>/.dependency-cruiser.cjs
cp tsconfig.strict.json     <project>/tsconfig.json   # or extend it
```

## Run

Add to `package.json`:

```json
{
  "scripts": {
    "lint":      "eslint .",
    "typecheck": "tsc --noEmit -p tsconfig.json",
    "arch:lint": "depcruise --config .dependency-cruiser.cjs src"
  }
}
```

`/verify` (from tk-verify) detects and invokes these.

## Tier-2 notes

- `functional/no-classes` is **commented out** in the eslint config —
  too disruptive for codebases using framework classes (NestJS, etc.).
  Re-enable per project.
- `Date.now`, `Math.random`, `crypto.randomUUID` in non-shell files are
  flagged by `dependency-cruiser` via a `no-impure-in-core` rule.
- `try/catch` in core is **not** machine-checked here; the code-reviewer
  pass (Step 3a) greps for it.
