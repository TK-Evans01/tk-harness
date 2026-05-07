#!/bin/sh
# edit-validation.sh -- PostToolUse hook for Edit and Write.
#
# Reads the Claude Code hook event JSON from stdin, extracts the
# target file path, and runs an extension-appropriate syntactic probe.
# If the probe reports a syntax error, emit a hook-protocol JSON
# response that blocks the edit and exit non-zero. Otherwise, allow.
#
# This hook is intentionally cheap: a parser-level check only. The
# heavier semantic analysis (typecheck, lint, purity, tests) lives
# in the /verify slash command.
#
# POSIX shell only. No bashisms (target: dash).

set -u

SELF_DIR=$(dirname "$0")
# shellcheck source=./edit-validation/parsers.sh
. "$SELF_DIR/edit-validation/parsers.sh"

# ---------- read event ----------

EVENT=$(cat)

# Extract tool_input.file_path. Prefer python3 (json stdlib) since
# we cannot rely on jq being installed everywhere. Fall back to a
# crude grep-based extractor only if python3 is missing.
extract_path() {
    if have python3; then
        printf '%s' "$EVENT" | python3 - <<'PY'
import json, sys
try:
    e = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = e.get("tool_input") or {}
p = ti.get("file_path") or ti.get("filePath") or ""
sys.stdout.write(p)
PY
        return
    fi
    # Fallback: very small regex. Not robust against escaped quotes
    # in paths, but file paths in practice do not contain quotes.
    printf '%s' "$EVENT" | \
        sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | \
        head -n 1
}

FILE_PATH=$(extract_path)

# ---------- response helpers ----------

emit_pass() {
    printf '{"continue": true}\n'
    exit 0
}

emit_fail() {
    # emit_fail <reason single line>
    reason=$1
    # Escape backslashes and double quotes for JSON.
    esc=$(printf '%s' "$reason" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
    printf '{"continue": false, "stopReason": "syntactically broken: %s"}\n' \
        "$esc"
    exit 1
}

# ---------- guard rails ----------

# No path -> nothing to validate. Allow.
if [ -z "$FILE_PATH" ]; then
    emit_pass
fi

# File missing -> probably a Write that targeted a deleted directory
# or some race; let the caller see the real error rather than masking
# it with our own.
if [ ! -f "$FILE_PATH" ]; then
    emit_pass
fi

# ---------- run probe ----------

# Capture the probe's stderr so we can use the first line as the
# rejection reason.
PROBE_ERR=$(mktemp 2>/dev/null || printf '/tmp/edit-validation.%s' "$$")
trap 'rm -f "$PROBE_ERR"' EXIT INT TERM

dispatch_probe "$FILE_PATH" 2>"$PROBE_ERR"
RC=$?

if [ "$RC" -eq 0 ]; then
    emit_pass
fi

FIRST_LINE=$(head -n 1 "$PROBE_ERR" 2>/dev/null)
if [ -z "$FIRST_LINE" ]; then
    FIRST_LINE="probe exited with status $RC"
fi

emit_fail "$FIRST_LINE"
