# Tier 3: Effect-Typed (opt-in)

Tier 2, plus effects modeled in the type system. A function that performs I/O has it visible in its return type, not just in its body.

Opt in only when the project has a champion who is fluent in the chosen library. Effect types are a force multiplier when you know them and a tax when you don't.

## What Tier 3 Adds Over Tier 2

| Concern        | Tier 2                          | Tier 3                                                |
|----------------|---------------------------------|-------------------------------------------------------|
| Effects        | live in the shell               | live in the type: `IO<A>`, `Task<A>`, `Effect<R,E,A>` |
| Dependencies   | passed as parameters            | tracked in `R` (reader environment)                   |
| Async          | `Promise<T>` / `async fn`       | `Task<A>` / `Effect<R, E, A>` with structured retry   |
| Resource scope | manual `try` / `finally`        | `bracket` / scoped resource combinators               |

Tier 2's discipline (Result, Option, ADTs, smart constructors, no mutation in core) still applies. Tier 3 is additive.

## Per-Language Recommendations

### TypeScript

- **effect-ts** (`Effect<R, E, A>`): the recommended library. Pulls in scheduling, concurrency, retries, dependency injection.
- **fp-ts**: older, lower-level. `Task`, `TaskEither`, `Reader`, `ReaderTaskEither`. Stable, well-documented, more verbose.
- **Cost:** high. New vocabulary, new control flow, ts-server slows on heavy effect graphs. Justify before opting in.

### Python

- **returns** library: `IO[A]`, `IOResult[A, E]`, `Future`, `FutureResult`, `Reader`, `RequiresContext`. Decorator-driven, integrates with mypy.
- **Cost:** high. Python's runtime model fights effect tracking. Most projects stay at Tier 2.

### Rust

- **Native:** `Result`, `Option`, `async fn` returning `Future`, traits for dependency abstraction. Rust covers most of what other languages need libraries for.
- **`tokio` / `async-std`** for runtime; `thiserror` / `anyhow` for error vocabulary; `tower` for service composition.
- **Cost:** low. Rust's type system already does most of this work. Tier 3 in Rust is mostly "use the language as designed."

### Scala (informational; not yet a tk-harness target)

- **cats-effect** `IO[A]` or **ZIO** `ZIO[R, E, A]`. Mature ecosystems.
- **Cost:** low to medium for teams already writing Scala.

## When to Opt In

- The project has long-running async pipelines with retry, timeout, and resource-scope concerns.
- The team has a champion who has shipped effect-typed code before.
- Reviewers can read the chosen library fluently.
- The friction of effect types is less than the friction of the bugs they prevent.

## When to Stay at Tier 2

- The project is mostly request/response or batch.
- The team is new to FP.
- The codebase is small enough that the boundary discipline of Tier 2 is sufficient.
- The chosen language is Python or TypeScript and no champion exists.

## Opt-In Mechanics

A project opts up by writing `Tier: 3` into `.tk-harness/style.md` and naming the chosen library:

```
Tier: 3 (effect-typed)
Library: effect-ts
```

The dispatcher injects this into the `<fp-primitives-active>` block; subagents adjust their stub signatures and review checklist accordingly.

## Vocabulary

- **Effect** vs **side-effect**: effect is named in the type; side-effect is unmodeled.
- **Capability**: value granting permission to perform an effect (Reader-style without ceremony).
- **Determinism boundary**: line where replayability ends; effects cross it.
- **Bracket / scoped resource**: acquire-use-release as a combinator; not manual try/finally.
- **Free monad / interpreter pattern**: program-as-data ADT plus a separate interpreter; reach for it when one program must run against multiple backends (real, mock, replayed).
- **Tagless final**: parameterize the program by an interface of effects rather than a concrete monad; lighter than free monad, heavier on the type system.
- **Structured concurrency**: child tasks bounded by parent scope; cancellation propagates downward; no orphan futures.
- **Retry / timeout / schedule combinators**: declarative policies over an effect, not hand-rolled loops.

## See Also

- `tier-2.md` - what you're building on
- `typescript.md`, `python.md`, `rust.md` - language-specific idioms (Tier 3 sections at the bottom of each)
