# Boundaries Deeper

Sub-page of `nearly-pure-functional/SKILL.md`. Loaded on demand. No frontmatter.

The boundary primitives beyond smart constructor: serialization out, schema evolution, canonical form, hashing-as-identity. Glossary; reach in when designing a public boundary or a wire format.

## Vocabulary

- **Parse-in / encode-out symmetry.** Every smart constructor that parses external data has a sibling `encode` that produces the wire form. Round-trip property: `parse(encode(x)) == ok(x)`.
- **Canonical form.** Two values "equal in meaning" have one byte representation. Required for hashing, signing, content-addressing.
- **Deterministic serialization.** No map iteration order, no float formatting drift, no timezone reformatting. Same input -> same bytes, always.
- **Schema evolution.** A change to the wire format that callers can adopt without breaking existing producers / consumers.
- **Backward compatible.** New version reads old data.
- **Forward compatible.** Old version reads new data (typically by ignoring unknown fields).
- **Tagged union on the wire.** Sum types serialize with an explicit discriminant field; never positional.
- **Optional vs absent.** Distinguish "field missing" from "field present with null"; pick one and document.
- **Hashing as identity.** Content-addressable storage uses canonical form + hash; any non-determinism breaks deduplication.

## Patterns

- **Versioned envelope.** `{ v: 1, payload: ... }`. Bump `v` for incompatible changes; carry both parsers during the transition.
- **Expand-then-contract migration.** Add the new field optional; backfill; flip required; remove old field.
- **Frozen wire model in a separate module.** Wire types are not domain types; never share the type definition. Translation is explicit.
- **Property tests for round-trip.** Generate domain values; encode; parse; assert equal. One test catches a class of bugs.

## Red Flags - STOP

- Smart constructor exists, no corresponding encoder.
- Encoder uses `JSON.stringify` on a record with a `Map` or `Set` (non-deterministic order).
- Wire format uses positional union (`[type, ...args]`) without a tag field.
- Schema change shipped without a versioned envelope or a migration plan.
- Hash computed over a non-canonical encoding.
- Wire type aliased to domain type (`type WireOrder = Order`); change to domain breaks the wire silently.

## Reviewer Notes

When changes touch a public wire format:

1. Confirm encoder exists alongside parser.
2. Confirm round-trip property test exists.
3. Confirm canonical form (sorted keys, fixed float format, UTC).
4. If the schema changed, confirm the version bump or the back-compat path.
