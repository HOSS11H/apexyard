# PR Workflow — Hard Stops

## Before `git push` (HARD STOP)

**Never** push without running CI checks locally. This prevents wasted CI minutes and failed checks.

```
[ ] Lint passes?              NO → fix before pushing
[ ] Type check passes?        NO → fix before pushing
[ ] Tests pass?               NO → fix before pushing
[ ] Build succeeds?           NO → fix before pushing
```

The `pre-push-gate.sh` hook reminds you of this on every `git push`.

Per-project commands depend on your stack. Common pattern:

```bash
npm run lint && npm run typecheck && npm run test && npm run build
```

For framework-specific projects, add the framework's own validator:

```bash
sam validate --lint        # AWS SAM
terraform validate         # Terraform
cdk synth                  # AWS CDK
```

Also check before pushing:

```
[ ] Only intended files staged?  NO → use specific `git add <file>` (NEVER `git add -A`)
[ ] PR title matches format?     NO → type(TICKET-ID): description
```

## Before `gh pr create`

```
[ ] Ticket exists?            NO → create the ticket FIRST
[ ] Ticket has AC?            NO → add acceptance criteria
[ ] Branch has ticket ID?     NO → rename branch
[ ] PR title has ticket ID?   NO → fix format (single ticket per title)
```

## After `gh pr create`

```
[ ] Invoke Code Reviewer agent
[ ] Wait for Code Reviewer approval
[ ] Wait for human approver (explicit "approved" or similar)
```

## Before `gh pr merge`

```
[ ] Code Reviewer approved?   NO → WAIT
[ ] Human approver approved?  NO → WAIT
```

NO EXCEPTIONS. Not for "small fixes". Not for "just a typo".

## After Pushing Commits to an Open PR

```
[ ] Re-invoke Code Reviewer for the new changes
```

A review is bound to a specific commit SHA — pushing additional commits invalidates the prior review.

## Resuming PR Sessions

Use the `--from-pr` flag to resume a Claude Code session linked to a specific PR:

```bash
claude --from-pr 123
```

This loads the PR context (diff, comments, review state) so you can continue work without re-explaining.
