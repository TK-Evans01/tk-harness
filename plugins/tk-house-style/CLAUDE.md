# tk-house-style

Coding standards and skills for projects under tk-harness. The plugin's job is to define discipline tiers and the vocabulary used by every code-touching subagent.

## Purpose

This plugin defines:

- **Discipline tiers** - Tier 1 (FCIS-light), Tier 2 (nearly-pure, default), Tier 3 (effect-typed opt-in).
- **Skills** - reference pages loaded by anchor skills and by code-touching subagents.
- **Forbidden lists** - the grep-able rules the code-reviewer scans.

## Plugin Structure

```
tk-house-style/
  skills/
    nearly-pure-functional/
      SKILL.md            anchor: glossary + forbidden list + dispatch block
      tier-1.md           FCIS-light fallback
      tier-2.md           default, this plugin's center of gravity
      tier-3.md           effect-typed opt-in
      typescript.md       per-language quick card
      python.md           per-language quick card
      rust.md             per-language quick card
    writing-good-tests/   (separate skill, separate pass)
    coding-effectively/   anchor entry point that branches into the others
  agents/                 (reserved for future use)
  CLAUDE.md               this file
```

## Tier Model

| Tier | Name         | Default? | Enforcement                                                      |
|------|--------------|----------|------------------------------------------------------------------|
| 1    | FCIS-light   | no       | Pure core / I/O shell, file pattern comment (ed3d baseline)      |
| 2    | Nearly-pure  | yes      | Tier 1 + Result/Option, ADTs, immutability, smart constructors   |
| 3    | Effect-typed | no       | Tier 2 + effects modeled in the type system                      |

A project chooses its tier by writing the tier name into `.tk-harness/style.md` at its repo root. Absence of that file means Tier 2.

## Working with Skills

When creating or modifying skills in this plugin, use `writing-skills` (when present) or follow the rules below. Skills are reference pages for Claude instances; they compete for context budget with the conversation, so keep them dense.

### Skill Frontmatter

Two fields, exactly:

```
---
name: skill-name-with-hyphens
description: Use when <trigger> - <what it does, third person>
---
```

Optional third field: `user-invocable: false` for internal-only skills (subagent-only, not surfaced to the user as a slash command).

Sub-pages (tier-*.md, typescript.md, python.md, rust.md) do **not** carry frontmatter. They are loaded by cross-link from the anchor SKILL.md, not by the skill loader.

### Skill Writing Rules

1. **ASCII only.** Use `->` not arrow chars, straight quotes, plain hyphens. No emojis. ed3d burned on this; we don't repeat the lesson.
2. **Target under 500 words** for most skills. The anchor for a tier (this plugin's `nearly-pure-functional/SKILL.md`) is allowed to be longer because it carries the canonical glossary and forbidden list, but every section earns its place.
3. **Common-mistakes table** for any discipline skill. Rationalization in column 1, reality in column 2, what to do in column 3.
4. **Red flags STOP list** for any discipline skill. Bulleted, scannable, used by the code-reviewer.
5. **One excellent worked example** per concept, not five mediocre ones in different languages. Per-language detail goes in the language quick card.
6. **Description starts with "Use when".** Triggers and symptoms in the description; the body is the reference.

### Encoding Pitfalls

- No smart quotes (`"` and `'` only).
- No em dashes; use ` - ` (two hyphens spelled as one ASCII hyphen with surrounding spaces) if a long dash is wanted.
- No Unicode arrows; use `->` only.
- No non-ASCII whitespace (no NBSP, no zero-width).
- Verify with `file -i SKILL.md`; expect `charset=us-ascii`.

## Anchor Skill

`coding-effectively` (separate pass) is the entry point. It branches into:

- `nearly-pure-functional` (this plugin's discipline core; tier-aware)
- `writing-good-tests` (testing discipline)
- `property-based-testing` (Hypothesis / fast-check / proptest)

A subagent that needs the discipline-core vocabulary loads `nearly-pure-functional/SKILL.md`; if it then needs language-specific detail, it loads the matching quick card. The dispatch-time `<fp-primitives-active>` block (defined in repo-root `CLAUDE.md`) is the priming layer that points subagents at this skill.

## Provenance

Some skills derive from `ed3dai/ed3d-plugins` (`ed3d-house-style`, CC-BY-SA-4.0) and ultimately from `obra/superpowers` (MIT). Provenance is marked per file or per plugin LICENSE. Default for new content in this plugin: CC-BY-SA-4.0. The `nearly-pure-functional` skill set is original to tk-harness; structure cribbed from ed3d's FCIS skill but content written fresh.

## Questions

Refer to `writing-skills` (when present) or to ed3d's `ed3d-house-style/CLAUDE.md` for the longer-form rationale. The repo-root `CLAUDE.md` (`/home/tk/Projects/harness/CLAUDE.md`) carries the cross-plugin conventions (XML Task syntax, version sync, model defaults, encoding).
