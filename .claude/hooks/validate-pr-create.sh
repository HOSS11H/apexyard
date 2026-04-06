#!/bin/bash
# Validates PR creation:
# - PR title matches format: type(TICKET): description
# - PR body contains a Glossary section
# - Branch has a ticket ID
#
# Customize the ticket pattern below if your team uses a different scheme.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check on gh pr create
if ! echo "$COMMAND" | grep -qE '\bgh\s+pr\s+create\b'; then
  exit 0
fi

ERRORS=""

# Extract --title value (macOS-compatible, no grep -P)
TITLE=$(echo "$COMMAND" | sed -n 's/.*--title[[:space:]]*["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/p' | head -1)
if [ -z "$TITLE" ]; then
  TITLE=$(echo "$COMMAND" | sed -n 's/.*--title[[:space:]]*\([^[:space:]]*\).*/\1/p' | head -1)
fi

# Validate PR title format if we can extract it
# Accepts: type(<UPPERCASE-PREFIX>-<digits>): … or type(#<digits>): …
if [ -n "$TITLE" ]; then
  if ! echo "$TITLE" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)\(([A-Z]+-[0-9]+|#[0-9]+)\):'; then
    ERRORS="${ERRORS}PR title '$TITLE' doesn't match format: type(TICKET-ID): description\n"
  fi
fi

# Check PR body for Glossary section
if echo "$COMMAND" | grep -q '\-\-body'; then
  if ! echo "$COMMAND" | grep -qiE '##\s*(Glossary|glossary)'; then
    ERRORS="${ERRORS}PR body missing required '## Glossary' section.\n"
  fi
fi

# Validate branch name has ticket ID
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$CURRENT_BRANCH" ] && [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
  if ! echo "$CURRENT_BRANCH" | grep -qE '[A-Z]+-[0-9]+|GH-[0-9]+|#[0-9]+'; then
    ERRORS="${ERRORS}Branch '$CURRENT_BRANCH' missing ticket ID.\n"
  fi
fi

if [ -n "$ERRORS" ]; then
  echo "PR VALIDATION WARNINGS:" >&2
  printf "$ERRORS" >&2
  # Warning only, not blocking — PR creation has valid edge cases
fi

exit 0
