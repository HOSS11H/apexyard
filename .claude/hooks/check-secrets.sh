#!/bin/bash
# Scans staged files for hardcoded secrets before git commit.
# Blocks the commit if potential secrets are detected in the diff.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check on git commit
if ! echo "$COMMAND" | grep -qE '\bgit\s+commit\b'; then
  exit 0
fi

# Check staged files for secret patterns. macOS-compatible regex.
SECRETS_FOUND=$(git diff --cached --diff-filter=ACMR -U0 2>/dev/null | grep -iE "(api[_-]?key|api[_-]?secret|password|passwd|secret[_-]?key|access[_-]?token|private[_-]?key|client[_-]?secret)[[:space:]]*[:=][[:space:]]*[\"'][^\"']{8,}" | grep -v '^\-' | head -5)

if [ -n "$SECRETS_FOUND" ]; then
  echo "BLOCKED: Potential hardcoded secrets detected in staged files:" >&2
  echo "$SECRETS_FOUND" >&2
  echo "" >&2
  echo "Use environment variables instead. If these are false positives, review and proceed." >&2
  exit 2
fi

exit 0
