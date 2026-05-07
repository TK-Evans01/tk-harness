---
name: architecture-patterns
description: Use when designing the internal shape of a module or service - chooses architecture (FCIS/hexagonal, pipeline, state machine, event-sourced, interpreter) with explicit rejected alternatives; complements system-topology which decides cross-process shape
user-invocable: false
---

# Architecture Patterns

## Overview

**Core principle:** within-process architecture is the second-most-expensive design decision after topology. Pick deliberately. The default is hexagonal + FCIS; deviations earn their tax with an FP-fit reason.

**Why this matters:** wrong architecture forces FP discipline to leak. Right architecture lets pure core, capabilities, and ADTs sit where they should without ceremony.

## When to Use

- Starting a design plan for a new module or service
- Refactoring a module that has outgrown its current shape
- Considering an event log, state machine, or interpreter
- Reviewer Step 3e (design-review only)

**Trigger symptoms:**
- Module mixes I/O orchestration with domain logic
- State transitions encoded with booleans instead of types
- Same logic must run against real and mock backends
- Audit / replay / undo is a stated requirement

## MANDATORY: Architecture Decision Record

Every design plan that introduces a non-trivial module **MUST** contain:

```
## Architecture Decision

- Chosen: <pattern>
- Why: <2-3 sentences; FP fit cited>
- Rejected:
  - <alt 1>: <one-line why-not>
- FP-fit notes: <where pure core lives, where effects live, what the boundary is>
```

NO EXCEPTIONS. Reviewer Step 3e greps for the heading and required fields.

"Non-trivial module" = exports a public surface, owns state, or coordinates effects. Utility modules with <=3 pure functions are exempt.

## Catalogue (Five Core Patterns)

| Pattern | Good for | Bad for | FP framing |
|---------|----------|---------|------------|
| **Hexagonal / FCIS (default)** | most apps | embedded / realtime tight loops | core = pure fns; shell = effects; ports = capabilities |
| **Pipeline / dataflow** | ETL, codecs, codegen, batch | bidirectional UI | `pipe(stage1, stage2, ...)` over `Result` |
| **State machine (explicit ADT)** | auth, checkout, anything with phases | trivial CRUD | discriminated union of states + `transition: (s, e) => Result<s', err>` |
| **Event-sourced** | audit, replay, finance, undo/redo | low-latency CRUD with no audit need | events = immutable log; state = `fold(events)` |
| **Interpreter / free monad-lite** | DSL, dry-run, multi-backend | one-off scripts | program-as-data ADT + `interpret` / `dryRun` |

**Default:** hexagonal + FCIS. Pure core; thin shell; capabilities at the edge.

Rare shapes (CRUD-on-records, onion/clean, intra-process actor, intra-module CQRS, state-monad core) live in `_rare-shapes.md`. Reach for them only when the standard five do not fit.

## Common Mistakes and Rationalizations

| Excuse | Reality | What to do |
|--------|---------|------------|
| "Event-sourcing for flexibility" | You will not need replay; you will pay the consistency tax forever. | Event-source only when audit/replay is stated. |
| "State machine is overkill" | Boolean flag soup grows; the state machine writes itself, badly. | >=2 phases with rules => write the ADT. |
| "Interpreter pattern is heavyweight" | High payoff for two backends (real + mock); waste for one. | Use only when multi-backend or dry-run is real. |
| "CRUD because simple" | Domain logic leaks into controllers; no place for invariants. | Model the domain. Do not flatten to records. |
| "Onion / clean for clean code" | Layers of pass-through. Many small modules of nothing. | Stay at hexagonal unless team and adapter count justify. |

## Red Flags - STOP

- Module mixes I/O calls with business logic at the same call depth.
- State encoded with multiple booleans instead of an ADT.
- Event log without a reducer / projection (audit log mislabelled as event-sourcing).
- Interpreter pattern with one interpreter.
- Architecture Decision Record missing on a non-trivial module.
- "Why" not citing FP fit.

## Sub-pages

- `_rare-shapes.md` - CRUD-on-records, onion, intra-process actor, intra-module CQRS, state-monad core. Loaded only when the five core patterns do not fit.

## Summary

1. Default: hexagonal + FCIS. Earn deviations with FP-fit reasoning.
2. Architecture Decision Record on every non-trivial module.
3. The catalogue exists to justify, not to browse.

**When in doubt:** pure core, thin shell, capabilities at the edge. Most other patterns are this with extra steps.

---
Provenance: original to tk-harness (CC-BY-SA-4.0).
