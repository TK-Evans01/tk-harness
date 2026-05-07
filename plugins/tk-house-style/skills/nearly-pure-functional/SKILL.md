---
name: nearly-pure-functional
description: Use when writing or reviewing code under tk-harness Tier-2 default - enforces nearly-pure functional discipline with Result/Option, ADTs, exhaustive matching, immutability, smart constructors, and a forbidden-construct list scannable by code-reviewer
---

# Nearly-Pure Functional (Tier 2 default)

## Overview

tk-harness defines three discipline tiers for code under its agents. Tier 2 (nearly-pure) is the default. Projects may opt up to Tier 3 (effect-typed) or down to Tier 1 (FCIS-light) by writing the chosen tier name into `.tk-harness/style.md`.

| Tier | Name         | Enforcement                                                                  |
|------|--------------|------------------------------------------------------------------------------|
| 1    | FCIS-light   | Pure core / I/O shell, file pattern comment (ed3d baseline)                  |
| 2    | Nearly-pure  | Tier 1 + Result/Option, no exceptions in core, ADTs, immutability, total fns |
| 3    | Effect-typed | Tier 2 + effects modeled in the type system (IO/Task/Reader-equivalent)      |

This SKILL.md is the anchor. It carries the deep glossary and the forbidden-construct list. Tier-specific rules live in `tier-1.md`, `tier-2.md`, `tier-3.md`. Per-language quick cards live in `typescript.md`, `python.md`, `rust.md`.

The `<fp-primitives-active>` dispatch block (see section 7) is the dispatch-time priming layer: it goes into every code-touching subagent's prompt and points back at this file for the full vocabulary.

## 0. Principles

Primitives are *what*. Principles are *why*. Reviewer names smells with primitives; designer reaches for primitives because of these principles.

- **Functional core, imperative shell (FCIS).** The lattice every other rule snaps onto. Pure logic in one set of files; effects in thin shells.
- **Equational reasoning.** A call may be replaced by its return value. The payoff of purity. See `laws-and-reasoning.md`.
- **Errors as values.** `Result` / `Either` instantiate this. NEVER throw in core.
- **Totality over partiality.** `Option` / `Maybe` instantiate this. NEVER `null` in core.
- **Parse, don't validate.** Smart constructors at boundaries. After parsing, downstream code sees domain types only.
- **Make illegal states unrepresentable.** ADTs over flag-soup. If a combination of fields is invalid, the type system rejects it.
- **Type-driven development.** Signatures first; bodies fill the shape. The stub-author / body-implementor split exists for this reason.
- **Composition over inheritance.** HOF and `pipe`; no class hierarchies for logic.
- **Data-first, behavior-second.** Define the ADT before the operations on it.
- **Errors and effects at the type level, not in your head.** If it can fail or touch the world, the type says so.
- **Inject dependencies.** Reader-style without Reader. Capabilities passed as parameters; never imported globally.
- **Property over example.** When it is a law, prove it. See `../property-based-testing/SKILL.md`.

Depth pages: `laws-and-reasoning.md`, `modeling-deep.md`. Effect-typed depth lives in `tier-3.md` once a project opts in.

## 1. The FP Primitives Glossary

The shared vocabulary every tk-harness subagent must understand. Categories are the categories the code-reviewer scans by.

### PURITY
- **Referential transparency.** A call may be replaced by its return value without changing behavior. The defining property of a pure function.
- **Total function.** Defined for every value of its declared input type. No "this case shouldn't happen" branches.
- **Determinism.** Same input -> same output, always. No clock, no random, no environment, no global state read.
- **Idempotent.** `f(f(x)) == f(x)` for the operation in question. Useful at boundaries (writes, network).
- **Observably pure.** External signature is pure (deterministic, no escaping side effect); internal body may use local mutation, in-place buffers, or SIMD. Marked with the perf-carveout comment. See `tier-2-perf-carveouts.md`.
- **Local mutation.** Permitted inside one stack frame on values not yet escaped. Erased on return.
- **Linear / affine use.** Value used at most once - safe to mutate in place.
- **Transient.** A mutable scratch form of an immutable structure; frozen on return.
- **Equivalence property.** A property test asserting the carve-out impl matches a naive reference impl on representative inputs.

### DATA
- **Immutable.** Values do not change after construction. Updates produce new values.
- **ADT (Algebraic Data Type).** A type built from sums (tagged unions / discriminated unions / enums) and products (records / structs / tuples). The bedrock of "make illegal states unrepresentable."
- **Newtype / branded type.** A nominal wrapper around a primitive (`UserId`, `Email`) that the type system treats as distinct from its underlying type.
- **Persistent data structure.** A collection whose "update" returns a new collection sharing structure with the old (no in-place mutation, no full copy).

### CONTROL
- **Higher-order function.** A function that takes or returns a function.
- **Composition.** `compose` / `pipe`: build big functions from small ones without naming intermediate values.
- **map / filter / fold.** The three workhorses for collection processing. Replace `for` loops in core code.
- **Recursion / fold.** Structural recursion (or its `fold` equivalent) replaces mutable accumulators when `map`/`filter` aren't enough.
- **Pattern matching with exhaustiveness.** Compiler (or runtime guard) verifies every case of an ADT is handled. Adding a variant breaks the build until every match is updated.

### ERROR & ABSENCE
- **Result<T, E> / Either<E, T>.** Two-arm tagged union for fallible operations. Replaces thrown exceptions in core code.
- **Option<T> / Maybe<T>.** Two-arm tagged union for "value may be missing." Replaces `null` / `undefined` returns.
- **Forbidden in core:** `try` / `catch`, thrown exceptions, `null` / `undefined` returns, partial functions.

### BOUNDARIES
- **Parse, don't validate.** External data (JSON, env, args, DB rows) enters through a parser that returns `Result<Domain, ParseError>`. Once parsed, downstream code sees domain types only.
- **Smart constructor.** A factory function that is the only public way to construct a domain type. Validates inputs and returns a Result. The raw constructor is private.
- **Make illegal states unrepresentable.** Encode invariants in the type. ADTs over flag-soup. If a combination of fields is invalid, the type system should reject it.
- **Effects at edges only.** I/O, time, randomness, environment access live in shell layers. The functional core is pure.
- **Resource lifecycle.** Acquire-use-release pairs (file handle, connection, lock, transaction) live in the shell. Wrap with `bracket` / `using` / `defer` / RAII; never leak a handle into core. Cleanup is part of the contract, not an afterthought.
- **Serialization at the boundary.** Smart ctor parses *in*; a corresponding `encode` / `serialize` function emits *out*. Both live at the same edge. See `boundaries-deeper.md`.
- **Concurrency at the boundary.** Pure core is race-free by construction (immutable + no shared state). Locks, channels, queues live in the shell. See `concurrency-deep.md`.

## 2. Forbidden in the Functional Core

The code-reviewer Step 3a scans for these. Keep this list exact and grep-friendly.

- `throw` / `raise` / `panic!` (use Result; the only exception is the language-specific stub marker before body-implementor runs)
- `try` / `catch` / `except` (use Result combinators)
- `null` / `undefined` returns (use Option)
- `Date.now()` / `Math.random()` / `crypto.randomUUID()` and equivalents (inject as parameters; effects belong at the edge)
- mutation of arguments
- mutable class fields
- `this` / instance state for logic (logic is functions over data)
- global / module-level mutable state
- `void` return on logic functions (compute means return a value)
- `for` / `while` loops over collections (use `map` / `filter` / `fold`)
- `any` / `unknown` without a justification comment
- partial functions (every input of the declared type must be handled; if not all inputs are valid, narrow the type)

### Permitted Exception: Observably-Pure Perf Carve-Out

A core file MAY use local mutation, in-place buffer fill, arena allocation, or SIMD intrinsics IF AND ONLY IF every condition holds:

```
// pattern: Functional Core
// perf-carveout: <one-line reason>
// benchmark: <commit-sha or path showing measured win>
// equivalence-test: <test path proving same I/O as naive impl>
```

External signature stays pure: deterministic on declared inputs, no escape of mutable references, no observable side effect across the boundary. Reviewer Step 3b runs the equivalence property test. No proof => reject. Full rules and permitted techniques in `tier-2-perf-carveouts.md`.

NO EXCEPTIONS to the marker requirement. A file without all four lines is not a carve-out; it is a bug.

## 3. Smart Constructors and Parse-Don't-Validate

Any data crossing into the functional core from outside (HTTP body, env var, file content, CLI arg, DB row) goes through a parser whose return type carries the failure mode:

```
parseEmail(raw: string) -> Result<Email, ParseError>
parseOrder(raw: unknown) -> Result<Order, ParseError>
```

The stub-author writes the parser signature first. The body-implementor fills it in. After the parser, downstream code uses `Email`, never `string`. The type alone is the proof the value was validated.

Smart constructors mean the raw constructor is private. The only public path is the parser. The compiler now enforces the invariant.

See `typescript.md`, `python.md`, `rust.md` for language-specific worked examples.

## 4. Make Illegal States Unrepresentable

Don't:

```
type LoadState = {
  isLoading: boolean,
  data: T | null,
  error: Error | null,
}
```

This permits `{ isLoading: true, data: someT, error: someErr }`, which is nonsense. Three booleans means eight states; only four are legal.

Do (TypeScript flavor):

```
type LoadState<T> =
  | { tag: "idle" }
  | { tag: "loading" }
  | { tag: "ok"; data: T }
  | { tag: "err"; error: Error }
```

Now only the four legal states exist. Pattern matching is exhaustive. No invalid combination compiles.

## 5. Tier Sub-Pages

- `tier-1.md` - FCIS-light, the ed3d baseline. Used when a project opts down.
- `tier-2.md` - Nearly-pure (this skill's default). Worked examples.
- `tier-3.md` - Effect-typed opt-in. High overhead in TS / Python; native in Rust / Scala.

## 6. Per-Language Quick Cards

- `typescript.md` - fp-ts / effect-ts, ts-pattern, branded types, eslint-plugin-functional, tsc strict flags.
- `python.md` - returns lib, frozen dataclasses, NewType, match on Literal-tagged unions, ruff / mypy.
- `rust.md` - native Result/Option, exhaustive match, newtype pattern, clippy pedantic.

## 7. The Dispatch-Time Priming Block

Every code-touching subagent (stub-author, body-implementor, code-reviewer, body-tester, eval-runner) gets a block at the top of its prompt:

```
<fp-primitives-active>
Tier: 2 (nearly-pure)
Language: <lang>
Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
Forbidden: throw, null, any, mutation, Date.now in core
</fp-primitives-active>
```

The dispatcher fills in `<lang>` and reads the tier from `.tk-harness/style.md` (default Tier 2). The block primes the subagent's working memory; this SKILL.md provides the deep vocabulary the subagent reaches for when the priming block names a primitive.

## 8. Common Mistakes and Rationalizations

| Excuse / Thought                                                | Reality                                                              | What to do                                                            |
|-----------------------------------------------------------------|----------------------------------------------------------------------|-----------------------------------------------------------------------|
| "I'll just throw, it's simpler"                                 | Throws cross every layer. Callers cannot see them in the type.       | Return `Result<T, E>`. Compose with `map` / `flatMap`.                |
| "`Date.now()` is harmless here"                                 | Non-deterministic. Tests become flaky; logic becomes unreproducible. | Inject `now: Instant` as a parameter. Shell calls the clock.          |
| "`any` is fine for unknown JSON shape"                          | Disables every type guarantee on every downstream caller.            | Parse with zod / pydantic / serde into a domain type. Then proceed.   |
| "Mutating the input is faster"                                  | Aliases break. Tests break. Bugs become spooky-action-at-a-distance. | Return a new value. Persistent collections share structure.           |
| "`null` is conventional in this language"                       | Convention is not a type. Callers forget to check.                   | Return `Option<T>`. The type forces the caller to handle absence.     |
| "I'll handle the error later"                                   | Later never comes. The unhandled path becomes a bug.                 | Encode the error in the return type now. Handle at the edge.          |
| "It's just one `for` loop"                                      | One loop becomes a mutable accumulator becomes a shared variable.    | `map` / `filter` / `fold`. Same shape, no mutation.                   |
| "`unknown` is safe, that's why it's there"                      | Safe in, unsafe out. Every downstream use needs a narrowing.         | Narrow once, at the boundary. Domain code never sees `unknown`.       |
| "This shouldn't happen, so I'll throw"                          | If it shouldn't happen, the type is wrong. If it can, it's not pure. | Narrow the type so the case cannot arise; or return Result.           |
| "Smart constructors are boilerplate"                            | They are the proof. Skipping them means the proof lives in your head.| Write the parser. Make the raw constructor private.                   |

## 9. Red Flags - STOP

If any of these appear in proposed core code, stop and refactor:

- `throw` outside a stub's unimplemented marker
- `null` / `undefined` in a return position
- `try` / `catch` / `except` in a core file
- `Date.now()` / `Math.random()` / RNG / clock / env access in core
- `any` / `unknown` returned from a parser (parser must return a domain type)
- `let` mutation, `for` over a collection, `while` over an accumulator
- `this` in a logic function
- a method that returns `void` and isn't a logger

## 10. Integration with /verify and the Code Reviewer

`/verify` (implemented in `tk-verify`) runs a purity step over changed core files. The check uses the forbidden list in section 2.

The `code-reviewer` agent's Step 3a (FP-primitives scan) greps the same list, plus checks that smart constructors exist for every domain type that crosses a boundary. Failures route the work to a `BLOCKED.md` at `.tk-harness/blocked/<phase>-<timestamp>.md` with the offending lines and the primitive that was violated.

## See Also

- `tier-1.md`, `tier-2.md`, `tier-3.md` - tier-specific rules
- `typescript.md`, `python.md`, `rust.md` - per-language quick cards
- `../writing-good-tests/SKILL.md` - testing discipline (separate skill)
- repo-root `CLAUDE.md` - `<fp-primitives-active>` dispatch block format
