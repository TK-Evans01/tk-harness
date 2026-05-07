---
name: writing-tests-against-stubs
description: Use when writing tests against frozen stubs in the rpie three-phase flow (stub-author -> test-author -> body-implementor) - tests must fail with the unimplemented marker, never with ImportError or collection errors, and must cover every acceptance criterion from the design doc.
user-invocable: false
---

# Writing Tests Against Stubs

## Overview

In the rpie flow, stubs land first. Signatures and contract docstrings are frozen on disk and committed. You write tests that pin down the contract those docstrings describe. You run them. They MUST fail with the language's "unimplemented" marker - not with an import error, not with a collection error, not with a type error. Then you commit. The next agent (body-implementor) turns red into green.

**Core principle:** the failure mode of your test on first run is your only proof the test actually runs. If it does not exhibit the unimplemented marker, the test never tested anything.

## Why This Order

Tests written before bodies cannot be biased by implementation details. The reviewer's diff at phase review shows the contract first, then the body that satisfies it; contract drift is visible.

It is impossible to "accidentally pass" against an unimplemented stub if your test actually calls the function. If a test passes here, either the stub leaked logic (stub-author bug, stop and report) or the test never called the function (your bug, fix the test).

This is the literal "see red first" of TDD. The test-driven-development skill covers the cycle in general; this skill covers the specific failure-mode discipline of phase 2.

## See Red First - Mandatory Verification

Run every test you write. Look at every failure line. The marker MUST come from the stub body.

### Right Failure Modes

**Python (Hypothesis / pytest):**

```python
# stub
def normalize_email(raw: str) -> Result[Email, EmailError]:
    """Lowercases, strips whitespace. Errors: Empty, NoAtSign."""
    raise NotImplementedError

# pytest output - GOOD
FAILED tests/test_email.py::test_normalize_lowercases_domain
    raise NotImplementedError
E   NotImplementedError
```

**Rust (proptest / cargo test):**

```rust
// stub
pub fn normalize_email(raw: &str) -> Result<Email, EmailError> {
    unimplemented!("normalize_email")
}

// cargo test output - GOOD
thread 'tests::normalize_lowercases_domain' panicked at 'not implemented: normalize_email'
```

**TypeScript (fast-check / vitest):**

```typescript
// stub
export function normalizeEmail(raw: string): Result<Email, EmailError> {
  throw new Error("not implemented");
}

// vitest output - GOOD
FAIL  tests/email.test.ts > normalize lowercases domain
Error: not implemented
```

### Wrong Failure Modes - STOP

If you see any of these, do not commit. Investigate first.

**Python:**
- `ImportError` / `ModuleNotFoundError` - import path wrong, or stub file is malformed.
- `collection error` from pytest - syntax error in test or test file fails to import.
- `fixture failed` - your fixture raised before the function ran.
- `TypeError: missing argument` - your test call shape does not match the signature.

**Rust:**
- `error[E0XXX]` from rustc - test does not compile. Test never ran.
- `unresolved import` - module path wrong.

**TypeScript:**
- `TS2304: Cannot find name` / `TS2307: Cannot find module` - test does not type-check.
- `SyntaxError` from the test runner - parse error in test file.

In all wrong-mode cases: STOP. Diagnose. Likely root cause is a malformed stub or a wrong import path in your test. If the stub itself is wrong, report it back; do not patch it (signatures are frozen at this stage).

### Worked Example - Right and Wrong Side By Side

```python
# stub: src/foo.py
def add(a: int, b: int) -> int:
    """Returns a + b."""
    raise NotImplementedError

# WRONG test - passes silently because we never called add
def test_add_commutes():
    assert True  # tautology, never exercises the contract

# WRONG test - fails with ImportError, never ran
from src.fooo import add  # typo
def test_add_commutes():
    assert add(1, 2) == add(2, 1)

# RIGHT test - fails with NotImplementedError on first run
from src.foo import add
def test_add_commutes():
    assert add(1, 2) == add(2, 1)
```

Only the third entry exhibits the marker. That is the only one you commit.

## AC Coverage Rule

Every acceptance criterion in the design doc that is in scope for this task maps to at least one named test that would fail if the AC were violated. No exceptions.

Write the coverage map either as a comment at the top of the test file or as `<task-slug>-coverage.md` next to the tests:

```markdown
# Coverage map - normalize-email task

| AC ID            | Test name(s)                                   |
|------------------|-----------------------------------------------|
| email.AC1        | test_normalize_lowercases_domain              |
| email.AC2        | test_normalize_strips_surrounding_whitespace  |
| email.AC3        | test_normalize_rejects_empty_with_Empty       |
| email.AC4        | test_normalize_rejects_missing_at_with_NoAtSign |
```

Reviewer checks this table at phase review. Missing rows = missing tests = phase fails.

## Test the Contract, Not the Implementation

GOOD: assert that input X yields output Y per the docstring.

BAD: assert that an internal helper was called with arg Z.

BAD: assert on the shape of an internal data structure.

**Self-review prompt:** "If body-implementor wrote a different correct implementation, would my test still pass?" If no, rewrite it. The test belongs to the contract, not to one particular body.

```python
# BAD - couples test to implementation
def test_normalize_calls_lowercase_helper(mocker):
    spy = mocker.spy(email_module, "_lowercase")
    normalize_email("Foo@Bar.Com")
    spy.assert_called_once()

# GOOD - tests the contract from the docstring
def test_normalize_lowercases_domain():
    result = normalize_email("Foo@Bar.Com")
    assert result.unwrap().value == "foo@bar.com"
```

## Property-Based Testing for Pure Functions

Mandatory in Tier 2 for pure logic. Minimum 1 property per pure function; prefer 2-3.

Reach for universal properties before bespoke ones:

| Property      | Formula                  |
|---------------|--------------------------|
| Idempotence   | `f(f(x)) == f(x)`        |
| Commutativity | `f(a, b) == f(b, a)`     |
| Associativity | `f(f(a,b), c) == f(a, f(b,c))` |
| Identity      | `f(x, e) == x`           |
| Roundtrip     | `decode(encode(x)) == x` |

"No exception on valid input" is too weak by itself. See `tk-house-style:property-based-testing` for the full catalog and quality gates.

### Worked Examples

**Python (Hypothesis):**

```python
from hypothesis import given, strategies as st
from src.text import normalize

@given(st.text(max_size=200))
def test_normalize_is_idempotent(s):
    assert normalize(normalize(s)) == normalize(s)
```

**TypeScript (fast-check):**

```typescript
import fc from "fast-check";
import { normalize } from "../src/text";

test("normalize is idempotent", () => {
  fc.assert(fc.property(fc.string({ maxLength: 200 }), (s) => {
    expect(normalize(normalize(s))).toBe(normalize(s));
  }));
});
```

**Rust (proptest):**

```rust
use proptest::prelude::*;
use crate::text::normalize;

proptest! {
    #[test]
    fn normalize_is_idempotent(s in "\\PC{0,200}") {
        prop_assert_eq!(normalize(&normalize(&s)), normalize(&s));
    }
}
```

All three fail with their respective unimplemented markers on first run. Good.

## Result and Option Testing Patterns

For `Result<T, E>`: one test per `Ok` shape and one test per enumerated `E` variant. If the docstring lists `Empty | NoAtSign | TooLong`, you write three error-variant tests. Do not collapse them into "errors on bad input".

```python
def test_normalize_returns_Empty_on_empty_string():
    assert normalize_email("").unwrap_err() == EmailError.Empty

def test_normalize_returns_NoAtSign_when_missing_at():
    assert normalize_email("foo.example.com").unwrap_err() == EmailError.NoAtSign
```

For `Option<T>`: a `Some` test and a `None` test. The absence case is not optional.

## Mocking Discipline

- Never mock pure functions. Just call them.
- Mock at I/O boundaries only (HTTP, disk, clock).
- Prefer fakes (in-memory implementations of an interface) over mocks (call-recording shells). Fakes survive refactors; mocks bind your test to a particular call sequence.
- If your mock setup is longer than the test logic, you are testing the mock. See `tk-house-style:writing-good-tests` "Mocking Strategy".

## Common Mistakes

| Mistake                                              | What it really means                              |
|------------------------------------------------------|---------------------------------------------------|
| A test passes against an unimplemented stub         | Test never called the function, or stub leaked logic. Fix the test or report the stub. |
| `ImportError` treated as "red"                       | Test never ran. Not red. Fix the import. |
| Mocking a pure function "for speed"                  | Just call it. Pure functions are fast. |
| Single happy-path test per function                  | Need every error variant and at least one property. |
| Asserting an internal helper was called              | Couples test to implementation. Rewrite against contract. |
| Skipping property tests because "the example covers it" | Examples cover the cases you thought of. Properties cover the cases you didn't. |
| Editing the stub to "make the test fit"              | Signatures are frozen. Report; do not patch. |
| Committing with red but mixed-mode failures          | Every test must fail with the unimplemented marker. Mixed = stop. |

## Red Flags - STOP

- Any test passes on first run.
- Any test fails with `ImportError`, `ModuleNotFoundError`, collection error, syntax error, or type error.
- You are about to mock a pure function.
- You are about to assert on a private helper or internal field.
- An AC has no test in your coverage map.
- A `Result`-returning function has fewer error tests than the docstring lists variants.
- A pure function has zero property tests.
- You are about to edit a stub file.

If any of these are true, do not commit. Fix or report.

## Exit Criteria Checklist

Before returning the report:

- [ ] Every public function in scope has at least one test.
- [ ] Every AC ID maps to at least one named test in the coverage map.
- [ ] Every pure function has at least one property-based test.
- [ ] Every `Result` error variant from the docstring has a dedicated test.
- [ ] Every `Option` return has both `Some` and `None` tests.
- [ ] Every test fails on first run with the unimplemented marker.
- [ ] Zero `ImportError` / collection / syntax / type-check failures.
- [ ] No stub files modified.
- [ ] No function bodies written.
- [ ] Coverage map saved (in-file comment or sibling `.md`).
- [ ] Commit message: `tests: <task-slug> (failing vs stubs)`.

Cannot tick all boxes? You are not done. Do not commit. Report what is blocking and to whom.
