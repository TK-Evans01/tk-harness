---
name: observability
description: Use when adding logging, metrics, or tracing to a module - keeps observability effects at the shell while preserving FP discipline in the core; defines structured logging, span/trace, and metric cardinality vocabulary
user-invocable: false
---

# Observability

## Overview

**Core principle:** observability is an effect. It belongs in the shell, with one exception: loggers passed as a capability into the core (already permitted under FCIS). Metrics and traces are NOT permitted in core; they emit, mutate counters, and read clocks.

**Why this matters:** instrumentation creeps. Once a counter call is in the core, every test needs a no-op metrics handle and the core is no longer pure. Hold the line at the shell boundary; pass the logger if you must.

## When to Use

- Adding logging, metrics, or tracing to a module
- Reviewing a module that emits to a metrics or tracing client from inside core
- Designing the observability surface of a new service

**Trigger symptoms:**
- "Where do I put the metric?"
- A core function takes a `MetricsClient` parameter.
- Logs emit at every step of a pure transformation.
- Cardinality alarms in production.

## MANDATORY: Effect Placement

| Effect | Allowed in Core? | Where it lives |
|--------|------------------|----------------|
| Logger (no-op-able) | YES (existing FCIS exception) | passed as capability; tests pass no-op |
| Metric counter / gauge / histogram | NO | shell wraps the core call and emits |
| Trace span / context | NO | shell opens span; passes correlation ID into core only as data |
| Event emit / pub-sub | NO | shell |
| Read clock for timestamp | NO | shell injects timestamp as parameter |

A metric or span call inside a core file is a **Critical** issue.

## Vocabulary

- **Structured logging.** Logs as records (`{ event, fields }`), not formatted strings. Queryable.
- **Log level.** `error`, `warn`, `info`, `debug`, `trace`. Default `info` in prod.
- **Span.** A unit of work with start, end, and attributes; children form a tree.
- **Trace.** A root span and its descendants across services; tied by trace ID.
- **Trace context propagation.** Headers (`traceparent`) carrying trace ID across boundaries.
- **Metric cardinality.** Number of distinct label combinations; high cardinality kills metric backends.
- **Counter / gauge / histogram.** Monotonic count / point-in-time value / distribution.
- **Sampling.** Keep a fraction of traces; full retention is too expensive at scale.
- **Correlation ID.** Per-request identifier propagated across logs / metrics / spans / messages.
- **Service-level objective (SLO).** Target for a measurable user-visible property; budgets alerts and toil.
- **Golden signals.** Latency, traffic, errors, saturation. Default dashboard set.

## Patterns

- **Logger as capability.** `function process(items, logger?)`; pass no-op in tests.
- **Span at the shell.** Shell opens span; calls pure core; closes span on the result.
- **Correlation ID as data.** Shell extracts ID from headers; passes as a parameter into core; core threads it through events it produces.
- **Idempotent log keys.** Use stable event names (`order.placed`, not `Successfully placed order #123`); fields carry the variable parts.
- **Cardinality discipline.** Labels must be low-cardinality (status, route, region). Never user IDs, never full URLs, never timestamps.

## Common Mistakes and Rationalizations

| Excuse | Reality | What to do |
|--------|---------|------------|
| "Just one metric in core" | Core is no longer pure; tests need a metrics double. | Wrap in shell. |
| "Span context is implicit" | Implicit context = global state = side effect. | Pass span / correlation ID as parameter. |
| "Log every step for debugging" | Log volume costs money; debug logs cost the most. | `debug` level for steps; `info` for outcomes. |
| "User ID as a metric label" | High cardinality; metric backend OOM. | User ID in logs only, never labels. |
| "Format the log message inline" | Search / aggregation breaks. | Stable event name + structured fields. |

## Red Flags - STOP

- Metric / counter / span call inside a `// pattern: Functional Core` file.
- Log message constructed with template strings carrying variable values (`Order ${id} failed`).
- Metric label of unbounded cardinality (user ID, URL, timestamp, free-form string).
- Span opened in core, closed in shell (lifecycle split).
- `console.log` / `print` / `eprintln!` debug statement left in committed code.
- No correlation ID propagated across an async boundary.

## Reviewer Notes

Reviewer Step 3a already flags clock reads in core. Extend to:

- Grep core files for known metric/tracing imports (`@opentelemetry/`, `prom-client`, `tracing::`, `opentracing`); core hits = Critical.
- Grep shell files for high-cardinality label patterns (template strings in label position) = Important.

## Summary

1. Logger is the only observability effect permitted in core. Metrics and spans live in shell.
2. Correlation ID is data; propagate it as a parameter.
3. Cardinality discipline is non-negotiable; labels are bounded sets.

**When in doubt:** put the metric in the shell function that wraps the core call. Always.

---
Provenance: original to tk-harness (CC-BY-SA-4.0).
