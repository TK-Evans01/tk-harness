#!/usr/bin/env bash
# tk-house-style: advisory visibility audit.
#
# Greps for `pub ` declarations outside `lib.rs` / `mod.rs` and reports
# them. Re-exports through `mod.rs` are the conventional Rust way to
# control a crate's surface; scattered `pub` in deep submodule files is
# usually accidental over-exposure.
#
# This script is ADVISORY — it always exits 0. /verify surfaces the
# output but does not fail the run on findings.

set -u

ROOT="${1:-.}"

if ! command -v rg >/dev/null 2>&1; then
    GREP_BIN="grep"
    GREP_ARGS=(-RIn --include='*.rs')
else
    GREP_BIN="rg"
    GREP_ARGS=(-n --type rust)
fi

# Match `pub ` and `pub(crate) `, but not `pub(super)` (already scoped),
# `pub use` (re-exports are fine), `// pub`, or string literals
# containing "pub".
PATTERN='^[[:space:]]*pub(\([^)]*\))?[[:space:]]+(fn|struct|enum|trait|type|const|static|mod|union)\b'

echo "tk-house-style :: visibility audit"
echo "root: $ROOT"
echo "policy: pub declarations should live in lib.rs / mod.rs"
echo "---"

# shellcheck disable=SC2068
HITS=$(
    $GREP_BIN ${GREP_ARGS[@]} -E "$PATTERN" "$ROOT" 2>/dev/null \
    | grep -Ev '/(lib|mod)\.rs:' \
    | grep -Ev '/(target|node_modules|\.git)/'
)

if [ -z "$HITS" ]; then
    echo "ok: no stray pub declarations found."
    exit 0
fi

COUNT=$(printf '%s\n' "$HITS" | wc -l | tr -d ' ')
echo "advisory: $COUNT pub declaration(s) outside lib.rs / mod.rs:"
printf '%s\n' "$HITS"
echo "---"
echo "(advisory only — exit 0)"
exit 0
