# Git Conventions

## Branch Naming

Format: `{type}/{TICKET-ID}-{description}`

Examples:

- `feature/ABC-123-add-auth`
- `fix/GH-45-login-bug`
- `docs/ENG-99-update-readme`

**Types**: `feature`, `fix`, `refactor`, `chore`, `docs`, `test`, `spike`, `ci`, `build`, `perf`

The `TICKET-ID` is whatever your team's ticket system uses — Linear (`ENG-123`), Jira (`PROJ-45`), or GitHub Issues (`GH-58` / `#58`). The validators in `.claude/hooks/` accept any uppercase prefix.

## PR Title Format

Must match: `type(TICKET): description`

Regex: `^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)\(([A-Z]+-[0-9]+|#[0-9]+)\):`

- One ticket ID per PR title — multi-ticket titles like `fix(ABC-1,2,3):` are rejected
- GitHub Issues use `#XX` format: `fix(#58): description`

## Commit Message Format

```
type: subject

- Detailed change 1
- Detailed change 2

Closes #123
```

**Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`

## File Staging

**NEVER** use `git add -A`, `git add .`, or `git add --all`. Always add specific files:

```bash
git add src/specific-file.ts
```

This is enforced by the `block-git-add-all.sh` hook.

## No Direct Main

Every change must go through a PR. Zero exceptions. No commits directly to `main`/`master`. Enforced by the `block-main-push.sh` hook.

## No Hardcoded Secrets

No API keys, passwords, tokens, or credentials in code. Use environment variables. Patterns to avoid:

- `api_key=`, `password=`, `secret=`, `token=`
- Cloud account IDs and ARNs
- Database connection strings
- Private keys or certificates

Enforced by the `check-secrets.sh` hook.
