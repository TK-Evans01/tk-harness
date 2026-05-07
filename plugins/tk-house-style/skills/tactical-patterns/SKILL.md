---
name: tactical-patterns
description: Use when reaching for Factory, Builder, Strategy, Observer, Singleton, Decorator, or other GoF patterns - shows how each dissolves into HOF / ADT / smart constructor in FP code, names the two that survive
user-invocable: false
---

# Tactical Patterns

## Overview

**Core principle:** most GoF patterns dissolve in FP. They were workarounds for missing language features (HOF, ADT, pattern match, immutable data). Reach for the FP equivalent first; the class pattern is almost always over-built.

**Why this matters:** Java-pattern reflex generates classes whose only job is to stand in for a function. `*Factory` whose body is two lines of construction; stub-author should not have written it.

## When to Use

Triggered JIT during stub-author or body-implementor work, when the model is about to emit a class pattern.

**Trigger symptoms:**
- About to write a class named `*Factory`, `*Builder`, `*Strategy`, `*Observer`, `*Decorator`, `*Adapter`, `*Visitor`, `*Singleton`, `*Manager`, `*Service` (where it is just a function bag).
- About to introduce a `Builder` for a record with <5 fields.
- About to write a `Singleton` to share state.
- Reviewer flags a class hierarchy that should be a discriminated union.

## Core: Most Patterns Dissolve

| GoF Pattern | FP Equivalent | Verdict |
|-------------|---------------|---------|
| Factory / Abstract Factory | Smart constructor returning `Result<Domain, ParseError>` | use smart ctor |
| Builder | Record + spread; in Rust, typestate builder | record literal unless inter-field invariants |
| Singleton | Module-level immutable value; or capability injected | NEVER for mutable state in core |
| Visitor | Exhaustive `match` on ADT | ADT match dissolves visitor |
| State | Discriminated union + transition fn | ADT (see architecture-patterns:state-machine) |
| Command | ADT of operations + interpreter fn | pattern match |
| Memento | Persistent data structure with snapshot | structural sharing |
| Composite | Recursive ADT (`type Tree = Leaf \| Node(Tree, Tree)`) | ADT |
| Observer / pub-sub | Event stream / `Observable` / channel | architecture decision, not class pattern |
| Iterator | `Iterable` / lazy seq / generator | language built-in |

**Bulk dissolution (HOF + composition).** Strategy, Decorator, Adapter, Facade, Proxy, Bridge, Template Method, Chain of Responsibility, Mediator, Flyweight, Prototype, Interpreter all collapse into one of:
- pass the function (Strategy, Template Method, Bridge)
- compose `pipe(f, g, h)` or middleware (Decorator, Proxy, Chain of Responsibility)
- module of curated exports (Facade)
- port-and-adapter at boundary (Adapter)
- coordination module / actor (Mediator)
- interning / persistent shared structure (Flyweight)
- structural copy / language built-in (Prototype)

## Two That Survive

These patterns earn first-class treatment because their FP form has unique value:

### Smart Constructor

The FP-native form of Factory. Already covered: see `../nearly-pure-functional/SKILL.md` section 3.

### Typestate Builder (Rust idiom)

When many optional fields have inter-field invariants, encode required-fields-set in the type so `.build()` only compiles when all required fields are set. See `typestate-builder.md`.

## Common Mistakes and Rationalizations

| Excuse | Reality | What to do |
|--------|---------|------------|
| "Factory is conventional" | Convention is not a reason; smart ctor returns `Result`. | Smart ctor. |
| "Builder for the record" | A 3-field record is a record literal. | `{ a, b, c }`. |
| "Strategy interface for flexibility" | One impl is not flexible; it is wrapping. | Pass the function. |
| "Singleton to share config" | Module-level immutable constants share without mutation. | Export the constant, or inject as capability. |
| "Decorator for cross-cutting concerns" | Function composition does the same. | `pipe(fn, withRetry, withLogging)`. |
| "Visitor for double dispatch" | Pattern match on the ADT does double dispatch for free. | `match` over the union. |

## Red Flags - STOP

- A class whose only methods are constructors -> use a smart ctor function.
- `Builder` for a 3-field record -> record literal.
- `Singleton` holding mutable state in core -> NEVER. Move to shell or eliminate.
- `Strategy` interface with one implementation -> pass the function.
- Class hierarchy with `instanceof` checks -> discriminated union + `match`.
- New `*Manager` / `*Service` class with only static methods -> module of free functions.

## Sub-pages

- `typestate-builder.md` - the Rust pattern that survives FP, with worked example

## Summary

1. Most GoF patterns dissolve into HOF, ADT, or smart constructor.
2. Smart constructor and typestate builder survive; the rest are over-engineering.
3. When tempted, name the FP equivalent first; if you cannot, reconsider.

**When in doubt:** ask "what does this class do that a function cannot?" If the answer is "nothing," delete the class.

---
Provenance: original to tk-harness (CC-BY-SA-4.0).
