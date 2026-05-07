# Rust Quick Card (Tier 2)

Rust's defaults already align with most of Tier 2. The discipline here is: don't reach for the escape hatches.

## Native Primitives

- `Result<T, E>` and `Option<T>` are in the prelude. Use them. Compose with `?`, `map`, `and_then`, `ok_or`.
- `enum` + `match` are exhaustive by default. The compiler refuses to build until every variant is handled.
- `&T` over `&mut T` in core. Reach for `&mut` only inside a single function's local scope when iteration ergonomics demand it.
- `struct` for products; derive `Clone`, `Debug`, `PartialEq`, `Eq` freely. Derive `Copy` for small value types.

## Crates

- **itertools** for richer iterator combinators (`fold`, `scan`, `group_by`, `chunks`).
- **im** (or **rpds**) for persistent collections when shared structural sharing is wanted; otherwise plain `Vec` / `HashMap` are fine because Rust's ownership prevents aliasing-induced mutation bugs.
- **serde** + **serde_json** / **toml** / **ron** for parsers at boundaries.
- **thiserror** for ergonomic domain error enums; **anyhow** at the shell for opaque error bubbling.
- **tokio** for async runtime when needed.

## Lints

In `Cargo.toml` or `clippy.toml`:

```
[lints.clippy]
pedantic         = "warn"
unwrap_used      = "deny"
expect_used      = "deny"
panic            = "deny"
todo             = "warn"
unimplemented    = "warn"
missing_errors_doc = "warn"
missing_panics_doc = "warn"
```

`unwrap_used`, `expect_used`, `panic` denied at the lint level is the heart of Tier 2 in Rust. They are still permitted in `main.rs`, `tests/`, and `#[cfg(test)]` modules; the lint config exempts those paths or the code uses `#[allow(...)]` per call site with a justification.

## Idioms

### Result Chain via ?

```rust
fn place_order(raw: &[u8], now: Instant) -> Result<Order, DomainError> {
    let parsed = parse_order(raw)?;
    let placed = place(parsed, now)?;
    Ok(with_audit_stamp(placed, now))
}
```

`?` does the propagation; no `try` / `catch` in sight.

### Exhaustive match on enum

```rust
enum Order {
    Draft   { items: Vec<LineItem> },
    Placed  { items: Vec<LineItem>, placed_at: Instant },
    Shipped { items: Vec<LineItem>, placed_at: Instant, tracking: TrackingId },
}

fn total(o: &Order) -> Money {
    match o {
        Order::Draft   { items, .. }
        | Order::Placed  { items, .. }
        | Order::Shipped { items, .. } => sum_items(items),
    }
}
```

Add a variant to `Order` and the `match` fails to compile.

### Newtype for Domain Primitives

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct UserId(u64);

impl UserId {
    pub fn parse(raw: u64) -> Result<Self, ParseError> {
        if raw == 0 { Err(ParseError::ZeroUserId) } else { Ok(UserId(raw)) }
    }
}
```

The inner field is private. The only way to construct a `UserId` is `parse`. Downstream functions take `UserId`, never `u64`.

### Iterator fold over for loop

```rust
// Tier 2:
let total: u64 = items.iter().map(price).sum();
let total: u64 = items.iter().fold(0, |acc, it| acc + price(it));

// Forbidden in core:
let mut total = 0u64;
for it in items.iter() {
    total += price(it);
}
```

Local mutation inside `fold`'s closure is fine: it cannot escape.

### Smart Constructor with serde + thiserror

```rust
#[derive(Debug, thiserror::Error)]
pub enum ParseError {
    #[error("invalid email: {0}")]
    InvalidEmail(String),
}

pub struct Email(String);

impl Email {
    pub fn parse(raw: &str) -> Result<Self, ParseError> {
        if EMAIL_RE.is_match(raw) {
            Ok(Email(raw.to_owned()))
        } else {
            Err(ParseError::InvalidEmail(raw.to_owned()))
        }
    }
    pub fn as_str(&self) -> &str { &self.0 }
}
```

## The Stub Marker

Stubs use `unimplemented!()` or `todo!()`. The body-implementor must replace every one before the file leaves the implementation phase. The clippy lints `clippy::unimplemented` and `clippy::todo` (warn) catch leftovers.

```rust
pub fn parse_order(raw: &[u8]) -> Result<Order, ParseError> {
    unimplemented!("stub-author wrote signature; body-implementor fills body")
}
```

## Anti-Patterns

| Anti-pattern                            | Why it's wrong                                  | Replace with                                |
|-----------------------------------------|-------------------------------------------------|---------------------------------------------|
| `.unwrap()` in core                     | Panics on `None` / `Err`; silent contract break | `?` propagation, `ok_or(err)`, `unwrap_or_else` |
| `.expect("...")` in core                | Same; the message just documents the panic     | Same as above                                |
| `panic!()` in core                      | Crashes the process                            | Return `Result<_, _>` with a domain error    |
| `RefCell` in core                       | Runtime borrow checking; hidden mutation       | Restructure ownership; pass `&mut` locally  |
| `Rc<RefCell<T>>`                        | Shared mutable state                           | Persistent collections; explicit messaging  |
| `lazy_static!` mutable                  | Global mutable state                           | Pass dependencies as parameters             |
| `Instant::now()` in core                | Non-deterministic                              | Inject `now: Instant` parameter             |
| `rand::random()` in core                | Non-deterministic                              | Inject `&mut impl Rng` parameter            |
| `static mut`                            | UB-adjacent; Tier 2 forbidden                  | Don't                                       |

## Tier 3 Note

Rust's native `async fn` + `Result` + traits already do most of what Tier 3 buys. A Rust project on Tier 3 typically just means: be deliberate about runtime choice (`tokio` vs `async-std`), use `tower` for service composition, and document `#[must_use]` on every effectful return. See `tier-3.md`.
