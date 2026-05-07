---
name: writing-bodies-against-tests
description: Use when implementing function bodies against frozen stubs and frozen failing tests - turns red tests green one function at a time without modifying signatures or tests.
user-invocable: false
---

# Writing Bodies Against Tests

## Overview

Bodies turn red tests green. Signatures are frozen. Tests are frozen. You write
one function, run its tests, watch them go green, move on.

This is the third leg of the per-task chain:

```
stub-author    -> stubs + contracts (frozen commit)
test-author    -> failing tests     (frozen commit)
body-implementor -> bodies          (this skill)
```

The contract chain only works if the freeze holds. Touching tests or signatures
silently breaks the chain and turns this into ad-hoc coding.

## Why One Function At A Time

The whole point of having stubs and tests pre-committed is that each body is
its own minimal feedback loop:

- Last change is always the suspect. If you wrote one body and one body's tests
  went red, the bug is in that body or in your reading of its contract. Period.
- Per-function test runs are seconds. Whole-suite runs are minutes and hide
  which change broke what.
- Writing five bodies then debugging five interleaved failures is big-bang
  integration debugging. Avoid it.

If you find yourself thinking "I'll batch the easy ones and run tests once at
the end", stop. That is the failure mode this skill exists to prevent.

## The Signature / Test Freeze

Stubs and tests sit at frozen commits. The dispatch passed you those SHAs on
purpose. Treat them as read-only contracts.

### If a test seems wrong

Do not edit it. Possible reasons it might look wrong:

- The contract is more subtle than you read on first pass. Re-read the stub
  docstring and the design doc.
- The test is correct and your mental model of the function is wrong.
- The test is genuinely buggy.

Only the third case is a real test bug, and you cannot fix it from this seat.
STOP, write a BLOCKED report at `.tk-harness/blocked/<phase-id>-<UTC-timestamp>.md` describing the suspected bug, and escalate.

### If a signature seems wrong

Same answer. Re-stubbing is stub-author's responsibility. If the signature is
genuinely impossible to implement correctly, STOP and escalate. Do not widen
the type, do not add an extra parameter, do not change the return shape.

### "Maybe the test is just flaky"

Per-task tests are deterministic by contract. If they are flaky, that is a test
design bug, not a reason to retry until green. Escalate.

## Per-Function Implementation Rhythm

For each function the task assigns you:

1. Re-read the stub signature and docstring.
2. Re-read every test that targets this function. Read in full; do not skim.
3. Write the minimum body that honors the contract.
4. Run THIS function's tests, narrowly. Examples:
   - `pytest path::test_name -x`
   - `vitest run -t "test name"`
   - `cargo test module::test_name`
5. Green -> next function.
6. Red -> read the failure message and stack. One quick retry if the cause is
   obviously a typo or off-by-one.
7. Still red -> invoke tk-rpie:systematic-debugging and follow its phases.
8. Three attempts max per function. After three, STOP and write `.tk-harness/blocked/<phase-id>-<UTC-timestamp>.md`.

The minimum-body rule matters. Do not generalize beyond the test. If the test
asks for `add(2, 3) == 5`, a body that handles negative numbers, floats, and
big integers is doing test-author's job for them. Implement what the contract
says, no more.

## Tier-2 FP Discipline Reminders

The fp-primitives-active block at the top of your dispatch is binding. Tier 2
is the default. Concretely:

- Prefer a pipeline of pure transformations over imperative loops. `map` /
  `filter` / `fold` / `reduce` over `for` / `while` where natural.
- Thread `Result<T, E>` and `Option<T>` through combinators. `andThen` /
  `.and_then` / `pipe(E.chain ...)`. No exception flow in core.
- Pattern matching is exhaustive. No silent default branches; no ad-hoc null
  checks where a discriminated union is in scope.
- Effects (I/O, time, randomness) live in the imperative shell. Do not
  introduce `Date.now()`, `fs.readFile`, `console.log`, `random()`, or network
  calls inside core modules.
- `Readonly<>` / `readonly` / immutable collections in TS. No mutation of
  inputs. In Rust, no interior mutability without justification. In Python,
  treat dataclasses as frozen unless the stub says otherwise.
- No `any` / `unknown` / `// @ts-ignore` / `# type: ignore` without a written
  justification in a comment.

If the test seems to require violating Tier 2, that is a freeze-layer
disagreement. Escalate; do not silently downgrade.

## Refactor-As-You-Go Is Out Of Scope

Body-implementor implements the contract. That is the whole job.

Out of scope:

- Renaming variables in sibling files
- "Improving" code in modules you happened to read
- Adding helpful error messages to functions you did not touch
- Reformatting files
- Updating dependencies
- Adding logging

If you see something worth fixing, leave it. The reviewer flags follow-up
work. Drive-by refactors muddy the diff and hide the actual implementation.

The only exception: a small private helper in the same file as a function you
are implementing, when the body genuinely needs it. Flag the helper in the
commit body.

## Final /verify Ritual

After every function in the task has its tests green:

1. Run /verify (or the project equivalent): typecheck, lint, arch-lint, purity,
   full test suite.
2. If everything is green, commit "impl: <task-id> <title>" and report.
3. If something is red, fix in priority order:
   - Critical: typecheck, full test suite
   - Important: arch-lint, purity, lint errors
   - Minor: lint warnings the project treats as errors
4. One fix at a time. Re-run /verify between fixes.
5. If three /verify attempts in a row leave a check red, invoke
   tk-rpie:systematic-debugging.

Never commit with /verify red. Never silence a check (no `// eslint-disable`,
no `# noqa`, no `#[allow(...)]`) just to ship.

## Common Mistakes

| Mistake                                          | Why it's wrong                                                                 |
|--------------------------------------------------|--------------------------------------------------------------------------------|
| Batch all bodies, run tests once at the end      | Loses the per-function feedback loop; turns it into big-bang debugging        |
| Skip a "minor" lint warning                      | Tier 2 is strict; the warning fails /verify; fix it                            |
| Tweak the test to match what the body does       | Breaks the freeze; silently rewrites the contract; escalate instead            |
| Loosen a stub signature to make a body easier    | Re-stubbing is stub-author's job; escalate                                     |
| Add a public helper in a sibling file            | Expands the public surface beyond the stub; only private same-file helpers OK  |
| Generalize past the tests ("might as well")      | Out of scope; reviewer flags follow-up; minimum body that honors contract     |
| Reformat or rename in passing                    | Out of scope; muddies the diff                                                 |
| `xfail` / `skip` a stubborn test                 | Suppresses the failure instead of fixing or escalating                         |
| Try fix #4 after three failed attempts           | Architectural / contract problem; STOP and write `.tk-harness/blocked/<phase-id>-<UTC-timestamp>.md` |

## Red Flags - STOP

If you catch yourself thinking any of these, stop and reset:

- "I'll just edit the test slightly so it matches."
- "The signature is almost right; I'll add one optional parameter."
- "Let me write all five bodies and then run the suite."
- "This warning is harmless; I'll silence it."
- "While I'm here, let me clean up this other file."
- "One more fix attempt" (after three failures on the same function).
- "It's probably flaky; I'll just rerun it."
- "I'll add `any` here, it's only one spot."

Each of these is a freeze break, a scope expansion, or a debugging shortcut.
None are acceptable.

## When To Write a BLOCKED Report

Write the BLOCKED report at `.tk-harness/blocked/<phase-id>-<UTC-timestamp>.md`
(timestamp format `YYYYMMDDTHHMMSSZ`, e.g. `20260506T143022Z`; create the
directory if missing) and stop coding when:

- Three attempts on the same function have failed.
- A test appears genuinely wrong (after re-reading stubs and design doc).
- A stub signature appears genuinely wrong or impossible.
- The design as specified is infeasible given other frozen contracts.
- A required dependency, file, or upstream module is missing.

The BLOCKED report should contain:

- Task id and the specific function / test / stub at issue
- Per-attempt log: hypothesis, change, observed result
- Why you believe the freeze layer is at fault, if you do
- What input you need from the caller to unblock

Do not commit partial bodies that leave tests red. Either the task is done and
green, or it is BLOCKED and unchanged.

## Exit Criteria Checklist

Before reporting success:

- [ ] Every function listed in the task has a body
- [ ] Each function's tests went red -> green
- [ ] No test files were modified
- [ ] No stub signatures were modified
- [ ] No new public functions were added beyond the stubs
- [ ] No skips, xfails, or suppressions added
- [ ] Tier-2 discipline held (no `any`, no `throw` in core, no mutation, no I/O
      in core)
- [ ] /verify is fully green: typecheck, lint, arch-lint, purity, tests
- [ ] Commit "impl: <task-id> <title>" exists with a body listing functions
      implemented and any non-obvious decisions
- [ ] Report includes commit SHA and per-step /verify status

If any box is unchecked, you are not done. Either finish the work or write
`.tk-harness/blocked/<phase-id>-<UTC-timestamp>.md`.
