# Laws and Reasoning

Sub-page of `nearly-pure-functional/SKILL.md`. Loaded on demand. No frontmatter.

Names the laws the FP primitives obey. Reviewer cites a law when an instance is broken. Reminder, not tutorial.

## Equational Reasoning

If `f` is pure, every call site `f(x)` may be replaced by its return value without changing program behavior. The whole point of purity. Enables refactor-without-fear, memoization, parallel execution, property tests.

If a refactor that should be a no-op changes behavior, purity was a lie. Find the side effect.

## Algebraic Laws (vocabulary)

- **Identity.** `concat([], xs) == xs`, `compose(id, f) == f`.
- **Associativity.** `(a + b) + c == a + (b + c)`. Folds depend on it.
- **Commutativity.** `a + b == b + a`. NOT every operation has it.
- **Distributivity.** `a * (b + c) == a*b + a*c`.
- **Idempotence.** `f(f(x)) == f(x)`. Useful at boundaries.

Reviewer names the broken law in the punch list. ("This `merge` violates associativity on overlapping keys.")

## Parametricity

A function whose type variable appears only in input and output positions cannot inspect the variable's value:

```
function first<A>(xs: ReadonlyArray<A>): Option<A>
```

`first` cannot depend on what `A` is. The type guarantees this. When reviewer sees a generic function casting its type variable (`as any`, `as unknown`), parametricity is broken. Flag it.

## Memoization

Sound IFF the function is pure. `memoize(impureFn)` is a bug factory. Most useful payoff of purity in hot paths.

## Reviewer Checklist

When a refactor touches a function with a known law:

1. Name the law.
2. Find or write a property test asserting it.
3. Run the test against old and new impl on shared inputs.
4. Disagree => unsound refactor. Reject.

## See Also

- `../property-based-testing/SKILL.md` - how to write the property tests
- `modeling-deep.md` - phantom and witness types as proofs
