---
name: writing-stubs-and-docs
description: Use when authoring typed function stubs and contract docstrings ahead of tests and bodies - declares signatures, branded primitives, Result/Option error shapes, smart constructors, and unimplemented markers, with a typecheck gate before commit.
user-invocable: false
---

# Writing Stubs and Docs

## Overview

A stub is a frozen contract: a fully typed signature plus a docstring describing the promise, with the body left unimplemented. Stubs are written BEFORE tests and BEFORE bodies. The next agent writes tests against the contract you froze; the agent after that writes the body that satisfies both.

Stubs are NOT logic. Stubs are NOT tests. Stubs are NOT placeholders for "I'll figure out the types later".

## Why Split Stubs From Bodies

- Tests written against stubs describe the contract, not the implementation. A test that needs to know how the body works is testing the wrong thing.
- A reviewer can read three commits in sequence: `stubs: X` shows the contract, `tests: X` shows the desired behavior in code, `impl: X` shows the body. Each commit is small and focused.
- It is structurally impossible for a test to "accidentally pass" against an unimplemented stub. The stub raises `NotImplementedError` / `unimplemented!()` / `throw new Error("not implemented")`. The test must fail until the body is written.
- Type errors caught at the stub stage cost minutes. The same errors caught after a body is written cost hours and require deleting code.

## Stub Anatomy

Every stub has:

1. **Signature with full types.** No `any`. No bare `unknown` (use a parsed ADT instead). No implicit return types in TypeScript. No untyped `*args`/`**kwargs` in Python without a `TypedDict` or dataclass.
2. **Domain-typed primitives.** Use newtype/branded types for ids, emails, currency, paths, hashes, durations. Raw `string`/`int` is a smell at module boundaries.
3. **`Result<T, E>` for fallible operations. `Option<T>` for absence.** Never `throw`. Never `null` or `undefined` as a sentinel. Never a magic sentinel value (`-1`, `""`).
4. **Discriminated union for errors.** A named, exhaustive sum type. `E = NotFound | Invalid | Conflict`, not `string` and not `Error`.
5. **File pattern comment.** `// pattern: Functional Core` or `// pattern: Imperative Shell`. See `tk-house-style:nearly-pure-functional`.
6. **Unimplemented body.** Language-native marker only. No partial implementation.

## Contract Docstring Template

Every stub gets a docstring with: purpose (1 line), input invariants, output, error variants, purity tag, one example.

### TypeScript

```typescript
// pattern: Functional Core

/**
 * Compute the price of a cart after applying a coupon.
 *
 * Inputs:
 *   - cart: non-empty; every line item has quantity >= 1.
 *   - coupon: validated upstream via parseCoupon.
 * Output: total price as Money (non-negative).
 * Errors:
 *   - CouponExpired: coupon.expiresAt < now (now passed in, not read).
 *   - CouponNotApplicable: cart subtotal below coupon.minSubtotal.
 * Purity: PURE
 * Example:
 *   priceCart(cart, coupon, now) // -> Ok(Money(42.00))
 */
export function priceCart(
  cart: Cart,
  coupon: Coupon,
  now: Instant,
): Result<Money, PriceError> {
  throw new Error("not implemented");
}
```

### Python

```python
# pattern: Functional Core

def price_cart(cart: Cart, coupon: Coupon, now: Instant) -> Result[Money, PriceError]:
    """Compute the price of a cart after applying a coupon.

    Inputs:
      cart: non-empty; every line item has quantity >= 1.
      coupon: validated upstream via parse_coupon.
    Output: total price as Money (non-negative).
    Errors:
      CouponExpired: coupon.expires_at < now (now passed in, not read).
      CouponNotApplicable: cart subtotal below coupon.min_subtotal.
    Purity: PURE
    Example:
      price_cart(cart, coupon, now)  # -> Ok(Money("42.00"))
    """
    raise NotImplementedError
```

### Rust

```rust
// pattern: Functional Core

/// Compute the price of a cart after applying a coupon.
///
/// Inputs:
///   - `cart`: non-empty; every line item has quantity >= 1.
///   - `coupon`: validated upstream via `parse_coupon`.
/// Output: total price as `Money` (non-negative).
/// Errors:
///   - `PriceError::CouponExpired` when `coupon.expires_at < now`.
///   - `PriceError::CouponNotApplicable` when subtotal < `coupon.min_subtotal`.
/// Purity: PURE
/// Example:
///   price_cart(&cart, &coupon, now) // -> Ok(Money::from_minor(4200))
pub fn price_cart(cart: &Cart, coupon: &Coupon, now: Instant) -> Result<Money, PriceError> {
    unimplemented!()
}
```

## Smart Constructor Pattern (Parse, Don't Validate)

Every external input gets a `parse` stub returning `Result<Domain, ParseError>`. Internal code receives the domain type and trusts it. The raw primitive does NOT cross the boundary.

```typescript
// pattern: Functional Core

/**
 * Parse a raw string into an Email. Lowercases and trims.
 * Errors:
 *   - InvalidFormat: missing '@' or empty local/domain part.
 * Purity: PURE
 * Example: parseEmail("Foo@Bar.com") // -> Ok(Email("foo@bar.com"))
 */
export function parseEmail(raw: string): Result<Email, ParseError> {
  throw new Error("not implemented");
}
```

If you find yourself writing `function send(to: string)`, stop. The boundary lost the parsed type. Use `Email`, not `string`.

## Make Illegal States Unrepresentable

Prefer ADTs to flag-soup. Two booleans where a sum type belongs is a bug waiting to be written.

Bad:

```typescript
type User = {
  isAnonymous: boolean;
  isAdmin: boolean;     // can both be true?
  email?: string;       // present when?
};
```

Good:

```typescript
type User =
  | { kind: "anonymous"; sessionId: SessionId }
  | { kind: "member"; email: Email }
  | { kind: "admin"; email: Email; scopes: ReadonlyArray<Scope> };
```

The compiler now refuses the impossible state. Tests do not need to assert it cannot happen.

## Common Mistakes

| Excuse / Thought | Reality | What To Do |
|------------------|---------|------------|
| "I'll implement just the trivial path now" | Then it is not a stub, it is a half-body. Tests will be written against your half-body, not the contract. | Replace body with the unimplemented marker. Move logic to the body phase. |
| "Tests can come later, after the body" | The whole RPSTIE workflow inverts that. Tests are next. They drive the body. | Stop. Hand off to `test-author`. |
| "The shape is unknown so I'll use `any`" | `any` defeats the typechecker, which is the only reason to write stubs first. | Define an ADT for the unknown shape. Add a `parse` smart constructor. The body decides how to populate it. |
| "Returning `null` is simpler than `Option`" | `null` punishes every caller for one author's convenience. | Return `Option<T>`. Callers pattern-match. |
| "I will throw on error and document it in the docstring" | Documented exceptions are still unchecked at the call site. | Return `Result<T, E>` with a discriminated `E`. |
| "It is just a string for now" | Stringly-typed APIs leak across the codebase faster than any other smell. | Brand it. `type Email = string & { readonly __brand: "Email" }`. |

## Red Flags - STOP and Refactor

- Writing any logic in a stub body beyond the unimplemented marker.
- Using `throw` (outside the unimplemented marker), `null`, `undefined` as sentinel, or `panic!` in a contract.
- A function that returns `T` but can fail. (It must return `Result<T, E>`.)
- A function whose error type is `Error`, `string`, `Exception`, or `Box<dyn Error>`. Name the variants.
- Two booleans that cannot both be true. Make it a sum type.
- A parameter typed `string` that the docstring describes as "an email" / "a path" / "a uuid". Brand it.
- `any` or unannotated `unknown` anywhere in a signature.
- Stubs for functions the task spec does not name.

If you catch any of the above: stop, refactor the stub, re-run the typechecker.

## Verification Before Commit

The typecheck gate is non-negotiable.

- TypeScript: `tsc --noEmit` exits 0.
- Python: `mypy --strict <paths>` exits 0.
- Rust: `cargo check` exits 0.

If the typechecker fails, the contract is wrong. Common causes:

- Missing import for a domain type.
- A `Result<T, E>` whose `E` is not exported.
- A discriminated union missing a variant the docstring promises.
- A smart constructor whose return type does not match its callers.

Fix the types. Do not commit broken stubs. Do not weaken types to silence the checker. See `tk-rpie:verification-before-completion` for the broader gate.

## Exit Criteria

Before handing off to `test-author`, confirm every item:

- [ ] Every function named in the task spec has a stub. No extras.
- [ ] Every signature is fully typed. No `any`. No bare `unknown` without justification.
- [ ] Domain primitives are branded; raw `string`/`number` does not cross module boundaries.
- [ ] Fallible functions return `Result<T, E>` with a named, exhaustive `E`.
- [ ] Optional values use `Option<T>`. No `null`/`undefined` as sentinel.
- [ ] Every external input has a `parse` smart constructor stub.
- [ ] Every new source file has a `// pattern: ...` comment (or is exempt).
- [ ] Every body is the language-native unimplemented marker. Nothing more.
- [ ] Typechecker passes.
- [ ] One commit, message `stubs: <task description>`.
- [ ] Report returned with file paths, signatures, contract decisions, commit SHA.

If any box is unchecked, you are not done.

## Remember

The contract is the artifact. The body is a detail that two agents from now will fill in. Spend your time on types and error variants, not on cleverness. A boring, exhaustive stub is the goal.
