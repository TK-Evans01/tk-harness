# tk-rpie

Research-Plan-Stub-Test-Implement-Eval (**RPSTIE**) workflow plugin. The core of tk-harness.

> **Naming note.** The workflow acronym is **RPSTIE** (six stages: Research, Plan, Stub, Test, Implement, Eval). The plugin namespace is **tk-rpie**, kept short for skill / agent reference ergonomics (e.g. `tk-rpie:executing-an-implementation-plan`). The plugin name is not changing.

Status: M0 skeleton — manifest only. Substantive implementation in M4.

## Workflow

```
Rough Idea
    |
    v
/start-design-plan                 ---> docs/design-plans/YYYY-MM-DD-<topic>.md
    | (clear context)
    v
/start-implementation-plan @design ---> worktree + phase files + test-requirements.md
    | (clear context)
    v
/execute-implementation-plan @plan ---> per task: stub-author -> test-author -> body-implementor
                                       per phase: code-reviewer -> bug-fixer (3-strike cap)
                                       end: librarian -> code-reviewer -> test-analyst
    |
    v
/finish-branch                     ---> merge / PR / discard
```

Auxiliary: `/flesh-it-out` for clarification standalone.

## Subagents

| Agent | Model | Role |
|-------|-------|------|
| `clarifying-questioner` | sonnet | Batches up to 5 ambiguity questions before design |
| `stub-author`           | sonnet | Writes function stubs + contract docs + types. Typechecks. Commits. |
| `test-author`           | sonnet | Writes tests against frozen stubs. Verifies tests fail with NotImplementedError, not import errors. Commits. |
| `body-implementor`      | sonnet | Writes function bodies. One function at a time, tests must transition red->green. Commits. |
| `code-reviewer`         | opus   | Per-phase review: verify, plan alignment, FP purity, test quality, refactor old-vs-new diff |
| `bug-fixer`             | sonnet | Fixes punch list from reviewer. Capped at 3 cycles. |
| `test-analyst`          | sonnet | Validates test coverage against acceptance criteria; emits human test plan |
| `librarian`             | sonnet | Updates CLAUDE.md / module AGENTS.md when contracts change |

## Skills

Workflow skills:
- `using-rpie`
- `asking-clarifying-questions`
- `starting-a-design-plan`, `writing-design-plans`
- `starting-an-implementation-plan`, `writing-implementation-plans`
- `executing-an-implementation-plan` — orchestrates the stub/test/body chain (rewritten vs ed3d)
- `using-git-worktrees` — worktree-first, mandatory for non-trivial
- `preserving-original-during-refactor` — keeps `<file>.original` for reviewer diff
- `requesting-code-review`
- `verification-before-completion`
- `systematic-debugging`
- `finishing-a-development-branch`

Discipline skills:
- `writing-stubs-and-docs`
- `writing-tests-against-stubs`
- `writing-bodies-against-tests`

## Key Divergences from ed3d-plan-and-execute

1. **Stubs/tests/bodies are three separate subagents**, not collapsed into one TDD implementor.
2. **Worktree mandatory** for any non-trivial task; ed3d makes it optional.
3. **Original file preserved** during refactor for reviewer's old-vs-new diff.
4. **FP-primitives block** injected into every coding subagent dispatch.
5. **3-strike fix-loop cap** with auto-escalation to `.tk-harness/blocked/<phase-id>-<UTC-timestamp>.md`.

## Provenance

Workflow shape and many skills derived from [ed3dai/ed3d-plugins](https://github.com/ed3dai/ed3d-plugins) `ed3d-plan-and-execute` (CC-BY-SA-4.0) and ultimately [obra/superpowers](https://github.com/obra/superpowers) (MIT).
