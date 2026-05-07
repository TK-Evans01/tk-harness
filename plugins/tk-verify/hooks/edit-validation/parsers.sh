#!/bin/sh
# parsers.sh -- per-extension syntactic probes for edit-validation.
#
# Each probe function takes one argument: a path to the file just
# edited or written. It must:
#   - print nothing on success and return 0;
#   - print a single-line diagnostic to stderr and return non-zero
#     on a syntactic failure;
#   - return 0 (warn-and-allow) when the underlying probe tool is
#     not installed -- we do not want a missing tsc to block writes.
#
# POSIX shell only. No bashisms.

# ---------- helpers ----------

have() {
    # have <cmd> -- 0 if cmd is on PATH.
    command -v "$1" >/dev/null 2>&1
}

warn_missing() {
    # warn_missing <tool> <ext>
    # Print to stderr and return 0 so the caller allows the write.
    printf 'edit-validation: %s not found, skipping %s probe\n' "$1" "$2" >&2
    return 0
}

# ---------- probes ----------

probe_typescript() {
    # .ts .tsx .mts .cts -- prefer tsc; fall back to allow.
    file=$1
    if have tsc; then
        tsc --noEmit --allowJs --skipLibCheck "$file" 2>&1 1>/dev/null
        return $?
    fi
    if have npx; then
        # Try project-local tsc without triggering an install.
        npx --no-install tsc --noEmit --allowJs --skipLibCheck "$file" \
            2>&1 1>/dev/null
        rc=$?
        # npx exits 1 when the package is not installed; we cannot
        # distinguish that from a real tsc failure here. To stay
        # conservative (warn-and-allow), only treat rc==2 as failure
        # since tsc uses 1 for diagnostics and 2 for syntax errors.
        if [ "$rc" -eq 2 ]; then
            return 2
        fi
        return 0
    fi
    warn_missing tsc ts
}

probe_javascript() {
    # .js .cjs .mjs -- node --check is fast and reliable.
    file=$1
    if have node; then
        node --check "$file" 2>&1 1>/dev/null
        return $?
    fi
    warn_missing node js
}

probe_python() {
    file=$1
    if have python3; then
        python3 -m py_compile "$file" 2>&1 1>/dev/null
        return $?
    fi
    if have python; then
        python -m py_compile "$file" 2>&1 1>/dev/null
        return $?
    fi
    warn_missing python3 py
}

probe_rust() {
    # Single-file rustc check. Many real .rs files reference crate
    # siblings or external crates and will fail to compile in
    # isolation -- we treat any error other than a clear parse error
    # as warn-and-allow. The /verify gate's `cargo check` is the real
    # backstop here.
    file=$1
    if ! have rustc; then
        warn_missing rustc rs
        return 0
    fi
    out=$(rustc --emit=metadata --crate-type lib -o /dev/null \
        --edition 2021 "$file" 2>&1 1>/dev/null)
    rc=$?
    if [ "$rc" -eq 0 ]; then
        return 0
    fi
    # Heuristic: only block on parse errors. Resolution errors (E0432,
    # E0433, "unresolved import", "can't find crate") mean the file
    # references external state we cannot see in isolation.
    case $out in
        *"expected"*|*"unexpected"*|*"unclosed"*|*"mismatched"*)
            printf '%s\n' "$out" >&2
            return 1
            ;;
    esac
    return 0
}

probe_json() {
    file=$1
    if have python3; then
        python3 -c 'import json,sys; json.load(open(sys.argv[1]))' \
            "$file" 2>&1 1>/dev/null
        return $?
    fi
    warn_missing python3 json
}

probe_toml() {
    # Python 3.11+ has tomllib in stdlib.
    file=$1
    if have python3; then
        python3 - "$file" <<'PY' 2>&1 1>/dev/null
import sys
try:
    import tomllib
except ImportError:
    sys.exit(0)  # warn-and-allow on older Python
with open(sys.argv[1], "rb") as fh:
    tomllib.load(fh)
PY
        return $?
    fi
    warn_missing python3 toml
}

probe_yaml() {
    file=$1
    if have python3; then
        python3 - "$file" <<'PY' 2>&1 1>/dev/null
import sys
try:
    import yaml
except ImportError:
    sys.exit(0)
yaml.safe_load(open(sys.argv[1]))
PY
        return $?
    fi
    warn_missing python3 yaml
}

# ---------- dispatch ----------

dispatch_probe() {
    # dispatch_probe <file>
    # Picks a probe by extension and runs it. Returns the probe's rc.
    file=$1
    case $file in
        *.ts|*.tsx|*.mts|*.cts)   probe_typescript "$file" ;;
        *.js|*.cjs|*.mjs|*.jsx)   probe_javascript "$file" ;;
        *.py)                     probe_python "$file" ;;
        *.rs)                     probe_rust "$file" ;;
        *.json)                   probe_json "$file" ;;
        *.toml)                   probe_toml "$file" ;;
        *.yml|*.yaml)             probe_yaml "$file" ;;
        *)                        return 0 ;;
    esac
}
