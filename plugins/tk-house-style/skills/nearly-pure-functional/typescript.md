# TypeScript Quick Card (Tier 2)

Concrete tooling and idioms for nearly-pure functional TypeScript.

## Libraries

- **fp-ts** or **effect-ts** for `Option`, `Either`, `Task`, `Reader`. Pick one per project. effect-ts is the more modern choice; fp-ts is the simpler one.
- **ts-pattern** for exhaustive pattern matching against discriminated unions. (Or: plain `switch` with a `never`-typed default.)
- **zod**, **valibot**, or **io-ts** for parsers (parse-don't-validate at boundaries).
- **immer** if you need ergonomic persistent updates on deeply nested structures. Object/array spread is fine for shallow ones.

## Type-System Setup

In `tsconfig.json`:

```
"strict": true,
"noUncheckedIndexedAccess": true,
"exactOptionalPropertyTypes": true,
"noImplicitOverride": true,
"noFallthroughCasesInSwitch": true
```

`strict` is non-negotiable. `noUncheckedIndexedAccess` is what makes `arr[i]` return `T | undefined` and forces an Option-style narrowing.

## Lint

Use `eslint-plugin-functional`. Recommended rules:

- `functional/no-let` (use `const`)
- `functional/no-loop-statements` (use `map` / `filter` / `reduce`)
- `functional/no-throw-statements` (use Either / Result)
- `functional/no-this-expressions`
- `functional/immutable-data`
- `functional/prefer-readonly-type`
- `functional/prefer-tacit`
- `functional/type-declaration-immutability`

Plus the standard `@typescript-eslint/no-explicit-any` (warn, with a justification comment to silence per use).

## Idioms

### Discriminated Union ADT

```
type Result<T, E> =
  | { readonly _tag: "ok";  readonly value: T }
  | { readonly _tag: "err"; readonly error: E }
```

The `_tag` field discriminates; `readonly` makes mutation a compile error.

### Branded Type

```
type Brand<T, B> = T & { readonly __brand: B }
type UserId = Brand<string, "UserId">
type Email  = Brand<string, "Email">
```

`UserId` is a `string` at runtime but distinct from `string` to the type system. The only way to construct one is the smart constructor.

### Smart Constructor (parse-don't-validate)

```
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export const parseEmail = (raw: string): Either<ParseError, Email> =>
  EMAIL_RE.test(raw)
    ? right(raw as Email)
    : left({ kind: "InvalidEmail", value: raw })
```

The cast is contained inside the parser. Every other call site uses `parseEmail` and gets a domain type.

### Exhaustive switch with never

```
type Shape =
  | { _tag: "circle"; r: number }
  | { _tag: "rect";   w: number; h: number }

const area = (s: Shape): number => {
  switch (s._tag) {
    case "circle": return Math.PI * s.r * s.r
    case "rect":   return s.w * s.h
    default: {
      const _exhaustive: never = s
      return _exhaustive
    }
  }
}
```

Add a new variant to `Shape` and the `default` block fails to compile until the new case is handled. (`ts-pattern`'s `.exhaustive()` does the same with less ceremony.)

### Result.map composition

```
const placeOrder = (raw: unknown, now: Instant): Either<DomainError, Order> =>
  pipe(
    parseOrder(raw),
    chain((o) => place(o, now)),
    map((o) => withAuditStamp(o, now))
  )
```

No `try` / `catch`. No `throw`. The error flows through the `Either`.

## The Single Allowed Throw: Stub Marker

Stubs (signature-only files written by stub-author) use:

```
throw new Error("not implemented")
```

This is the single permitted `throw` in the codebase. It exists only between the stub-author phase and the body-implementor phase. After body-implementor runs, no `throw` should remain in core code. The code-reviewer flags any other `throw` in core.

Equivalent options the project may pick instead (configure once, use everywhere):

```
function unimplemented(): never { throw new Error("not implemented") }
```

## Anti-Patterns

| Anti-pattern                          | Why it's wrong                                       | Replace with                          |
|---------------------------------------|------------------------------------------------------|---------------------------------------|
| `any`                                 | Disables every type guarantee downstream             | Parse to a domain type at the edge    |
| Non-readonly types                    | Permits mutation; aliasing bugs                      | `Readonly<T>`, `ReadonlyArray<T>`     |
| `let` in core                         | Mutable accumulator                                  | `reduce` / `map` / `filter`           |
| `for` over a collection               | Same problem                                         | `array.map` / `array.reduce`          |
| `throw` outside the stub marker       | Bypasses Result; invisible in the type signature     | Return `Either<E, T>`                 |
| `null` return                         | Caller forgets to check                              | Return `Option<T>` (`O.some` / `O.none`) |
| `Date.now()` in core                  | Non-deterministic; flaky tests                       | Inject `now: Instant`                 |
| Untagged union (`Foo \| Bar`)         | Cannot pattern-match                                 | Tagged: `{_tag: "foo", ...}`          |
| `class` with mutable fields           | Logic-as-state                                       | `type` + functions                    |

## Tier 3 Note (effect-ts)

If the project opts up to Tier 3, `Either<E, T>` becomes `Effect<R, E, A>`, dependencies move from explicit parameters into `R`, and async `Promise<T>` / `Task<T>` becomes the same `Effect`. See `tier-3.md`.
