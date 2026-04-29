#!/usr/bin/env bash
set -euo pipefail

# Auto-refresh prompt metadata after Edit/Write on a prompt file.
# Receives JSON on stdin from the PostToolUse hook event.

INPUT="$(cat)"

# Extract file path from tool input
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')"
[ -z "$FILE_PATH" ] && exit 0

# Only act on files inside the prompt library data directory
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/prompt-library}"
PROMPTS_DIR="$DATA_DIR/prompts"

case "$FILE_PATH" in
  "$PROMPTS_DIR"/*.md) ;;
  *) exit 0 ;;
esac

# Extract slug from filename: /path/to/prompts/my-prompt.md → my-prompt
SLUG="$(basename "$FILE_PATH" .md)"

# Run refresh via prompt-lib
PROMPT_LIB="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}/bin/prompt-lib"
[ -x "$PROMPT_LIB" ] && "$PROMPT_LIB" refresh "$SLUG" >/dev/null 2>&1 || true

exit 0
