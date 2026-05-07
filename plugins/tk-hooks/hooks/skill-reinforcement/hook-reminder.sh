#!/usr/bin/env bash
# Provenance: ported from ed3d-plugins/ed3d-hook-skill-reinforcement (CC-BY-SA-4.0).

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nBefore responding to this prompt, consider whether you have any skills that apply. Your available skills are listed in your system context. If ANY skill applies to this task and has not been activated in this session, you MUST use the Skill tool to activate it. Do NOT skip this step.\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
