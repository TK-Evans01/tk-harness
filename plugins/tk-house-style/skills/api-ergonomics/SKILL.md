---
name: api-ergonomics
description: Use when writing module signatures, designing public exports, or reviewing call sites - checks call-site clarity, misuse resistance, error-surface size, and boilerplate ratio; mandates a caller-perspective comment on every stubbed module
---

# API Ergonomics

## Overview

**Core principle:** the public surface is a UX. Pure FP can produce miserable APIs. Discipline does not constrain ergonomics; this skill does.

**Why this matters:** type safety and purity are necessary but not sufficient. A correct API the caller cannot figure out is a defect. Boilerplate compounds; a 3-line setup tax on every call site adds up to thousands of lines across a project.

## When to Use

- Writing or reviewing public module exports
- Reviewing a stub-author signature batch
- Designing an error type that callers must consume
- Caller boilerplate exceeds two lines per useful call
- A module needs an init/setup ordering you can't enforce in types
- Reviewer Step 3c (ergonomics scan)

**Trigger symptoms:**
- "How does the caller use this?"
- A new exported function has more than five positional parameters
- An options object has more than ten fields
- The error type is `string` or generic `Error`
- Documentation reads "first call X, then Y, then Z"

## MANDATORY: Caller-Perspective Comment

**YOU MUST** add, at the top of every stubs file produced by stub-author, a representative call-site example before any signatures:

```
// caller-perspective:
//
//   const cart = Cart.empty();
//   const updated = await cart.addItem({ sku, qty });
//   if (updated.tag === "err") return reportError(updated.error);
//   const result = await orders.place(updated.value, payment);
//   ...
//
```

5 to 15 lines. Real types, real names, the dominant use case. stub-author writes it BEFORE signatures. body-implementor matches it. Reviewer Step 3c flags drift between the comment and the actual exported surface.

NO EXCEPTIONS. A stubs file without this comment is incomplete.

## Glossary (one line each)

- **API surface.** Count of exported symbols. Smaller is easier to learn.
- **Cognitive load.** Concepts the caller must hold in head to use the module.
- **Pit of success.** The default path is the correct path.
- **Misuse resistance.** Wrong usage fails to compile, not at runtime.
- **Discoverability.** IDE autocomplete reveals capability without reading docs.
- **Boilerplate ratio.** Lines of caller setup per line of useful work.
- **Layered API.** High-level convenience fns; low-level escape hatches; both documented.
- **Progressive disclosure.** Easy things easy, hard things possible.
- **Sharp edge.** A documented way to misuse, with the type-level fix recommended.
- **Cohesion vs coupling.** One job per module; narrow exports.
- **Naming legibility.** Domain names not implementation names. `PaymentToken` not `EncodedJWT`.
- **Error surface.** What the caller has to handle. Quality of `Result<T, E>` depends on the usability of `E`.

## Anti-Vocab (smells the reviewer names)

- **Stringly-typed.** Domain in `string`. Antithesis of newtype.
- **Boolean blindness.** `isAdmin: bool` instead of role ADT.
- **Primitive obsession.** `string`/`number` everywhere instead of domain types.
- **Train wreck.** `a.b().c().d()` chain, often nullable.
- **Config explosion.** 40-field options object.
- **Hidden order-of-operations contract.** Must call init before use, not enforced by type.
- **Parameter-list polymorphism.** 10-arg functions with booleans.
- **Hexagonal pyramid scheme.** 3 wrappers per call site.

## Error Shape (positive guidance)

Reviewer flags `string` / `Error` / `unknown` as error types. What good looks like:

- **Discriminated union** with a `tag` field per failure mode the caller can act on.
- **One taxonomy per module.** `ParseError`, `TransferError`, `AuthError`. Don't mix concerns.
- **Distinguish by category:**
  - **Domain error**: business-rule failure, caller decides UX (`out-of-stock`, `payment-declined`).
  - **Infrastructure error**: transient or env-level (`network-timeout`, `db-unavailable`); usually retried at the shell.
  - **Programmer error**: invariant broken; should be unrepresentable, not in `E`.
  - **User-input error**: parser-level; produced by smart constructors at boundaries.
- **Carry context** on each variant: the input that failed, the field name, the boundary value. Enough for the caller to act AND for the operator to debug.
- **No `cause` chain ambiguity.** If you wrap an underlying error, name the field (`cause`) and type it; do not stringify.

Smell: every variant has the same shape `{ tag, message: string }`. That is a string error wearing a tag. Variants must carry case-specific fields.

## Five-Question Review Checklist

Reviewer Step 3c runs through these on every public export:

1. Can a new caller reach success in <=10 lines using only the caller-perspective example?
2. Does the type system reject the most common misuse?
3. Is the error type something the caller can actually act on (ADT with branches), not a string to log?
4. Does autocomplete from a value of the type surface the right next call?
5. Are there two levels (high-level convenience + low-level escape hatch), and are both documented?

A "no" on any => issue. Default to flagging as Important.

## Common Mistakes and Rationalizations

| Excuse | Reality | What to do |
|--------|---------|------------|
| "Caller can read the types" | Types document mechanism; example documents intent. | Write the caller-perspective comment. |
| "Options object is flexible" | 40 fields = 40 things to misconfigure. | Group related fields into typed sub-records or split into multiple constructors. |
| "Error is just a string for now" | "For now" survives to production. Caller has nothing to branch on. | Define an ADT error type with named variants. |
| "Caller will figure out init order" | They won't. They will call out of order and crash in prod. | Encode order with typestate; require init before use at the type level. |
| "We expose internals so callers can do advanced things" | Now you cannot refactor internals without breaking callers. | Layered API: public convenience, separate low-level module. |
| "The 12-arg function is faster" | Caller readability lost; refactor cost high. | Take a struct/record. Argument order is a documentation tax. |
| "We will document the gotchas" | Docs rot. Types do not. | Make the gotcha unrepresentable. |
| "It is more functional to chain" | Chains hide control flow and break under `null`/`undefined`. | `pipe` over explicit values; one stage per line. |

## Red Flags - STOP

- Exported function takes >5 positional args.
- Options object has >10 fields with no progressive grouping.
- Caller has to remember an init order not enforced by types.
- Error type is `string`, `Error`, or `unknown`.
- Public API exposes an internal type (private record, framework primitive).
- "Advanced usage" is the only documented path.
- Caller-perspective comment missing, stale, or contradicts the actual signatures.
- A function name describes implementation (`computeFromCachedDigest`) instead of intent (`getOrder`).

## Sub-pages

- `_examples.md` - before/after for each red flag.
- `caller-perspective.md` - the marker exercise, deeper guidance for stub-author.

## Summary

1. Write the call-site example BEFORE the signatures.
2. The compiler should reject the dominant misuse.
3. Errors are values the caller can act on, not strings to log.

**When in doubt:** put yourself in the caller's editor. If autocomplete and the example do not get them to working code in 10 lines, the API is not ready.

---
Provenance: original to tk-harness; structure cribbed from ed3d-house-style skill conventions (CC-BY-SA-4.0).
