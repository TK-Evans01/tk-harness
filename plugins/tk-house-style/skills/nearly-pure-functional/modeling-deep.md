# Modeling Deep

Sub-page of `nearly-pure-functional/SKILL.md`. Loaded on demand. No frontmatter.

Three type-level techniques that push more invariants into the compiler. Reminder, not tutorial.

## Phantom / Branded Type

A type marker that exists only to distinguish otherwise-identical representations.

```typescript
type Branded<T, Tag> = T & { readonly __tag: Tag };
type Email = Branded<string, "Email">;
type UserId = Branded<string, "UserId">;
```

Same runtime value, distinct compile-time types. Mixing fails to compile. Constructed only by parser; possession is proof of validation.

**Use when:** domain primitives share a representation but must not mix.

A "witness" is just a phantom-tagged value: `SortedVec<T>`, `Validated<Order>`, `Authenticated<Request>`. Pass the witness, not a boolean.

## Refinement Type

Newtype around a primitive whose smart constructor enforces a runtime predicate.

```typescript
type PositiveInt = Branded<number, "PositiveInt">;

function parsePositiveInt(n: number): Result<PositiveInt, ParseError> {
  if (Number.isInteger(n) && n > 0) return ok(n as PositiveInt);
  return err({ tag: "not-positive-int", got: n });
}
```

Possession of a `PositiveInt` is the proof. Downstream code never re-checks.

**Use when:** you would otherwise write the same validation guard at every call site.

## Typestate

Encode the state of an object in its type so the compiler refuses invalid transitions. Native in Rust; achievable in TS with branded markers; impractical in Python.

```rust
struct Conn<S> { _s: PhantomData<S>, sock: TcpStream }
struct Disconnected;
struct Connected;

impl Conn<Disconnected> { fn connect(self) -> Result<Conn<Connected>, IoErr> { ... } }
impl Conn<Connected>    { fn send(&self, data: &[u8]) -> Result<(), IoErr> { ... } }
```

`send` cannot compile against `Conn<Disconnected>`. No runtime guard, no "is connected?" boolean.

**Use when:** an object has a small set of states with rules about which methods are valid in which state.

See `../tactical-patterns/typestate-builder.md` for the builder variant.

## Reviewer Checklist

- Domain primitive (Email, UserId, OrderNumber) typed as raw `string` -> flag.
- Boolean flags carrying state semantics (`isAdmin`, `isLoggedIn`) on a wide record -> flag, suggest typestate or role ADT.
- "Validated" / "sorted" / "authenticated" passed as boolean alongside the value -> flag, suggest witness (phantom tag).
- Pattern match without exhaustiveness check -> flag, require compiler-enforced exhaustiveness.

## See Also

- `SKILL.md` section 4 - illegal-states-unrepresentable basics
- `typescript.md`, `rust.md` - language idioms for branding and phantom types
