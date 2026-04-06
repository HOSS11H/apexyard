#!/bin/bash
# Blocks: git add -A, git add ., git add --all
# Rationale: these commands stage every modified file in the working tree,
# including unintended ones (.env, credentials, generated artifacts, scratch
# files). Always add specific files by name.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

if echo "$COMMAND" | grep -qE '\bgit\s+add\s+(-A|--all|\.)(\s|$)'; then
  echo "BLOCKED: Never use 'git add -A', 'git add --all', or 'git add .' — always add specific files to avoid committing unrelated changes." >&2
  exit 2
fi

exit 0
