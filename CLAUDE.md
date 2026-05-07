# tk-harness Conventions

Repo-wide conventions for plugin authoring in this marketplace.

## Task Invocations Use XML Syntax

When documenting `Task` tool invocations in skills or agent prompts, use XML-style blocks:

```
<invoke name="Task">
<parameter name="subagent_type">tk-foundation:sonnet-general</parameter>
<parameter name="description">Brief description of what the subagent does</parameter>
<parameter name="prompt">
The prompt content goes here.

Can be multiple lines.
</parameter>
</invoke>
```

This format keeps the model on-rails better than fenced code blocks with plain prose. Adopted from ed3d-plugins.

**Do not** write Task invocations as prose like "Use the Task tool with subagent_type X and prompt Y". Use the XML block.

## Version Sync Discipline

When updating a plugin's version in its `.claude-plugin/plugin.json`, you must also:

1. Update the corresponding version in `.claude-plugin/marketplace.json` at repo root
2. Add a changelog entry to `CHANGELOG.md` at repo root

Changelog entry format (top of file, after `# Changelog` heading):

```markdown
## [plugin-name] [version]

Brief description of the release.

**New:**
- New features

**Changed:**
- Modifications to existing behavior

**Fixed:**
- Bug fixes
```

Only include sections that apply.

## FP-Primitives Active Block

Subagents that touch code are dispatched with a `<fp-primitives-active>` header in their prompt. Skill content carries the deep glossary; the dispatch block is the dispatch-time priming layer. Format:

```
<fp-primitives-active>
Tier: 2 (nearly-pure)
Language: <lang>
Required: Result<T,E>, Option<T>, Readonly<>, discriminated unions, smart ctors
Forbidden: throw, null, any, mutation, Date.now in core
</fp-primitives-active>
```

See `plugins/tk-house-style/skills/nearly-pure-functional/` (M3) for full glossary.

## Subagent Model Defaults

| Role               | Model  |
|--------------------|--------|
| code-reviewer      | opus   |
| (everything else)  | sonnet |

Override only with justification in agent frontmatter comment.

## Skill Frontmatter

Two fields:

```yaml
---
name: skill-name-with-hyphens
description: Use when [trigger] - [what it does, third person]
---
```

Optional: `user-invocable: false` for internal-only skills.

## Agent Frontmatter

```yaml
---
name: agent-name
description: One-line summary of when to dispatch this agent.
model: sonnet
color: cyan
tools: Read, Edit, Write, Bash, Grep, Glob, Skill
---
```

Agent body should start with a "Mandatory First Actions" section listing skills to invoke before any work.

## Encoding

All `.md` files: ASCII only. Use `->` not arrow chars, straight quotes, plain hyphens. ed3d burned on this.

## Per-Plugin LICENSE

Plugins port code from `obra/superpowers` (MIT) and `ed3d-plugins` (CC-BY-SA-4.0). Mark provenance per file or per plugin LICENSE. Default for new content: CC-BY-SA-4.0.
