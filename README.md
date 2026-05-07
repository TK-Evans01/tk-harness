# tk-harness

Claude Code plugin marketplace implementing a strict research-plan-stub-test-implement-eval (RPSTIE) workflow with Tier-2 nearly-pure functional discipline.

Status: **M0 — skeleton.** Plugin manifests, structure, conventions in place. No agents/skills/commands implemented yet.

## Workflow Shape

```
Rough Idea
    |
    v
/start-design-plan          ---> Design Document (committed)
    | (clear context)
    v
/start-implementation-plan  ---> Phase files + worktree
    | (clear context)
    v
/execute-implementation-plan ---> per task: stub-author -> test-author -> body-implementor
                                  per phase: code-reviewer -> bug-fixer (capped loop)
                                  end: test-analyst -> librarian -> finishing-a-development-branch
```

Main thread runs at top-line model (Opus). Subagents default to Sonnet; reviewer escalates to Opus for subtle catches.

## Plugins

| Plugin | Purpose |
|--------|---------|
| `tk-foundation`     | Generic subagents + base skills |
| `tk-research`       | Codebase + internet research subagents |
| `tk-house-style`    | Tier-2 nearly-pure FP discipline + per-language quick cards |
| `tk-verify`         | `/verify` gate, edit-validation hook |
| `tk-rpie`           | RPSTIE workflow commands and subagents |
| `tk-hooks`          | Security hardening, CLAUDE.md reminder, skill reinforcement |

## Subagent Roster

| Stage             | Agent                                    | Model  |
|-------------------|------------------------------------------|--------|
| Orchestrate       | main thread                              | opus   |
| Research          | codebase-investigator, internet-researcher | sonnet |
| Clarify           | clarifying-questioner                    | sonnet |
| Stubs             | stub-author                              | sonnet |
| Tests             | test-author                              | sonnet |
| Bodies            | body-implementor                         | sonnet |
| Review (per phase) | code-reviewer                           | opus   |
| Fix               | bug-fixer                                | sonnet |
| Final tests       | test-analyst                             | sonnet |
| Docs              | librarian                                | sonnet |

## House Style: Tier-2 Nearly-Pure Functional

Default for projects using this harness. Project may override via `.tk-harness/style.md`.

- Result/Either for fallible operations; Option/Maybe for absence
- No exceptions in functional core
- Algebraic data types + exhaustive pattern matching
- Immutable data; persistent data structures for "updates"
- Smart constructors at boundaries (parse-don't-validate)
- Effects pushed to imperative shell

See `plugins/tk-house-style/skills/nearly-pure-functional/SKILL.md` (M3).

## Installation (once published)

```
/plugin marketplace add https://github.com/TK-Evans01/tk-harness.git
/plugin install tk-rpie@tk-harness
/plugin install tk-house-style@tk-harness
# ... etc
```

## Roadmap

- **M0** Skeleton (this commit)
- **M1** Foundation + research plugins (port from ed3d, adapt)
- **M2** `tk-verify` — `/verify` gate, edit-validation hook, per-language arch-lint configs
- **M3** `tk-house-style` — `nearly-pure-functional` skill + per-language cards + linter configs
- **M4** `tk-rpie` — full RPSTIE workflow
- **M5** `tk-hooks` — port ed3d hook trio
- **M6** Dogfood on a real project, tighten

## Attribution

Inspired by and partially derived from [ed3dai/ed3d-plugins](https://github.com/ed3dai/ed3d-plugins) by Ed Ropple, which itself derives from [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent.

Files derived from those projects retain their original MIT license (see per-plugin LICENSE files).

## License

CC-BY-SA-4.0 for original content. MIT for files derived from `obra/superpowers` (marked per-file or per-plugin).
