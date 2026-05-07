# tk-hooks

Cross-cutting hooks for the tk-harness marketplace. Bundles three independent
hook scripts under one plugin so a single install enables all of them.

## What this plugin does

### security-hardening (PreToolUse on Bash, PostToolUse on Write/Edit)

`check-bash-secrets.py` inspects every Bash command before execution. It denies
high-confidence secret leaks (echo of `$TOKEN`-style vars, `printenv SECRET`,
`${#SECRET}` length probes, polyglot `os.environ['SECRET']` readers, `declare -p
SECRET`) and forces an `ask` prompt for medium-confidence patterns
(`env|grep` without `-q`, `cat .env`, `source` of secret files, tokens in git
URLs or curl query strings, curl exfiltration of secret files).
`check-sensitive-file.py` runs after Write/Edit; if the path looks secret-bearing
(.env, .pem, .key, credentials, etc.) it reminds the operator to verify
gitignore status and 600 permissions.

### claudemd-reminder (PostToolUse on Bash)

`git-command-reminder.py` watches for commit-relevant Bash commands
(`git commit`, `git status`, substantive `git log`). When triggered, it scans
the last few commits' diffs and the working-tree dirty list for context-anchor
files. tk-harness uses **both** `CLAUDE.md` and `AGENTS.md` (root and per
module), so the hook treats either basename as an anchor. If anchors have
recently changed but are not staged for the in-flight commit, the hook injects
a reminder to refresh them before committing.

### skill-reinforcement (UserPromptSubmit)

`hook-reminder.sh` injects a short additional-context block on every user prompt
reminding the assistant to invoke any applicable skill via the Skill tool before
responding. The script does not hardcode skill names; the harness's skill
catalog drives applicability. (No tk-harness rename was needed because the
ed3d source script is itself name-agnostic.)

## Install / enable

This plugin lives in the `tk-harness` marketplace and is enabled by adding
`tk-hooks` to your `~/.claude/settings.json` `enabledPlugins`. Once enabled,
`hooks/hooks.json` registers all three event handlers automatically. No
additional configuration is required.

The Python scripts target Python 3 (`python3` on `$PATH`); the Bash script uses
`/usr/bin/env bash`. POSIX coreutils are sufficient.

## Customization

Environment variables consumed by `claudemd-reminder/git-command-reminder.py`:

- `TK_CLAUDEMD_REMINDER_LOOKBACK` - number of commits to scan for prior anchor
  edits (default: 5).
- `TK_CLAUDEMD_REMINDER_DISABLE` - set to `1` to silence the reminder.

The other two hooks have no runtime configuration; behavior is controlled by
editing the script bodies (`SECRET_WORDS` / `SECRET_FILE_PATTERNS` in
`security-hardening/`, the additional-context string in
`skill-reinforcement/hook-reminder.sh`).

## Provenance

All three hooks ported from
[ed3dai/ed3d-plugins](https://github.com/ed3dai/ed3d-plugins) under
CC-BY-SA-4.0:

- `security-hardening/` from `ed3d-hook-security-hardening` (verbatim port of
  `check-bash-secrets.py` and `check-sensitive-file.py`; non-ASCII em-dashes
  in comments normalized to `-`).
- `claudemd-reminder/` from `ed3d-hook-claudemd-reminder`. Adapted: also
  handles `AGENTS.md`, scans recent-commit diffs and unstaged dirty paths
  rather than firing on `git status`/`git log` text alone, and triggers on
  `git commit` directly.
- `skill-reinforcement/` from `ed3d-hook-skill-reinforcement` (verbatim).

Each ported script carries a `# Provenance:` header. License: CC-BY-SA-4.0
(see `LICENSE`).
