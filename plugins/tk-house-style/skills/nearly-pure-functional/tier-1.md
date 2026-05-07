# Tier 1: FCIS-light

The fallback profile. Use when a project opts down via `.tk-harness/style.md` (e.g. legacy code, scripting-heavy, exploratory).

This tier is the ed3d baseline: separate pure business logic (Functional Core) from side effects (Imperative Shell). No Result/Option requirement, no ADT mandate. Just the file-classification discipline.

## Rules

1. **Every file with runtime behavior carries a pattern comment.** First line of the file (or just under the module docstring):

   ```
   // pattern: Functional Core
   // pattern: Imperative Shell
   // pattern: Mixed (needs refactoring)
   // pattern: Mixed (unavoidable)  // Reason: <specific technical justification>
   ```

2. **Functional Core files contain only pure functions.** No file I/O, DB, HTTP, env access, `Date.now()`, `Math.random()`, or mutation outside function scope. Loggers are the single permitted exception (pass a no-op logger in tests).

3. **Imperative Shell files contain only I/O orchestration.** Gather data, call core, persist results. No business rules, no calculations beyond format conversion.

4. **Code flow is GATHER -> PROCESS -> PERSIST.** Shell gathers, Core processes, Shell persists. Every operation follows this sequence.

5. **Mixed (needs refactoring) is a TODO, not a destination.** Mark it, then split.

## Exempt Files (no pattern comment needed)

Type-only files, constants/enums-only, barrel/index re-exports, test files, generated code, shell scripts, config files, Markdown, HTML, task runners, package manifests, data files (JSON / YAML / CSV).

If an exempt file gains runtime logic, it crosses the threshold and must be classified.

## Decision Question

Before writing a function, ask: can this run without external dependencies (file system, DB, network, environment, clock, RNG)?

- **Yes** -> Functional Core.
- **No, but coordinates I/O** -> Imperative Shell.
- **No, mixes I/O with business logic** -> STOP. Refactor or escalate.

## Logger Exception

Loggers are explicitly permitted in Functional Core. Pass a no-op logger for unit tests. This is the single allowed side-effect channel in the core.

## Why This is Tier 1 and Not Tier 2

Tier 1 enforces *where* effects live. Tier 2 additionally enforces *how* errors and absence are represented (Result, Option), *what* shape data takes (ADTs), and *which* control flow is allowed (no `for` over collections, no mutation). Tier 1 is a structural discipline; Tier 2 is a structural discipline plus a vocabulary discipline.

A project on Tier 1 can use `throw`, `null`, and `for` loops in its core, as long as the file is classified Functional Core and is pure (no I/O). The code-reviewer's FP-primitives scan is skipped on Tier 1 projects; only the file-classification check runs.

## Reference

The full Tier 1 reference (worked examples, refactoring patterns, the FCIS decision tree) lives in ed3d's skill at `ed3d-house-style/skills/howto-functional-vs-imperative/SKILL.md`. Tier 1 is exactly that skill, no additions.
