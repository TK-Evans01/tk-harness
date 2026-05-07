# Caller-Perspective Exercise

Sub-page of `api-ergonomics/SKILL.md`. Loaded on demand. No frontmatter.

The caller-perspective comment is the load-bearing trick of this skill. This page covers how stub-author writes it well.

## What It Is

A 5-15 line block at the top of every stubs file showing how a representative caller uses the module. Real types, real names, the dominant use case. Written BEFORE any signatures.

## Why It Goes First

Writing the call site first forces the author to choose ergonomics before commitment to a signature shape. Once signatures exist, sunk-cost bias resists changing them. The caller-perspective comment reverses the order: ergonomics first, signatures fall out.

stub-author already does type-driven development (signature first, body later). This skill asks for one step earlier: call site first, signature second, body third.

## How to Write It

1. **Pick the dominant use case.** Not the edge case, not the most powerful. The thing 80% of callers will do.
2. **Write the success path.** Plain types, plain calls.
3. **Write the most likely error path.** One branch on the error ADT, showing the caller can act on it.
4. **Stop at 15 lines.** If you need more, the API is too complex; refactor.
5. **Use real names.** Not `foo`, `bar`. `cart`, `payment`, `order`.

## Worked Example

For a checkout module:

```typescript
// caller-perspective:
//
//   import { Cart, Orders } from "./checkout";
//
//   const cart = Cart.empty();
//   const updated = Cart.addItem(cart, { sku, qty: 2 });
//   if (updated.tag === "err") return reportError(updated.error);
//
//   const placed = await Orders.place(updated.value, payment);
//   switch (placed.tag) {
//     case "ok":  return showReceipt(placed.value);
//     case "err":
//       switch (placed.error.tag) {
//         case "out-of-stock": return suggestAlternatives(placed.error.sku);
//         case "payment-declined": return promptDifferentCard();
//         case "cart-empty": return redirectHome();
//       }
//   }
//
```

Reading this comment, a new caller knows:

- `Cart.empty()` exists and returns a `Cart`.
- `addItem` returns a `Result`, not a thrown exception.
- `Orders.place` is async and returns a `Result` with a structured error.
- Every error case is actionable.

That is the contract. Stubs fall out of it; bodies fill the stubs; reviewer checks they all agree.

## Drift Check (Reviewer Step 3c)

The reviewer compares the caller-perspective comment to the actual exported surface and flags drift:

- Function called in the example does not exist in exports.
- Function exists with a different signature.
- Error variant in the example is not in the exported error type.
- Comment shows three steps but the API requires five.
- Comment uses a name (`Orders.place`) but exports use a different name (`placeOrder`).

Any drift => Important issue. Stale comments rot fast; hold the line.

## When to Update

- stub-author updates the comment as part of writing stubs.
- body-implementor MUST NOT modify the comment (it is part of the frozen stubs contract).
- bug-fixer MAY update the comment if a fix changes the caller-visible API; the change is itself a punch-list item to be reviewed.
- librarian copies the final comment into module-level documentation when the implementation is green.

## Anti-Patterns

- **Trivial example.** "const x = foo();" tells the reader nothing.
- **Edge-case example.** Showing the rare path obscures the common path.
- **Error-free example.** Real callers handle errors; show one.
- **Pseudo-code.** Use real syntax that would compile against the stubs.
- **Imports omitted.** Show where things come from.
- **Five examples.** One. The dominant use case.

## See Also

- `SKILL.md` - the mandatory comment requirement and the five-question checklist
- `_examples.md` - before/after for each red flag
- `../../tk-rpie/skills/writing-stubs-and-docs/SKILL.md` - where stub-author runs this exercise
