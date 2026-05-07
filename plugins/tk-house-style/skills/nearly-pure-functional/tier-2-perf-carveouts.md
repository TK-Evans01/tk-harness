# Tier 2 - Performance Carve-Outs

Sub-page of `nearly-pure-functional/SKILL.md`. Loaded on demand. No frontmatter.

The narrow exception that lets a hot-path function use local mutation, in-place buffer fill, or SIMD intrinsics while keeping its external contract pure. Marker-gated. Reviewer-tested. NOT a license to sprinkle mutation.

## When to Reach for This

ALL of:

1. The function is on a measured hot path. Profile first; benchmark commit attached.
2. The naive functional impl was tried and is the bottleneck.
3. The transformation is local: mutation does not escape the function frame.
4. An equivalence property test exists asserting the carve-out impl matches a naive reference impl on representative inputs.

If any of these is missing, you do not have a carve-out. You have a Tier 2 violation.

## MANDATORY: The Carve-Out Marker

Every carve-out file carries, at the top:

```
// pattern: Functional Core
// perf-carveout: <one-line reason - what is being optimized and why>
// benchmark: <commit-sha or path showing measured win>
// equivalence-test: <test path proving same I/O as naive impl>
```

All four lines required. NO EXCEPTIONS. Reviewer Step 3b greps for the marker, runs the equivalence test, reads the benchmark. Missing line => reject. Failing equivalence test => reject. Stale benchmark (older than relevant commits) => reject and ask for re-run.

## Permitted Local Techniques

- **`let mut` on local values** (Rust, JS/TS via `let`, Python via local list).
- **In-place buffer fill** for a buffer allocated in the same function and returned as immutable.
- **Transient-then-freeze** (Clojure-style): take immutable in, build mutable internally, return immutable.
- **Arena / scratch allocator** scoped to the function call.
- **SIMD intrinsics** (`std::simd`, `_mm_*`, WebAssembly SIMD).
- **Linear / affine consumption** of an owned input: in Rust, take by value and overwrite.

## Forbidden Even in Carve-Outs

- Escape of a mutable reference (return, store on `this`, send through a channel).
- Mutation through an alias whose non-escape is not proven.
- `unsafe` Rust without an explicit safety comment AND a property test covering the invariant the unsafe block depends on.
- Perf claim without a benchmark commit. "It's faster" is not a justification.
- Mutation of an input the caller still owns. Take ownership or copy first.
- Carve-out marker on a file that does not actually contain a measured optimization.
- Skipping the equivalence test "because the optimization is obvious."

## Worked Example (TypeScript)

Naive:

```typescript
// pattern: Functional Core
export function dotNaive(a: ReadonlyArray<number>, b: ReadonlyArray<number>): number {
  return a.reduce((acc, ai, i) => acc + ai * b[i], 0);
}
```

Carve-out:

```typescript
// pattern: Functional Core
// perf-carveout: tight numeric inner loop on Float64Array; reduce closure dominated profile
// benchmark: bench/dot.bench.ts at commit a1b2c3d (3.1x speedup, n=1024)
// equivalence-test: test/dot.equiv.test.ts

export function dot(a: Float64Array, b: Float64Array): number {
  let sum = 0;
  for (let i = 0; i < a.length; i++) {
    sum += a[i] * b[i];
  }
  return sum;
}
```

External signature is pure: same inputs, same output, no escape, no observable side effect. Internal `for` loop and `let` mutation are local. The marker declares the trade. The test proves the equivalence.

Equivalence test (sketch): property-test that `dot(a, b)` matches `dotNaive(a, b)` on arbitrary same-length arrays within float tolerance. See `../property-based-testing/SKILL.md` for the framework.

## Common Mistakes and Rationalizations

| Excuse | Reality | What to do |
|--------|---------|------------|
| "It's a small loop, no need for the marker" | Reviewer cannot tell carve-out from drift. | Add the marker. 4 lines. |
| "Benchmark too noisy to commit" | Then the optimization is not measured. | Stabilize benchmark or revert to naive. |
| "Equivalence test would be slow" | Cap input size; use property test with `fc.tuple(maxLength: 1024)`. | Write the test anyway. Slow tests are fine in a carve-out file. |
| "Mutation does not escape, trust me" | Aliasing bugs are silent. Hostile inputs find them. | Prove with the equivalence test on adversarial property. |
| "I will benchmark later" | Later never comes. | Benchmark first. No marker without measured win. |
| "The naive version is too slow to test against" | Test on small inputs; naive does not need to be production-fast. | Naive lives only in the test or in `*-naive.ts`. |
| "I need `unsafe` for SIMD; skip the safety comment" | `unsafe` without justification is a defect. | Comment the safety invariant. Property-test the invariant. |
| "Carve-out applies to the whole module" | Carve-out is per function, marker per file. | Split: hot-path file (carve-out) + cold-path file (Tier 2 strict). |

## Red Flags - STOP

- Mutation of an argument the caller still holds.
- Mutable reference returned from a carve-out function.
- `unsafe` block without a safety comment AND a covering property test.
- Carve-out file with no equivalence test path on the marker.
- Carve-out file where the equivalence test was last run before the impl changed.
- Carve-out marker on code that is not on a measured hot path.

## Reviewer Step 3b (the check)

```
1. grep for `perf-carveout:` in changed files
2. for each match:
   a. assert all four marker lines present
   b. resolve the equivalence-test path; verify it exists
   c. run the equivalence test; assert green
   d. resolve the benchmark path; assert benchmark commit referenced is reachable
3. flag any failure as Critical
```

## See Also

- `SKILL.md` section 2 - the forbidden list and the carve-out exception block
- `../property-based-testing/SKILL.md` - how to write the equivalence property
- `tier-2.md` - the rules the carve-out is an exception to
