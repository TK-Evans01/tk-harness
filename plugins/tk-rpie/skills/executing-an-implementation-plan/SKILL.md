---
name: executing-an-implementation-plan
description: Use when executing implementation plans with independent tasks - dispatches stub-author, test-author, body-implementor in sequence per task; reviews once per phase; loads phases just-in-time
user-invocable: false
---

# Executing an Implementation Plan

Execute plan phase-by-phase, loading each phase just-in-time to minimize context usage.

**Core principle:** Read one phase -> for each task in phase, run the stub -> test -> body chain -> after all tasks, run code review -> move to next phase. Never load all phases upfront. Never collapse the per-task chain into a single dispatch.

**REQUIRED SKILL:** `requesting-code-review` - The review loop (dispatch, fix, re-review until zero issues, with the 3-strike cap below).

## Overview

**When NOT to use:**
- No implementation plan exists yet (use writing-implementation-plans first)
- Plan needs revision (brainstorm or re-plan first)

**The unit of work below the phase is the task (or a grouped subcomponent of tasks). Each task is implemented by a chain of THREE subagents in this order:**

1. `tk-rpie:stub-author` - writes signatures, contract docs, types, ADTs; raises `NotImplementedError`-equivalent in bodies; typechecks; commits.
2. `tk-rpie:test-author` - writes tests against the frozen stubs; verifies tests fail with `NotImplementedError`-equivalent (NOT `ImportError`, NOT `AttributeError`); commits.
3. `tk-rpie:body-implementor` - implements function bodies one at a time, transitioning each test red -> green; runs full verification at the end; commits.

This split is the design point of tk-rpie. Do not collapse it.

## Per-task Chain Invariants

> **Stubs are frozen at STUBS_SHA when test-author runs. Tests are frozen at TESTS_SHA when body-implementor runs.**
>
> - test-author MUST NOT edit stub files. If a stub is wrong, test-author returns a BLOCKED report identifying the stub bug; you escalate by stopping the phase.
> - body-implementor MUST NOT edit stub or test files. If a test is wrong, or a stub signature is wrong, body-implementor returns a BLOCKED report; you escalate.
> - The handoff between agents is a commit SHA. You capture that SHA from each agent's response and pass it to the next agent so the next agent can confirm what state it is operating against.
> - If any agent in the chain returns BLOCKED, write a `BLOCKED.md` describing the situation and stop the phase. Do not proceed to the next task.

These invariants exist because the value of the split is honest red->green TDD with clear authorship boundaries. The moment one agent edits another's artifacts, the signal is lost.

## MANDATORY: Human Transparency

**The human cannot see what subagents return. You are their window into the work.**

After EVERY subagent completes (stub-author, test-author, body-implementor, code-reviewer, bug-fixer, librarian, test-analyst), you MUST:

1. **Print the subagent's full response** to the user before taking any other action.
2. **Do not summarize or paraphrase** - show them what the subagent actually said.
3. **Include all details:** test counts, failing-test names, issue lists, commit hashes, error messages, BLOCKED reasons.

**Before dispatching any subagent:**
- Briefly explain (2-3 sentences) what you are asking the agent to do.
- State which phase and task this covers.
- State which step in the per-task chain (stub / test / body) this is.

**Why this matters:** When you silently process subagent output without showing the user, they lose visibility into their own codebase. They cannot catch errors, learn from the process, or intervene when needed. Transparency is not optional.

**Red flag:** If you find yourself thinking "I will just move on to the next step in the chain" without printing the subagent's response, STOP. Print it first. Especially do not skip the print between stub-author and test-author - that response carries the STUBS_SHA you need to pass forward.

## REQUIRED: Implementation Plan Path

**DO NOT GUESS.** If the user has not provided a path to an implementation plan directory, you MUST ask for it.

Use AskUserQuestion:
```
Question: "Which implementation plan should I execute?"
Options:
  - [list any plan directories you find in docs/implementation-plans/]
  - "Let me provide the path"
```

If `docs/implementation-plans/` does not exist or is empty, ask the user to provide the path directly.

**Never assume, infer, or guess which plan to execute.** The user must explicitly tell you.

## REQUIRED: FP-Primitives Active Block

Every coding-agent dispatch in this skill (stub-author, test-author, body-implementor, bug-fixer) MUST be prefaced with the `<fp-primitives-active>` header. Determine the Tier and Language from the implementation plan or from `.tk-harness/implementation-plan-guidance.md` if present. Default Tier is 2 (nearly-pure) unless the plan says otherwise.

The block looks like:

```
<fp-primitives-active>
Tier: 2 (nearly-pure)
Language: <lang>
Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
Forbidden: throw, null, any, mutation, Date.now in core
</fp-primitives-active>
```

The same block is also passed to code-reviewer so it can run the FP-violation check (see code-reviewer agent, Step 3a).

## The Process

### 1. Discover Phases

**DO NOT read the full phase files yet.** List them and read only the header and task markers. Use Glob to list, Read with `limit` for headers, Grep for task markers - not `ls`, `head`, `find`, or `grep`.

```
# List phase files (Glob tool)
Glob: [plan-directory]/phase_*.md

# For each file, read first 10 lines (Read tool with limit: 10)
Read: [plan-directory]/phase_01.md  limit: 10

# Get task/subcomponent structure (Grep tool)
Grep: pattern "START_TASK_|START_SUBCOMPONENT_"  path [plan-directory]/phase_01.md
```

The header includes the title (`# [Phase Title]`) and `**Goal:**` line. Extract the title for the task entry.

The grep output shows the task structure, e.g.:
```
<!-- START_TASK_1 -->
<!-- START_TASK_2 -->
<!-- START_SUBCOMPONENT_A (tasks 3-5) -->
<!-- START_TASK_3 -->
<!-- START_TASK_4 -->
<!-- START_TASK_5 -->
```

Examples of headers you might see:
- `# Document Infrastructure Implementation Plan` - Phase 1 implied
- `# Phase 4: Link Resolution` - Phase number explicit

**Check for implementation guidance:**

After discovering phases, check if `.tk-harness/implementation-plan-guidance.md` exists in the project root:

```
# Glob tool, looking for the file
Glob: [project-root]/.tk-harness/implementation-plan-guidance.md
```

If the file exists, note its **absolute path** for use during code reviews and as input when building the FP-primitives active block. If it does not exist, proceed without it. Do not pass a nonexistent path to reviewers.

**Check for test requirements:**

```
Glob: [plan-directory]/test-requirements.md
```

If it exists, note its **absolute path** for use during final review.

**Capture the base commit:**

Before any task runs, record the git HEAD as `INITIAL_BASE_SHA`. This is the BASE_SHA for the final code review.

**Create a session-isolated scratchpad directory:**

```bash
SLUG=$(basename "[plan-directory]")
SESSION_ID=$(printf '%04x%04x' $RANDOM $RANDOM)
SCRATCHPAD_DIR="/tmp/exec-${SLUG}-${SESSION_ID}"
mkdir -p "${SCRATCHPAD_DIR}"
echo "${SCRATCHPAD_DIR}"
```

This scratchpad ensures isolation when multiple execution sessions run in parallel. Pass it to code-reviewer invocations.

### 2. Create Phase-Level Task List

Use TaskCreate to create **three task entries per phase** (or TodoWrite in older Claude Code versions). Include the title from the header:

```
- [ ] Phase 1a: Read /absolute/path/to/phase_01.md - Document Infrastructure Implementation Plan
- [ ] Phase 1b: Execute tasks (stub -> test -> body per task)
- [ ] Phase 1c: Code review
- [ ] Phase 2a: Read /absolute/path/to/phase_02.md - API Integration
- [ ] Phase 2b: Execute tasks (stub -> test -> body per task)
- [ ] Phase 2c: Code review
...
```

**Why absolute paths in task entries:** After compaction, context may be summarized. The absolute path in the task entry ensures you always know exactly which file to read.

**Why include the title:** Gives visibility into what each phase covers without loading full content.

**Why "stub -> test -> body per task" in the task entry:** Reminds you (and a successor agent reading the task list after compaction) that 3b is not a single dispatch.

### 3. Execute Each Phase

For each phase, follow this cycle.

#### 3a. Read Phase File (just-in-time)

Mark "Phase Na: Read [path]" as in_progress.

Read ONLY that phase file now. Extract:
- List of tasks in this phase, in order
- Subcomponent groupings (if any)
- Working directory (absolute path)
- Language for the FP-primitives block
- Any phase-specific context

Record the current git HEAD as `PHASE_BASE_SHA`. This is the BASE_SHA for this phase's code review.

Mark "Phase Na: Read" as complete.

#### 3b. Execute All Tasks

Mark "Phase Nb: Execute tasks" as in_progress.

**Before dispatching, verify test coverage for functionality tasks:**

If a functionality task (code that does something) has no tests specified anywhere in the phase or in `test-requirements.md`:

1. Check if a subsequent task in the same phase provides tests.
2. If no tests exist anywhere for this functionality -> **STOP**.
3. This is a plan gap. Surface to user: "Task N implements [functionality] but no corresponding tests exist in the plan. This needs tests before implementation."

Do NOT implement functionality without tests. Missing tests = plan gap, not something to skip.

**Execute all tasks in sequence. For each task (or subcomponent), run the THREE-AGENT CHAIN:**

##### 3b.1. Dispatch stub-author

```
<invoke name="Task">
<parameter name="subagent_type">tk-rpie:stub-author</parameter>
<parameter name="description">Stubs for Phase X Task Y: <short desc></parameter>
<parameter name="prompt">
<fp-primitives-active>
Tier: <tier>
Language: <lang>
Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
Forbidden: throw, null, any, mutation, Date.now in core
</fp-primitives-active>

Write stubs, types, and contract docs for Task N from the phase file.

Phase file: <absolute path>
Task number: N (look for `<!-- START_TASK_N -->`)
Working directory: <absolute path>
Language: <lang>

Your job is to:
1. Read the phase file to understand context.
2. Write function/method signatures, types, ADTs, and contract docstrings.
3. Each function body must raise the language's NotImplementedError-equivalent.
4. Run the typechecker. It must pass.
5. Commit your work.
6. Report back with the commit SHA, list of stubbed symbols, and any contract decisions.

Apply tk-rpie:writing-stubs-and-docs (and any other applicable house-style skills).

If you cannot proceed (plan ambiguity, missing dependency), return BLOCKED with reason.
</parameter>
</invoke>
```

**Capture STUBS_SHA from the response.** Print the response verbatim to the user.

If response is BLOCKED: write `BLOCKED.md` in the working directory with the agent's reason and the task identifier; mark Phase Nb as blocked; surface to the user; STOP. Do not proceed to test-author.

##### 3b.2. Dispatch test-author

```
<invoke name="Task">
<parameter name="subagent_type">tk-rpie:test-author</parameter>
<parameter name="description">Tests for Phase X Task Y: <short desc></parameter>
<parameter name="prompt">
<fp-primitives-active>
Tier: <tier>
Language: <lang>
Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
Forbidden: throw, null, any, mutation, Date.now in core
</fp-primitives-active>

Write failing tests for Task N from the phase file, against the frozen stubs.

Phase file: <absolute path>
Task number: N
Working directory: <absolute path>
Language: <lang>
Stubs commit (frozen): STUBS_SHA = <sha>

Your job is to:
1. Read the phase file and any test-requirements.md present in the plan directory.
2. Read the stubs at STUBS_SHA. DO NOT EDIT THEM.
3. Write tests that exercise each contract in the stubs.
4. Run the test suite. Tests MUST fail with NotImplementedError-equivalent. They MUST NOT fail with ImportError, AttributeError, or any error indicating the stub is missing or wrong-shaped. If they fail with the wrong error, return BLOCKED identifying the stub bug.
5. Commit your work.
6. Report back with the commit SHA, list of new tests, and the failure mode you observed.

Apply tk-rpie:writing-tests-against-stubs.

If a stub is wrong (signature or types), DO NOT FIX IT. Return BLOCKED with the stub bug identified.
</parameter>
</invoke>
```

**Capture TESTS_SHA from the response.** Print the response verbatim.

If test-author reports the wrong failure mode (ImportError, AttributeError, etc.), that means the stubs are broken. STOP, surface to the user, write `BLOCKED.md`, do not proceed to body-implementor. This is the critical check that the chain catches stub bugs early.

If response is BLOCKED for any other reason: write `BLOCKED.md`, surface, STOP.

##### 3b.3. Dispatch body-implementor

```
<invoke name="Task">
<parameter name="subagent_type">tk-rpie:body-implementor</parameter>
<parameter name="description">Bodies for Phase X Task Y: <short desc></parameter>
<parameter name="prompt">
<fp-primitives-active>
Tier: <tier>
Language: <lang>
Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
Forbidden: throw, null, any, mutation, Date.now in core
</fp-primitives-active>

Implement function bodies for Task N from the phase file, against frozen stubs and frozen tests.

Phase file: <absolute path>
Task number: N
Working directory: <absolute path>
Language: <lang>
Stubs commit (frozen): STUBS_SHA = <sha>
Tests commit (frozen): TESTS_SHA = <sha>

Your job is to:
1. Read the phase file, the stubs at STUBS_SHA, and the tests at TESTS_SHA.
2. DO NOT EDIT STUB FILES OR TEST FILES.
3. Implement function bodies one at a time, transitioning each test red -> green.
4. After all bodies are written, run the full verification (/verify or equivalent: typecheck + tests + lint).
5. Commit your work (one commit per logical body, or one commit at the end - your choice).
6. Report back with final commit SHA, count of tests now passing, and verification output.

Apply tk-rpie:writing-bodies-against-tests and tk-rpie:verification-before-completion.

If a stub signature is wrong, or a test is wrong, DO NOT FIX IT. Return BLOCKED with the bug identified - escalation to the orchestrator is the correct response.
</parameter>
</invoke>
```

Print the response verbatim.

If response is BLOCKED: write `BLOCKED.md`, surface, STOP.

##### 3b.4. Move to next task

Once body-implementor reports green (all tests passing, /verify clean), move to the next task in the phase and repeat 3b.1 - 3b.3.

##### 3b.5. Subcomponents

For SUBCOMPONENTS (groups of tasks marked `<!-- START_SUBCOMPONENT_X (tasks A-B) -->`), each agent in the chain takes the WHOLE subcomponent at once. That is THREE dispatches total (one stub-author for all stubs in the subcomponent, one test-author for all tests, one body-implementor for all bodies) - NOT three per task. The commit-SHA handoff between agents works the same way.

##### 3b.6. After all tasks

After all tasks (and subcomponents) in the phase are green, mark "Phase Nb: Execute tasks" as complete.

#### 3c. Code Review for Phase

Mark "Phase Nc: Code review" as in_progress.

**MANDATORY:** Use the `requesting-code-review` skill for the review loop.

**Context to provide to code-reviewer:**

- WHAT_WAS_IMPLEMENTED: Summary of all tasks in this phase
- PLAN_OR_REQUIREMENTS: All tasks from this phase (cite the phase file path)
- BASE_SHA: PHASE_BASE_SHA (commit before phase started)
- HEAD_SHA: current commit
- IMPLEMENTATION_GUIDANCE: absolute path to `.tk-harness/implementation-plan-guidance.md` (only if it exists - omit entirely otherwise)
- SCRATCHPAD_DIR: session-isolated temp directory (created in step 1)
- The same `<fp-primitives-active>` block used for the coding agents, so the reviewer can run the FP-violation check (Step 3a in the code-reviewer agent body)

The implementation guidance file contains project-specific coding standards, testing requirements, and review criteria. When provided, the code reviewer should read it and apply those standards.

**Note:** Test-requirements validation happens at final review, not per-phase. Per-phase reviews focus on code quality, plan alignment, FP purity, and whether the phase includes tests for its functionality.

**If code reviewer returns a context-limit error:**

The phase changed too much for a single review. Chunk the review:

1. Identify the midpoint of tasks in the phase.
2. Run code review for first half of tasks (commits for tasks 1 through N/2).
3. Fix any issues found.
4. Run code review for second half of tasks (commits for tasks N/2+1 through N).
5. Fix any issues found.

**When issues are found:**

1. **Create a task for EACH issue** (survives compaction):

   ```
   TaskCreate: "Phase N fix [Critical]: <VERBATIM issue description from reviewer>"
   TaskCreate: "Phase N fix [Important]: <VERBATIM issue description from reviewer>"
   TaskCreate: "Phase N fix [Minor]: <VERBATIM issue description from reviewer>"
   ...one task per issue...
   TaskCreate: "Phase N: Re-review after fixes"
   TaskUpdate: set "Re-review" blocked by all fix tasks
   ```

   **Copy issue descriptions VERBATIM**, even if long. After compaction, the task description is all that remains - it must contain the full issue details for the bug-fixer to understand what to fix.

2. **Dispatch `bug-fixer`** with the phase file:

```
<invoke name="Task">
<parameter name="subagent_type">tk-rpie:bug-fixer</parameter>
<parameter name="description">Fixing review issues for Phase X</parameter>
<parameter name="prompt">
<fp-primitives-active>
Tier: <tier>
Language: <lang>
Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
Forbidden: throw, null, any, mutation, Date.now in core
</fp-primitives-active>

Fix issues from code review for Phase X.

Phase file: <absolute path>
Working directory: <absolute path>

Code reviewer found these issues (Critical, Important, Minor):

[verbatim list of all issues]

Your job is to:
1. Understand root cause of each issue.
2. Apply fixes systematically (Critical -> Important -> Minor).
3. Verify with full /verify (typecheck + tests + lint).
4. Commit your fixes.
5. Report back with evidence (commit SHAs, before/after for each issue).

Fix ALL issues - including every Minor issue. The goal is ZERO issues on re-review.
Minor issues are not optional.
</parameter>
</invoke>
```

3. **Mark "Fix issues" complete**, then re-review per the `requesting-code-review` skill.

4. **If re-review finds more issues**, create new fix/re-review tasks. Continue loop until zero issues OR the 3-strike cap fires.

5. **Mark "Re-review" complete** when zero issues.

**Plan execution policy (stricter than general code review):**

- ALL issues must be fixed (Critical, Important, AND Minor).
- Ignore APPROVED/BLOCKED status flags - count issues only.
- **Three-strike rule:** If the same issue (or substantially the same set of issues) persists across THREE review cycles in a row, STOP. The bug-fixer is not converging. Write `BLOCKED.md` in the working directory containing:
  - Phase identifier
  - The persistent issues
  - The three review cycle summaries
  - The bug-fixer's three attempts
  - A note that the orchestrator surrendered after 3 strikes
  Then surface to the user and exit the phase loop. Do not proceed to the next phase.

**Minor issues are NOT optional.** Do not rationalize skipping them with "they are just style issues" or "we can fix those later." The reviewer flagged them for a reason. Fix every single one.

**Exit condition:** Zero issues in all categories - including Minor.

Mark "Phase Nc: Code review" as complete.

#### 3d. Move to Next Phase

Proceed to the next phase's "Read" step. Repeat 3a-3c for each phase.

### 4. Update Project Context

After all phases complete, invoke the `tk-rpie:librarian` subagent (when available) to review changes and update CLAUDE.md / module AGENTS.md files if contracts changed.

```
<invoke name="Task">
<parameter name="subagent_type">tk-rpie:librarian</parameter>
<parameter name="description">Updating project context after implementation</parameter>
<parameter name="prompt">
Review what changed during this implementation and update CLAUDE.md / AGENTS.md files if contracts or structure changed.

Base commit: INITIAL_BASE_SHA = <sha at start of first phase>
Current HEAD: <current commit>
Working directory: <absolute path>

Your job is to:
1. Diff against base to see what changed.
2. Identify contract / API / module-structure changes.
3. Update affected CLAUDE.md / AGENTS.md files.
4. Commit documentation updates.

Report back with what was updated (or that no updates were needed).
</parameter>
</invoke>
```

**If librarian reports updates:** Print the response, review the changes, then proceed to final review.
**If librarian reports no updates needed:** Print the response, then proceed to final review.
**If librarian subagent is unavailable:** Skip this entire step. Say aloud that you are skipping it because the `tk-rpie:librarian` agent is not available.

### 5. Final Review Sequence

After all phases and the librarian step complete, run a sequence of specialized agents:

```
Final Code Review -> Test Analysis (Coverage + Plan)
```

#### 5a. Final Code Review

Use the `requesting-code-review` skill for final code review.

**Context to provide:**

- WHAT_WAS_IMPLEMENTED: Summary of all phases completed
- PLAN_OR_REQUIREMENTS: Reference to the full implementation plan directory
- BASE_SHA: INITIAL_BASE_SHA (commit before first phase started)
- HEAD_SHA: current commit
- IMPLEMENTATION_GUIDANCE: absolute path (if exists)
- SCRATCHPAD_DIR: session-isolated temp directory
- The `<fp-primitives-active>` block (project-wide tier/language)
- AC_COVERAGE_CHECK: "Verify all acceptance criteria (using scoped format `{slug}.AC*`) from the design plan are covered by at least one phase. Flag any ACs not addressed."

Continue the review loop until zero issues remain. Same 3-strike cap as 3c. If 3 strikes hit, write `BLOCKED.md` and stop.

#### 5b. Test Analysis

**Only after final code review passes with zero issues.**

**Skip this step if test-requirements.md does not exist.**

The test-analyst agent performs two sequential tasks with shared analysis:

1. Validate coverage against acceptance criteria.
2. Generate human test plan (only if coverage passes).

Dispatch the test-analyst agent:

```
<invoke name="Task">
<parameter name="subagent_type">tk-rpie:test-analyst</parameter>
<parameter name="description">Analyzing test coverage and generating test plan</parameter>
<parameter name="prompt">
Analyze test implementation against acceptance criteria.

TEST_REQUIREMENTS_PATH: <absolute path to test-requirements.md>
WORKING_DIRECTORY: <project root>
BASE_SHA: INITIAL_BASE_SHA = <sha>
HEAD_SHA: <current commit>

Phase 1: Validate that automated tests exist for all acceptance criteria.
Phase 2: If coverage passes, generate human test plan using your analysis.

Return coverage validation result. If PASS, include the human test plan.
</parameter>
</invoke>
```

Print the response verbatim.

**If analyst returns coverage FAIL:**

1. Dispatch bug-fixer to add missing tests:

   ```
   <invoke name="Task">
   <parameter name="subagent_type">tk-rpie:bug-fixer</parameter>
   <parameter name="description">Adding missing test coverage</parameter>
   <parameter name="prompt">
   <fp-primitives-active>
   Tier: <tier>
   Language: <lang>
   Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
   Forbidden: throw, null, any, mutation, Date.now in core
   </fp-primitives-active>

   Add missing tests identified by the test analyst.

   Missing coverage:
   [verbatim list from analyst output]

   For each missing test:
   1. Read the acceptance criterion carefully.
   2. Create the test file at the expected location.
   3. Write tests that verify the criterion's actual behavior - not just code that passes, but code that would fail if the criterion were not met.
   4. Run tests to confirm they pass.
   5. Commit the new tests.

   Working directory: <absolute path>
   </parameter>
   </invoke>
   ```

2. Re-run test-analyst.
3. Repeat until coverage PASS or three attempts fail. On 3 strikes, write `BLOCKED.md` and escalate to the user.

**If analyst returns coverage PASS:**

The response will include the human test plan. Extract the "Human Test Plan" section.

**Write the test plan:**

```bash
mkdir -p docs/test-plans
# Filename uses the implementation plan directory name
# e.g., impl plan dir: docs/implementation-plans/2025-01-24-oauth/
#       test plan:     docs/test-plans/2025-01-24-oauth.md
```

Write the test plan content to `docs/test-plans/[impl-plan-dir-name].md`, then commit:

```bash
git add docs/test-plans/[impl-plan-dir-name].md
git commit -m "docs: add test plan for [feature name]"
```

Announce: "Human test plan written to `docs/test-plans/[impl-plan-dir-name].md`"

### 6. Complete Development

After final review and test analysis pass:

- Provide a report to the human operator. For each phase:
  - How many tasks were implemented (and whether they used the stub/test/body chain or were single-dispatch trivial work)
  - How many code-review cycles were needed
  - Any compromises made (there should be NO compromises, but if any were made, list them):
    - "I could not run the integration tests, so I continued on"
    - "I could not generate the client because the dev environment was down"
    - These are PARTIAL FAILURE CASES and you must explain to the user what they must do now.
  - Were any code-review issues left outstanding at any point?
  - Did any task hit a per-task BLOCKED that you resolved interactively, and how?

- Activate the `finishing-a-development-branch` skill. DO NOT activate it before this point.

## Example Workflow

```
You: I am using the `executing-an-implementation-plan` skill.

[Glob phases: phase_01.md, phase_02.md, phase_03.md]
[Read first 10 lines of each to get titles]
[Glob .tk-harness/implementation-plan-guidance.md - exists]
[Glob test-requirements.md - exists]
[Record INITIAL_BASE_SHA = abc123]
[mkdir scratchpad /tmp/exec-2025-01-24-oauth-7f3a4b91]

[Create tasks with TaskCreate:]
- [ ] Phase 1a: Read /path/to/phase_01.md - Project Setup
- [ ] Phase 1b: Execute tasks (stub -> test -> body per task)
- [ ] Phase 1c: Code review
- [ ] Phase 2a: Read /path/to/phase_02.md - Token Service
- [ ] Phase 2b: Execute tasks (stub -> test -> body per task)
- [ ] Phase 2c: Code review
- [ ] Phase 3a: Read /path/to/phase_03.md - API Middleware
- [ ] Phase 3b: Execute tasks (stub -> test -> body per task)
- [ ] Phase 3c: Code review

--- Phase 1 ---

[Mark 1a in_progress, read phase_01.md]
-> Contains 2 tasks. PHASE_BASE_SHA = abc123.

[Mark 1a complete, 1b in_progress]

--- Task 1 ---
[Dispatch stub-author with FP block]
-> STUBS_SHA = def456. Stubbed package.json, tsconfig.json schema types.
[Print stub-author response]
[Dispatch test-author with STUBS_SHA = def456]
-> TESTS_SHA = ghi789. Tests fail with NotImplementedError, correct mode.
[Print test-author response]
[Dispatch body-implementor with STUBS_SHA + TESTS_SHA]
-> BODIES_SHA = jkl012. /verify clean, 8 tests green.
[Print body-implementor response]

--- Task 2 ---
[stub -> test -> body chain again, three dispatches]

[Mark 1b complete, 1c in_progress]

[Use requesting-code-review skill for phase 1, FP block + IMPLEMENTATION_GUIDANCE + SCRATCHPAD_DIR]
-> Zero issues.

[Mark 1c complete]

--- Phase 2 ---

[Mark 2a in_progress, read phase_02.md]
-> Contains 3 tasks. PHASE_BASE_SHA updated.

[Mark 2a complete, 2b in_progress]

--- Task 1 ---
[stub -> test -> body chain]
[stub-author returns OK; test-author reports tests fail with ImportError]
-> WRONG FAILURE MODE. Stub bug. Write BLOCKED.md, surface to user, STOP.
[User intervenes; resumes after fixing stub authoring]

[Resume; redo Task 1 chain from stub-author. Now correct.]

--- Task 2, Task 3 ---
[chains run cleanly]

[Mark 2b complete, 2c in_progress]

[Use requesting-code-review skill for phase 2]
-> Important: 1, Minor: 1
-> Dispatch bug-fixer with FP block, re-review
-> Zero issues.

[Mark 2c complete]

--- Phase 3 ---
[Similar pattern.]

--- Finalize ---

[Invoke tk-rpie:librarian]
-> Updated CLAUDE.md.

[Use requesting-code-review skill for final review]
-> All requirements met.

[Dispatch tk-rpie:test-analyst]
-> Coverage PASS, human test plan included.
[Write docs/test-plans/2025-01-24-oauth.md, commit]

[Report to user. Activate finishing-a-development-branch.]
```

## Common Rationalizations - STOP

| Excuse | Reality |
|--------|---------|
| "I will read all phases upfront to understand the full picture" | No. Read one phase at a time. Context limits are real. |
| "I will skip the read step, I remember what is in the file" | No. Always read just-in-time. Context may have been compacted. |
| "I will review after each task to catch issues early" | No. Review once per phase. Task-level review wastes context. |
| "I will combine stub+test+body in one dispatch to save context" | No. The split is the design point. The agent boundary is what makes the red->green honest. |
| "I will skip the per-task PRINT to keep things tidy" | No. Human transparency rule. Print every subagent response verbatim. |
| "test-author saw an ImportError, that is red, move on" | No. Wrong failure mode means the stub is broken. STOP. |
| "body-implementor edited the test file to make it pass" | No. body-implementor must NOT edit tests or stubs. Escalate via BLOCKED instead. |
| "stub-author can write a quick body, just to make tests pass faster" | No. Stub bodies must raise NotImplementedError-equivalent only. |
| "Context error on review, I will skip the review" | No. Chunk the review into halves. Never skip review. |
| "Minor issues can wait" | No. Fix ALL issues including Minor. |
| "Bug-fixer keeps missing the same issue, but I will give it one more shot" | After 3 strikes, STOP. Write BLOCKED.md. Get the human. |
| "I will skip the FP-primitives block on this dispatch, the agent knows" | No. The dispatch-time priming is mandatory for every coding-agent dispatch. |
| "I will assume the plan path since there is only one in docs/" | No. Ask via AskUserQuestion. Never guess. |

---
Provenance: ported from ed3d-plugins/ed3d-plan-and-execute (CC-BY-SA-4.0); ultimately derived from obra/superpowers (MIT). REWRITTEN for tk-harness 3-agent stub/test/body chain.
