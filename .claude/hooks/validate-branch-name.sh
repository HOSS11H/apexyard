#!/bin/bash
# Validates branch naming convention before push.
# Format: {type}/{TICKET-ID}-{description}
#
# Accepts any uppercase project prefix (e.g. ABC-123, ENG-45) or GitHub-style
# issue references (GH-12, #12). Customize the regex below if your team uses
# a different ticket scheme.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check on git push
if ! echo "$COMMAND" | grep -qE '\bgit\s+push\b'; then
  exit 0
fi

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)

# Allow trunk and shared integration branches
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ] || [ "$CURRENT_BRANCH" = "develop" ]; then
  exit 0
fi

# Validate: type/<TICKET>-<description>
#   <TICKET> = uppercase prefix + dash + digits  OR  GH-<digits>  OR  #<digits>
if ! echo "$CURRENT_BRANCH" | grep -qE '^(feature|fix|refactor|chore|docs|test|spike|ci|build|perf)/([A-Z]+-[0-9]+|GH-[0-9]+|#[0-9]+)-'; then
  echo "WARNING: Branch '$CURRENT_BRANCH' doesn't follow naming convention: {type}/{TICKET-ID}-{description}" >&2
  echo "Examples: feature/ABC-123-add-auth, fix/GH-45-login-bug, docs/ENG-99-update-readme" >&2
  # Warning only — does not block
fi

exit 0
