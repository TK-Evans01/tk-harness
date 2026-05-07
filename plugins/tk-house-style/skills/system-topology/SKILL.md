---
name: system-topology
description: Use when starting a design plan for a system that crosses process boundaries, services, or independent deploys - chooses topology (monolith, modular, microservices, microkernel, event-driven, dataflow, FaaS) with explicit rejected alternatives and a measurement-cited justification
user-invocable: false
---

# System Topology

## Overview

**Core principle:** the topology decision is the most expensive in a design plan. Reverse it later and pay 10x. Make it explicitly, with measured constraints, against an enumerated alternative set.

**Why this matters:** "we'll use microservices" without measurement is the most common over-engineering failure. Distributed systems multiply ops cost, latency, and failure modes. Modular monolith is the default; deviations earn their tax with evidence.

## When to Use

- Starting a design plan that involves more than one process, service, or deploy
- Considering whether to extract a service from a monolith
- Considering whether to introduce an event bus, queue, or pub/sub
- Considering whether to expose a plugin/extension API (microkernel)
- Reviewer Step 3d (design-review only)

**Trigger symptoms:**
- "Should we split this off?"
- "We need to scale X independently."
- "Different teams want to own different parts."
- "Latency / fault isolation / regulatory split."

## MANDATORY: Topology Decision Record

Every design plan that involves a system shape **MUST** contain:

```
## Topology Decision

- Chosen: <topology>
- Why: <2-3 sentences citing measured constraints>
- Rejected:
  - <alt 1>: <one-line why-not>
  - <alt 2>: <one-line why-not>
- Reversibility: <1-5; 1 = trivial to change, 5 = requires rewrite>
- Re-evaluation trigger: <metric or event that would force revisiting>
```

NO EXCEPTIONS. Reviewer Step 3d greps for the heading and the five fields.

"Why" must cite measurements (RPS, team size, fault isolation requirement, regulatory split, ops headcount), not aspirations ("future scale", "flexibility", "best practice").

## Catalogue (Seven Topologies)

| Topology | When | When NOT | Risk |
|----------|------|----------|------|
| Single-binary monolith | <5 devs, single bounded context, <1k RPS | many independent release cadences | mud-ball if domains not bounded |
| **Modular monolith (DDD)** | one deploy, multiple bounded contexts, team boundaries | ops needs scale-isolation per domain | enforced module boundaries hard without tooling |
| Microservices | independent scaling, polyglot teams, fault isolation, regulatory split | <50 devs, single team, no measured need | distributed monolith, n+1 latency, ops tax 5-10x |
| Microkernel / plugin | extensible product (IDE, CMS), 3rd-party extensions | closed app | plugin API breakage, version skew |
| Event-driven / pub-sub | async workflows, audit, fan-out, decoupled producers/consumers | sync request/response is the dominant load | eventual consistency UX, debugging hard |
| Pipes-and-filters / dataflow | ETL, codegen, batch, stream | interactive transactional | back-pressure, restart semantics |
| Lambda / FaaS | spiky workloads, per-event isolation, no long state | steady load, latency-sensitive, complex transactions | cold start, vendor lock, observability gaps |

## Default

**Modular monolith.** Escalate ONLY if 2+ contexts have measured-divergent scaling, cadence, or regulatory needs AND ops headcount supports the deviation.

## Decision Template (fill before choosing)

```
1. Estimated team size at 18 months: ___
2. Independent release cadences needed: ___ (list)
3. Bounded contexts (one-line each): ___
4. Failure-isolation requirements: ___ (per context)
5. Latency budget P99: ___
6. Ops budget (engineers): ___
7. Regulatory split: ___ (none / per-context / per-region)
```

If 2, 4, 5, 7 are blank or uniform, default to modular monolith.

## Common Mistakes and Rationalizations

| Excuse | Reality | What to do |
|--------|---------|------------|
| "Microservices for future scale" | Distributed monolith ahead. | Modular monolith. Extract when measured. |
| "Each team should own a service" | Conway's law cuts the wrong way; you bake org chart into deploy graph. | Module boundaries first; service split only when team genuinely cannot deploy together. |
| "We need event-driven for decoupling" | Async always more complex than sync. | Sync calls until measured back-pressure or fan-out. |
| "Lambda for elasticity" | Cold starts, observability gaps, vendor lock. | FaaS only for spiky, isolated, stateless workloads. |
| "Microkernel for flexibility" | Plugin APIs are the hardest contract to keep stable. | Microkernel only with a documented extension catalogue. |
| "Best practice is microservices" | There is no industry-wide best practice. | Cite *your* measurements. |

## Red Flags - STOP

- "microservices for future scale" without measured demand
- service-per-class (nano-services)
- shared mutable database between services (distributed monolith tell)
- sync chains > 3 services (latency multiplication)
- new microkernel without an extension catalogue and a stable API contract
- event-driven where every consumer is also the only producer
- "Why" field citing aspirations rather than measurements
- "Rejected" list missing or fewer than 2 alternatives

## Summary

1. Default is modular monolith. Earn deviations with measurements.
2. Topology Decision Record in every system-shape design plan. Five fields, no exceptions.
3. Catalogue exists to justify, not to browse.

**When in doubt:** the boring choice has a 90% lower ops tax. Choose it unless measurement says otherwise.

---
Provenance: original to tk-harness (CC-BY-SA-4.0).
