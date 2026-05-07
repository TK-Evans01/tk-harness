# tk-hooks

Cross-cutting hooks for the tk-harness marketplace.

Status: M0 skeleton — manifest only.

## Planned Hooks

### `security-hardening` (PreToolUse + PostToolUse)
Detects common secret leak patterns (env values, API keys, tokens) in tool inputs/outputs. Blocks or warns. Ported from ed3d-hook-security-hardening.

### `claudemd-reminder` (PostToolUse)
After staging or commit-related Bash calls, reminds to update `CLAUDE.md` / module `AGENTS.md` when contracts change. Ported from ed3d-hook-claudemd-reminder.

### `skill-reinforcement` (UserPromptSubmit)
Lightweight prompt reinforcement to ensure skills get invoked when relevant. Ported from ed3d-hook-skill-reinforcement.

## Provenance

All three hooks ported from [ed3dai/ed3d-plugins](https://github.com/ed3dai/ed3d-plugins) (CC-BY-SA-4.0). Will be adapted to reference tk-harness skill names where applicable.
