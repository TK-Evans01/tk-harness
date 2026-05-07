# ts-pattern: prefer `match` over `switch` + `assertNever`

`ts-pattern` gives compile-time exhaustiveness with clearer ergonomics
than the `switch (x) { ... default: assertNever(x); }` pattern.

## Install

```
pnpm add ts-pattern
```

## Use

```ts
import { match, P } from "ts-pattern";

type Event =
  | { kind: "click"; x: number; y: number }
  | { kind: "key"; key: string }
  | { kind: "scroll"; dy: number };

const describe = (e: Event): string =>
  match(e)
    .with({ kind: "click" }, ({ x, y }) => `click @ ${x},${y}`)
    .with({ kind: "key" },   ({ key })  => `key ${key}`)
    .with({ kind: "scroll" },({ dy })   => `scroll ${dy}`)
    .exhaustive();   // <- compile error if a variant is unhandled
```

## Why over `switch + never`

- `.exhaustive()` is enforced at the type level — no runtime
  `assertNever` needed.
- Pattern shapes (nested objects, tuples, `P.string`, `P.union(...)`)
  are first-class.
- Returns a value naturally — composes with `const x = match(...)`.
- No fall-through bugs; no `break` boilerplate.

## Tier-2 fit

Works hand-in-hand with `@typescript-eslint/switch-exhaustiveness-check`:
- Use `match().exhaustive()` for value-producing branching.
- Keep `switch` only where you genuinely need statement-level branching;
  the eslint rule then guarantees exhaustiveness there too.
