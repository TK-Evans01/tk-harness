# Tier 2: Nearly-Pure (default)

The tk-harness default. Everything in Tier 1, plus a vocabulary discipline.

## What Tier 2 Adds Over Tier 1

| Concern              | Tier 1 (FCIS-light)              | Tier 2 (this tier)                                       |
|----------------------|----------------------------------|----------------------------------------------------------|
| Errors in core       | `throw` / `try` / `catch` allowed| `Result<T, E>` only; no exceptions in core               |
| Absence              | `null` / `undefined` allowed     | `Option<T>` only                                         |
| Data shape           | any                              | ADTs (sum + product); illegal states unrepresentable     |
| Branching on tags    | `if` / `switch` informal         | Exhaustive pattern matching (compiler-checked)           |
| Mutation             | discouraged                      | forbidden in core; persistent updates only               |
| Totality             | not enforced                     | every input of the declared type must be handled         |
| Boundaries           | informal                         | smart constructors; parse-don't-validate                 |
| Escape hatches       | -                                | `any` / `unknown` need a justification comment           |

The forbidden list lives in `SKILL.md` section 2. The code-reviewer scans it.

## The Six Rules

### 1. Result / Either replaces try / catch

Fallible core operations return `Result<T, E>` (or the language's equivalent). Composition uses `map`, `flatMap` / `andThen` / `bind`. The shell unwraps at the edge.

### 2. Option / Maybe replaces null / undefined

A function that may return no value returns `Option<T>`. Callers handle `Some` and `None` explicitly.

### 3. ADTs and Exhaustive Matching

Domain states are tagged unions. Every `match` (or `switch` with `never` default, or `match` statement in Python with all `Literal` tags) handles every variant. Adding a variant to the ADT must produce a compile error at every match site.

### 4. Immutability is the Default

No mutation of arguments. No mutable class fields used as logic state. Updates produce new values. Use persistent collections (im in Rust, immer or Object spread in TS, pyrsistent in Python) when sharing matters.

### 5. Total Functions

Every value of the declared input type must produce a defined output. If a subset of the input type is invalid, narrow the type (newtype, smart constructor) so the invalid subset is unrepresentable. No "this should never happen" branches.

### 6. Smart Constructors at Boundaries

External data (JSON, env, file, DB row, CLI arg) enters through a parser:

```
parse(raw): Result<Domain, ParseError>
```

The raw constructor is private. The parser is the only public path. Once parsed, downstream code uses the domain type.

## Worked Example: Order Processing

The same module, in pseudocode, showing the Tier 2 shape.

### ADT for the domain

```
type Money = { amount: Cents; currency: Currency }   // product
type Currency = "USD" | "EUR" | "GBP"                 // sum (Literal)

type LineItem = { sku: Sku; qty: PositiveInt; unit: Money }

type Order =
  | { tag: "draft";    items: ReadonlyArray<LineItem> }
  | { tag: "placed";   items: NonEmptyArray<LineItem>; placedAt: Instant }
  | { tag: "shipped";  items: NonEmptyArray<LineItem>; placedAt: Instant; trackingId: TrackingId }
```

A `draft` may be empty; a `placed` may not (encoded by `NonEmptyArray`). A `shipped` order has a tracking id; a `placed` order does not. Illegal combinations do not compile.

### Smart constructors

```
parsePositiveInt(n: number): Result<PositiveInt, ParseError>
parseSku(raw: string): Result<Sku, ParseError>
parseOrder(raw: unknown): Result<Order, ParseError>
```

The body of `parseOrder` validates structure, then walks fields with `parseSku`, `parsePositiveInt`, currency tag check. Returns `Ok(Order)` or `Err(ParseError)` with the failed field path.

### Pure core function

```
totalForOrder(o: Order): Money
  // total function: every variant handled
  match o:
    draft   -> sumLineItems(o.items)            // may be zero
    placed  -> sumLineItems(o.items)
    shipped -> sumLineItems(o.items)
```

No `Date.now`, no DB, no `null`. The only branching is over the tag, exhaustively.

### Place transition

```
place(o: Order, now: Instant): Result<Order, PlaceError>
  match o:
    draft when o.items is non-empty -> Ok({ tag: "placed", items: o.items, placedAt: now })
    draft                           -> Err(PlaceError.EmptyDraft)
    placed | shipped                -> Err(PlaceError.AlreadyPlaced)
```

`now` is injected. The function is pure: same `(o, now)` -> same result. The shell calls the clock and passes the value in.

### Shell wires it up

```
// pattern: Imperative Shell
async function placeOrder(orderId: OrderId, db: Db, clock: Clock): Promise<Result<Order, PlaceError | DbError>> {
  const raw  = await db.fetchOrder(orderId)            // I/O
  const ord  = parseOrder(raw)                          // boundary parse
  if (ord.isErr) return ord
  const now  = clock.now()                              // effect
  const next = place(ord.value, now)                    // pure core
  if (next.isErr) return next
  await db.saveOrder(orderId, next.value)               // I/O
  return next
}
```

Core is pure. Shell coordinates. Boundary parses. Errors flow through `Result`. No `throw`, no `null`, no `Date.now()` in core.

## What Tier 2 Does Not Require

- It does not require effect types (`IO<A>`, `Task<A>`, `Effect<R, E, A>`). That is Tier 3.
- It does not require all data to be persistent. Local mutation inside a single function (a builder, a folded accumulator) is fine if no caller can observe it. Argument mutation is still forbidden.
- It does not require pure laziness. Eager evaluation is the default in every supported language.

## See Also

- `SKILL.md` - full glossary and forbidden list
- `tier-3.md` - when to opt up
- `typescript.md`, `python.md`, `rust.md` - per-language idioms
