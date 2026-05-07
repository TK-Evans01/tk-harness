# Python Quick Card (Tier 2)

Concrete tooling and idioms for nearly-pure functional Python.

## Libraries

- **returns** (`Result`, `Maybe`, `IO`, `Future`) for explicit error and absence types. Plays well with mypy.
- **pydantic v2** or **msgspec** for parsers (parse-don't-validate at boundaries).
- **pyrsistent** for persistent collections when sharing matters; otherwise `tuple`, `frozenset`, `frozendict` (3.13+) suffice for small cases.
- **typing.NewType** for branded primitives.
- **dataclasses** with `frozen=True, slots=True` for product types.
- **typing.Literal** + `match` for tagged unions.

## Type-System Setup

`pyproject.toml` (mypy):

```
[tool.mypy]
strict = true
disallow_any_explicit = true
warn_return_any = true
warn_unreachable = true
```

Or pyright with `strict` mode. Either is fine; pick one per project.

`disallow_any_explicit` means a use of `Any` requires a `# type: ignore[explicit-any]` with a justification comment.

## Lint

Use **ruff** with these rule families enabled:

- `E`, `F`, `B` (bugbear) baseline
- `PLW0603` (no global statement)
- `B008` (no function call in default argument)
- `B023` (no function uses loop variable)
- `RUF012` (mutable class attributes need `ClassVar`)
- `SIM` (simplify) for comprehension preference
- `RET` (return) for total-function patterns

Plus a custom check (regex or grep) for `for` and `while` in files marked `# pattern: Functional Core`. The code-reviewer also greps these.

## Idioms

### Frozen Dataclass (Product Type)

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class Money:
    amount: int      # cents
    currency: str    # narrowed below
```

`frozen=True` rejects attribute assignment; `slots=True` rejects new attributes.

### Tagged Union via Literal + Match

```python
from typing import Literal
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class Draft:
    tag: Literal["draft"] = "draft"
    items: tuple["LineItem", ...] = ()

@dataclass(frozen=True, slots=True)
class Placed:
    placed_at: int
    items: tuple["LineItem", ...]
    tag: Literal["placed"] = "placed"

Order = Draft | Placed

def total(o: Order) -> int:
    match o:
        case Draft(items=items):     return sum_items(items)
        case Placed(items=items):    return sum_items(items)
```

mypy / pyright flag a missing case if a new variant is added.

### NewType for Domain Primitives

```python
from typing import NewType

UserId = NewType("UserId", str)
Email  = NewType("Email", str)

def lookup(uid: UserId) -> Maybe[User]: ...
```

`UserId("abc")` is the only way to construct one; passing a raw `str` is a type error.

### Smart Constructor returning Result

```python
from returns.result import Result, Success, Failure
import re

EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")

def parse_email(raw: str) -> Result[Email, ParseError]:
    if EMAIL_RE.match(raw):
        return Success(Email(raw))
    return Failure(ParseError(field="email", value=raw))
```

The `Email(raw)` cast is contained inside the parser. Downstream code receives `Email`.

### Comprehension over for-loop

```python
# Tier 2: comprehension or higher-order
totals = [price(item) for item in items]
totals = list(map(price, items))
total  = sum(price(item) for item in items)

# Forbidden in core:
total = 0
for item in items:
    total += price(item)
```

### Maybe replaces None Returns

```python
from returns.maybe import Maybe, Nothing, Some

def find_user(uid: UserId, users: tuple[User, ...]) -> Maybe[User]:
    for u in users:                  # iteration to find one is fine if the result is not the loop accumulator
        if u.id == uid:
            return Some(u)
    return Nothing
```

(For pure-functional purists: `next((Some(u) for u in users if u.id == uid), Nothing)`. Either is acceptable; the return type is the contract.)

## The Stub Marker

Stubs use:

```python
raise NotImplementedError
```

This is the single permitted `raise` in core code. It exists only between stub-author and body-implementor. After body-implementor, no `raise` should remain in core; errors flow through `Result`.

## Anti-Patterns

| Anti-pattern                              | Why it's wrong                              | Replace with                                  |
|-------------------------------------------|---------------------------------------------|-----------------------------------------------|
| `except` in core                          | Catches and hides; breaks Result flow       | Return `Result[T, E]`                          |
| Bare `except:` anywhere                   | Catches `KeyboardInterrupt`, `SystemExit`   | Catch the specific class at the shell         |
| Mutable default argument (`def f(x=[])`)  | Shared across calls                         | `def f(x: tuple[int, ...] = ()) -> ...`       |
| Mutating function arguments               | Aliasing bugs                               | Return a new value                            |
| `global` in core                          | Hidden state                                | Pass dependencies as parameters               |
| `Any` without justification               | Disables type checking                      | Parse to a domain type at the boundary        |
| `class Foo:` with mutable instance fields | Logic-as-state                              | `@dataclass(frozen=True)` + module functions  |
| `datetime.now()` in core                  | Non-deterministic                           | Inject `now: int` (epoch ms) parameter        |
| `random.random()` in core                 | Non-deterministic                           | Inject a `Random` instance or sample value    |

## Tier 3 Note

If the project opts up to Tier 3, `Result[T, E]` becomes `IOResult[T, E]` and dependencies move into a `RequiresContext`. See `tier-3.md`. Most Python projects stay at Tier 2.
