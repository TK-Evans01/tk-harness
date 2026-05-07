---
name: preserving-original-during-refactor
description: Use when a task is tagged `refactor:` and modifies an existing file's externally-observable behavior - preserves the pre-edit version of each touched file as `<file>.original` in the worktree so the code-reviewer can produce an old-vs-new behavior map.
user-invocable: false
---

# Preserving Original During Refactor

## Overview

Refactors must preserve externally-observable behavior. To make any regression visible to the code-reviewer, the original version of each file is preserved in the worktree as `<file>.original` until review passes. The reviewer reads both versions and produces a behavior map (Step 2b of code-reviewer).

**Core principle:** Behavior loss must be explicit. Silent removal is a Critical regression.

**Announce at start:** "I'm using the preserving-original-during-refactor skill before editing this file."

## When to Use

- Task type prefix is `refactor:` in the phase file or task spec
- Any task whose stated goal is to restructure existing code while preserving behavior
- The file already exists and has externally-observable behavior (exported functions, side effects, public API)

## When NOT to Use

- Greenfield work - there is no original to preserve
- Pure additions - new file, or new function in an existing file that does not replace anything
- Deliberate behavior changes - those are features, not refactors. The task should be retagged `feature:` and not run this skill. If you find yourself wanting to remove behavior, stop and confirm the task tag.

## Procedure (file-author side)

Run by whoever edits the file FIRST in the chain (typically stub-author, sometimes body-implementor for in-place refactors).

1. Identify each file you are about to modify. For each existing file `path/to/file.ext`:

   ```bash
   REL=path/to/file.ext
   cp -- "$REL" "$REL.original"
   ```

2. Ensure `*.original` is gitignored so artifacts do not pollute commits:

   ```bash
   grep -qxF '*.original' .gitignore || printf '\n# refactor preservation artifacts\n*.original\n' >> .gitignore
   ```

3. Edit the file freely. The `.original` sits beside it as a frozen reference.

4. Commit your edits as normal. Do not commit `.original` files (gitignore prevents this).

5. The `.original` artifact stays in the worktree until review approves and `finishing-a-development-branch` cleans it up.

## Procedure (reviewer side)

Cross-link: this is Step 2b of `code-reviewer`. Summarized here for completeness.

1. Locate originals:

   ```bash
   find . -name '*.original' -not -path './.git/*'
   ```

2. For each `<file>.original`, diff against current `<file>`:
   - Enumerate behaviors in the original (exports, side-effect points, error paths, invariants)
   - Map each to the new file: present / present-with-changed-shape / removed
   - Removed without justification in commit message or phase plan = **Critical regression**

3. Include the behavior map table in the review output.

## Procedure (cleanup side)

The `finishing-a-development-branch` skill removes `.original` artifacts before merge:

```bash
find . -name '*.original' -not -path './.git/*' -delete
```

This runs after review approves and before the merge/PR step. Until then, originals stay so re-review (cycles 2 and 3) has the same reference.

## Worked Example

Phase task: `refactor: extract pure parser from src/parse.ts`

Before editing:

```bash
REL=src/parse.ts
cp -- "$REL" "$REL.original"
grep -qxF '*.original' .gitignore || printf '\n*.original\n' >> .gitignore
```

Edit `src/parse.ts`, commit. `src/parse.ts.original` remains in the worktree.

Reviewer runs `find . -name '*.original'`, finds `src/parse.ts.original`, diffs, produces:

```
| Behavior (original)         | Status                     | Location (new)   | Notes              |
|-----------------------------|----------------------------|------------------|--------------------|
| parse(input: string): AST   | present                    | src/parse.ts:12  | identical          |
| throws on bad input         | present-with-changed-shape | src/parse.ts:34  | now Result<AST,E>  |
| logs warnings to stderr     | removed (justified)        | -                | commit msg: "logging moved to caller" |
```

After approval, `finishing-a-development-branch` deletes `src/parse.ts.original`.

## Edge Cases

**File renamed (`git mv old.ts new.ts`):**
- Preserve original at the OLD name with `.original` suffix: `old.ts.original`
- Reviewer maps via `git log --follow new.ts` to find the rename, then diffs `old.ts.original` vs `new.ts`

**File split across multiple new files:**
- Preserve as `<old>.original`
- Reviewer maps each behavior in the original to whichever new file now contains it
- All target new files are in scope for the behavior map

**File deleted (behavior moved entirely into another existing file):**
- Treat as a refactor of the destination file
- Preserve `<deleted-file>.original` alongside the destination
- Reviewer maps original behaviors into the destination's new shape

**Multiple files refactored in one task:**
- Preserve each one. The reviewer's `find` walks all of them.

## Common Mistakes

| Mistake                                          | Fix                                                          |
|--------------------------------------------------|--------------------------------------------------------------|
| Committing `.original` artifacts                 | Add `*.original` to `.gitignore` BEFORE the first commit     |
| Deleting `.original` before review approves      | Wait for `finishing-a-development-branch` to clean up        |
| Reviewing without locating originals             | Mandatory `find . -name '*.original'` step in code-reviewer  |
| Skipping the skill for "small" refactors         | Any task tagged `refactor:` triggers it - no size threshold  |
| Running the skill on greenfield (no original)    | Skill is a no-op when source file does not yet exist; skip   |
| Editing the file before copying to `.original`   | Copy FIRST, edit second. Order matters.                      |

## Red Flags

**Never:**
- Remove behavior silently in a refactor task
- Add new public API under a `refactor:` task (retag as `feature:`)
- Commit `.original` files
- Delete `.original` files before review approves

**Always:**
- Copy before editing
- Gitignore the artifact
- Leave the artifact in the worktree until cleanup
- Verify the task is genuinely a refactor (behavior-preserving) before invoking

## Exit Criteria

This skill is complete when:
1. Each existing file you intend to modify has a sibling `<file>.original` in the worktree
2. `*.original` is in `.gitignore`
3. You proceed with the edit

Cleanup is the responsibility of `finishing-a-development-branch`, not this skill.

## Integration

**Called by:**
- `stub-author` - when scaffolding a refactor task
- `body-implementor` - when an in-place refactor has no stub phase

**Pairs with:**
- `code-reviewer` - reads the artifacts in Step 2b (refactor old-vs-new diff)
- `finishing-a-development-branch` - removes the artifacts after approval
