# Typestate Builder

Sub-page of `tactical-patterns/SKILL.md`. Loaded on demand. No frontmatter.

The one builder pattern that survives FP, because it provides a guarantee a record literal cannot: required-fields-set checked at compile time. Native in Rust; achievable in TypeScript with branded markers; impractical in Python.

## When to Reach for It

ALL of:

1. The constructed type has >=3 required fields AND >=2 optional fields.
2. There are inter-field invariants (e.g., "if `tls` is set, `cert` and `key` must both be set").
3. Wrong construction at runtime is a real failure mode (config errors at startup, etc.).

Otherwise, use a record literal with smart constructor returning `Result`. Cheaper.

## Rust Worked Example

Building an HTTP client where `host` is required and `port` defaults to 443 if `tls` is on:

```rust
use std::marker::PhantomData;

pub struct Set;
pub struct Unset;

pub struct ClientBuilder<HostState> {
    host: Option<String>,
    port: Option<u16>,
    tls: bool,
    timeout_ms: u64,
    _host: PhantomData<HostState>,
}

impl ClientBuilder<Unset> {
    pub fn new() -> Self {
        Self {
            host: None,
            port: None,
            tls: false,
            timeout_ms: 30_000,
            _host: PhantomData,
        }
    }

    pub fn host(self, h: impl Into<String>) -> ClientBuilder<Set> {
        ClientBuilder {
            host: Some(h.into()),
            port: self.port,
            tls: self.tls,
            timeout_ms: self.timeout_ms,
            _host: PhantomData,
        }
    }
}

impl<S> ClientBuilder<S> {
    pub fn port(mut self, p: u16) -> Self { self.port = Some(p); self }
    pub fn tls(mut self) -> Self { self.tls = true; self }
    pub fn timeout_ms(mut self, ms: u64) -> Self { self.timeout_ms = ms; self }
}

impl ClientBuilder<Set> {
    pub fn build(self) -> Client {
        let port = self.port.unwrap_or(if self.tls { 443 } else { 80 });
        Client {
            host: self.host.expect("host: Set state proves Some"),
            port,
            tls: self.tls,
            timeout_ms: self.timeout_ms,
        }
    }
}
```

Usage:

```rust
let c = ClientBuilder::new().host("example.com").tls().build();
// ClientBuilder::new().tls().build();    // does not compile: build() requires Set
```

`build` exists only on `ClientBuilder<Set>`. The compiler refuses construction without `host`.

## TypeScript Worked Example (Branded)

```typescript
type Set = { readonly _host: "set" };
type Unset = { readonly _host: "unset" };

class ClientBuilder<S> {
  private constructor(
    private host: string | undefined,
    private port: number | undefined,
    private tls: boolean,
    private timeoutMs: number,
    private _phantom: S,
  ) {}

  static start(): ClientBuilder<Unset> {
    return new ClientBuilder(undefined, undefined, false, 30_000, { _host: "unset" });
  }

  setHost(h: string): ClientBuilder<Set> {
    return new ClientBuilder(h, this.port, this.tls, this.timeoutMs, { _host: "set" });
  }

  setPort(p: number): ClientBuilder<S> { /* return new with port set */ }
  setTls(): ClientBuilder<S>           { /* return new with tls=true */ }
}

// Build only on Set
function build(b: ClientBuilder<Set>): Client { /* ... */ }

// build(ClientBuilder.start().setTls());  // type error: not Set
build(ClientBuilder.start().setHost("example.com").setTls());
```

Less ergonomic than Rust because the phantom is structural, not nominal. Reach for it only when the invariant matters.

## Anti-Patterns

- **Typestate for a 3-field record.** Use a record literal. The compiler already checks required fields.
- **Typestate for runtime-validated invariants** (length, range, format). That is a smart constructor returning `Result`, not a typestate.
- **Multi-state typestate proliferation.** If you need >=4 phantom states, the type is doing too much. Split it.
- **Typestate without a `build` step.** The whole point is that `build` is only callable in the final state. If you do not have a single terminal call, this is the wrong pattern.
- **Translating Rust typestate to Python.** Python lacks the type-system support; you get noise without enforcement. Use a smart constructor.

## When NOT to Reach for It

- Python: no static enforcement; the typestate is fiction. Use smart constructor.
- TypeScript with optional fields and no inter-field invariants: a `Partial<Config>` plus runtime parser is simpler.
- Rust struct with all fields required: just take all fields in `new`.
- Test fixtures: builders for tests should be cheap. Typestate adds friction.

## See Also

- `SKILL.md` - the dissolution table and where typestate builder sits in it
- `../nearly-pure-functional/modeling-deep.md` - phantom-type and typestate fundamentals
- `../nearly-pure-functional/rust.md` - Rust idioms for newtype and phantom data
