# API Ergonomics - Worked Examples

Sub-page of `api-ergonomics/SKILL.md`. Loaded on demand. No frontmatter.

Four before/afters. The dominant red flags. Other anti-vocab in the anchor follows the same shape.

## 1. Stringly-Typed -> Branded Domain Type

BEFORE:

```typescript
function transfer(fromUser: string, toUser: string, amount: string): Promise<string>;

await transfer(orderId, userId, "ten dollars"); // caller swapped args; "amount" is freeform
```

AFTER:

```typescript
type UserId = Branded<string, "UserId">;
type Money  = { cents: number; currency: Currency };
type TxnId  = Branded<string, "TxnId">;

function transfer(from: UserId, to: UserId, amount: Money): Promise<Result<TxnId, TransferError>>;
```

Misuse fails to compile. Currency cannot be lost. Returns are typed.

## 2. Boolean Blindness -> Role ADT

BEFORE:

```typescript
type User = { id: UserId; isAdmin: boolean; isOwner: boolean; isReadOnly: boolean };
```

8 representable states; 4 legal. Caller writes `if (u.isAdmin && !u.isReadOnly)` everywhere.

AFTER:

```typescript
type Role = { tag: "admin" } | { tag: "owner" } | { tag: "member" } | { tag: "viewer" };
type User = { id: UserId; role: Role };
```

Pattern match exhaustive. Adding a role breaks every match site until updated.

## 3. Config Explosion -> Progressive Grouping

BEFORE: 30-field options bag.

```typescript
function createServer(opts: {
  host, port, tlsCert?, tlsKey?, maxConnections, idleTimeoutMs,
  readTimeoutMs, writeTimeoutMs, logLevel, logFile?, metricsPort?, ...
});
```

AFTER:

```typescript
type ServerConfig = {
  bind:    BindConfig;     // host, port, tls
  limits:  LimitsConfig;   // connections, timeouts
  observe: ObserveConfig;  // log, metrics, health
};

function createServer(c: ServerConfig): Server;
```

Three groups; defaults per group. Caller overrides only what matters. Defaults are the pit of success.

## 4. String-Error -> Error ADT

BEFORE:

```typescript
function parseOrder(raw: unknown): Order | string {
  if (...) return "missing customer";
  if (...) return "bad sku: " + sku;
}

const r = parseOrder(payload);
if (typeof r === "string") logger.warn(r);   // can only log
```

AFTER:

```typescript
type ParseError =
  | { tag: "missing-customer" }
  | { tag: "bad-sku"; sku: string }
  | { tag: "negative-quantity"; sku: string; got: number };

function parseOrder(raw: unknown): Result<Order, ParseError>;

switch (r.error.tag) {
  case "missing-customer":  return promptForCustomer();
  case "bad-sku":           return suggestNearestSku(r.error.sku);
  case "negative-quantity": return clampToOne(r.error.sku);
}
```

Caller branches per case. See SKILL.md "Error Shape" for taxonomy guidance.
