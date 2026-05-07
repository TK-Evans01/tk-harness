# tk-house-style

Tier-2 nearly-pure functional house style for projects using tk-harness.

Status: M0 skeleton — manifest only. Substantive content lands in M3.

## Tier Model

| Tier | Name | Enforcement |
|------|------|-------------|
| 1 | FCIS-light    | Pure core / I/O shell, file pattern comment (ed3d baseline) |
| 2 | **Nearly-pure** | Tier 1 + Result/Option, no exceptions in core, ADTs + exhaustive match, immutability, total functions, smart constructors |
| 3 | Effect-typed  | Tier 2 + effects modeled (IO/Task/Reader-equivalent) |

**Default: Tier 2.** Project may override via `.tk-harness/style.md`.

## Planned Skills

- `nearly-pure-functional/SKILL.md` — Tier-2 glossary, allowed/forbidden, smart constructors, parse-don't-validate
- `nearly-pure-functional/typescript.md` — TS quick card (fp-ts/effect-ts, eslint-plugin-functional, ts-pattern)
- `nearly-pure-functional/python.md` — Python quick card (returns lib, frozen dataclass, match, ruff config)
- `nearly-pure-functional/rust.md` — Rust quick card (Result/Option discipline, no unwrap, clippy lints)
- `writing-good-tests` — testing discipline (ported from ed3d)
- `property-based-testing` — Hypothesis / fast-check / proptest (ported from ed3d)
- `coding-effectively` — anchor skill referencing the others (ported + adapted)

## FP-Primitives Active Block

Subagents that touch code receive this block at dispatch time:

```
<fp-primitives-active>
Tier: 2 (nearly-pure)
Language: <lang>
Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
Forbidden: throw, null, any, mutation, Date.now in core
</fp-primitives-active>
```

The full glossary lives in `nearly-pure-functional/SKILL.md`. The block above is the dispatch-time priming layer.

## Provenance

Some skills derived from [ed3dai/ed3d-plugins](https://github.com/ed3dai/ed3d-plugins) `ed3d-house-style` (CC-BY-SA-4.0) and ultimately from [obra/superpowers](https://github.com/obra/superpowers) (MIT). Property-based-testing originally from [trailofbits/skills](https://github.com/trailofbits/skills).
