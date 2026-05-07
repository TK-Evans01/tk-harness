# Rare Shapes

Sub-page of `architecture-patterns/SKILL.md`. Loaded on demand. No frontmatter.

Patterns that are sometimes the right answer but rarely the default. Glossary-style; reach in only when the five core patterns do not fit.

## CRUD-on-Records

**Shape:** parse -> operate -> serialize. No domain layer.

**Good for:** internal admin tools, scaffolded apps, prototypes where the domain is genuinely "rows in a table."

**Bad for:** anything with invariants between fields. Domain logic leaks into controllers; no place for parse-don't-validate.

**FP framing:** smart constructors at I/O boundary do the work; "domain" is the parsed record.

## Onion / Clean

**Shape:** concentric layers (entities, use-cases, interface adapters, frameworks). Dependency rule: inner layers know nothing of outer.

**Good for:** large team with many adapters and a long-lived domain core.

**Bad for:** small services; you write five files of pass-through to add one feature.

**FP framing:** entities are ADTs; use-cases are pure functions; outer layers are the imperative shell. Same lattice as hexagonal with more named layers.

**Trigger to reach for it:** team >=10, adapter count >=4, domain expected to outlast any one adapter.

## Intra-Process Actor / CSP

**Shape:** independent stateful entities communicating by mailbox or channel.

**Good for:** many independent stateful units (chat sessions, IoT devices, game agents) within one process.

**Bad for:** stateless RPC, request/response, anything with shared mutable state across actors.

**FP framing:** actor body is `(state, message) -> (state', effects)` - pure fold over inbox; mailbox is the only effect.

**Trigger to reach for it:** units with isolated state and high parallelism within a process.

## Intra-Module CQRS

**Shape:** within one module, separate read model (projection) from write model (events / commands).

**Good for:** read:write skew where projections are cheap to compute and reads dominate.

**Bad for:** balanced read/write loads; you maintain two models for nothing.

**FP framing:** writes produce events (immutable); reads are folds over events into projection records.

**Distinct from:** system-topology CQRS, which splits read and write across processes. Intra-module CQRS is a within-process shape.

## State-Monad Core

**Shape:** core threads state through a pure update function; shell sequences calls.

**Good for:** simulations, game loops, interpreters where state mutates many times per tick.

**Bad for:** stateless services; ceremony with no payoff.

**FP framing:** `step: (state, input) -> (state', output)`; sequence with `fold` or a state-monad combinator.

**Trigger to reach for it:** core logic is "step a state machine N times per second," and Tier 2 scattered-capability passing is too noisy.

## Reviewer Notes

If a design picks one of these, the Architecture Decision Record's "Why" must explain why none of the five core patterns fit. Otherwise default to hexagonal + FCIS.
