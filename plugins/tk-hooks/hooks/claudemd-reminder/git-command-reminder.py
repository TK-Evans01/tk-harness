#!/usr/bin/env python3
# Provenance: ported from ed3d-plugins/ed3d-hook-claudemd-reminder (CC-BY-SA-4.0).
"""
PostToolUse hook that reminds the operator to refresh context-anchor files
(CLAUDE.md, AGENTS.md) before committing.

Triggers on commit-related Bash commands (git commit, git status, git log).
Fires only if a context-anchor file has changed in the last N commits' diff
but is not currently staged for the new commit.

Environment variables:
  TK_CLAUDEMD_REMINDER_LOOKBACK   number of commits to scan (default: 5)
  TK_CLAUDEMD_REMINDER_DISABLE    set to "1" to disable the reminder
"""
import json
import os
import re
import subprocess
import sys

ANCHOR_NAMES = ("CLAUDE.md", "AGENTS.md")
DEFAULT_LOOKBACK = 5


def is_commit_related(command: str) -> bool:
    """Return True if the bash command is commit-relevant."""
    # git commit (any flags), git status, git log (substantive)
    if re.search(r"\bgit\s+commit\b", command):
        return True
    if re.match(r"^\s*git\s+status\b", command):
        return True
    # match git log unless it's a quick one-liner like `git log --oneline -3`
    if re.match(r"^\s*git\s+log\b", command):
        if not re.match(r"^\s*git\s+log\s+--oneline\s+-\d+\s*$", command):
            return True
    return False


def run_git(args: list[str]) -> str:
    """Run a git command and return stdout, or empty string on failure."""
    try:
        result = subprocess.run(
            ["git", *args],
            capture_output=True,
            text=True,
            timeout=3,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return ""
    if result.returncode != 0:
        return ""
    return result.stdout


def is_anchor_path(path: str) -> bool:
    """Return True if the path's basename is a context-anchor file."""
    base = path.rsplit("/", 1)[-1]
    return base in ANCHOR_NAMES


def anchors_in_recent_commits(lookback: int) -> set[str]:
    """Anchor files touched in the last N commits."""
    output = run_git(["log", f"-{lookback}", "--name-only", "--pretty=format:"])
    if not output:
        return set()
    return {line.strip() for line in output.splitlines() if is_anchor_path(line.strip())}


def staged_paths() -> set[str]:
    """Paths currently staged for commit."""
    output = run_git(["diff", "--cached", "--name-only"])
    if not output:
        return set()
    return {line.strip() for line in output.splitlines() if line.strip()}


def unstaged_anchor_changes() -> set[str]:
    """Anchor paths with unstaged working-tree changes."""
    output = run_git(["diff", "--name-only"])
    if not output:
        return set()
    return {line.strip() for line in output.splitlines() if is_anchor_path(line.strip())}


def main():
    if os.environ.get("TK_CLAUDEMD_REMINDER_DISABLE") == "1":
        sys.exit(0)

    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    if input_data.get("tool_name") != "Bash":
        sys.exit(0)

    command = input_data.get("tool_input", {}).get("command", "")
    if not isinstance(command, str) or not is_commit_related(command):
        sys.exit(0)

    try:
        lookback = int(os.environ.get("TK_CLAUDEMD_REMINDER_LOOKBACK", DEFAULT_LOOKBACK))
    except ValueError:
        lookback = DEFAULT_LOOKBACK

    recent_anchors = anchors_in_recent_commits(lookback)
    unstaged_anchors = unstaged_anchor_changes()
    staged = staged_paths()

    # Anchor candidates: previously touched in lookback OR currently dirty,
    # but NOT already staged for the in-flight commit.
    candidates = (recent_anchors | unstaged_anchors) - staged

    if not candidates:
        sys.exit(0)

    sample = ", ".join(sorted(candidates)[:5])
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": (
                f"Reminder: context-anchor files have changed recently or are dirty "
                f"but are not staged for the next commit ({sample}). "
                f"If this commit changes contracts, APIs, or domain structure, "
                f"refresh the relevant CLAUDE.md / AGENTS.md before committing."
            )
        }
    }
    print(json.dumps(output))
    sys.exit(0)


if __name__ == "__main__":
    main()
