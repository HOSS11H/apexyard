#!/bin/bash
# Reminds the user to run CI checks locally before pushing.
# Outputs a warning, does not block.
#
# Customize the checklist below for your project's actual commands.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check on git push
if ! echo "$COMMAND" | grep -qE '\bgit\s+push\b'; then
  exit 0
fi

echo "PRE-PUSH REMINDER: Ensure these passed locally before pushing:" >&2
echo "  [ ] Lint                  (e.g. npm run lint)" >&2
echo "  [ ] Type check            (e.g. npm run typecheck)" >&2
echo "  [ ] Tests                 (e.g. npm run test)" >&2
echo "  [ ] Build                 (e.g. npm run build)" >&2
echo "  [ ] Framework validation  (e.g. sam validate, terraform validate)" >&2

exit 0
