---
id: AgDR-9001
timestamp: 2026-10-14T11:42:25Z
agent: claude
model: claude-opus-5-5
trigger: user-prompt
status: executed
---

# Fetch the CI snapshot proofs from upstream in the fork

> In the context of the v5.8.0 upstream sync (KAN-148), facing hook-test CI that fails at setup in every fork, I decided to fetch the snapshot proofs from `me2resh/apexyard` in the fork's `tests.yml` to achieve a green, meaningful hook test suite, accepting a one-step divergence from upstream until upstream fixes it.

## Context

- Upstream `tests.yml` fetches `refs/pull/1466/head` from `$GITHUB_SERVER_URL/$GITHUB_REPOSITORY.git`. In this fork, that URL names the fork, which has no PR 1466.
- Each hook-test leg failed with exit 128 before any test ran (run 38500132015 on PR #7). The red-CI merge gate blocks a merge while a check fails.
- The ref exists on `me2resh/apexyard` and is public. A local fetch from upstream found all three pinned commits.
- The defect is also on upstream `main` and `dev` at the time of writing. No upstream issue reported it.
- The operator chose this option on 2026-10-14.
- This record uses the fork-local number 9001. Upstream `dev` already uses AgDR numbers up to 0240, so the next sequential number would repeat an upstream identifier after a later sync.

## Options Considered

| Option | Pros | Cons |
|--------|------|------|
| Patch the fork's `tests.yml` and report the bug upstream | The fork's CI runs the suite now. Upstream learns about the defect. | The fork differs from upstream in one step until upstream fixes it. |
| Report upstream and wait for a fixed release | No divergence. | PR #7 stays red and unmerged. The fork stays on v5.6.2 until a fixed release. |
| Patch the fork only | The fork's CI runs the suite now. | Other forks keep the defect. The divergence has no planned end. |

## Decision

Chosen: **patch the fork's `tests.yml` and report the bug upstream**, because it makes the hook test suite run in the fork now and gives the divergence a clear end.

## Consequences

- The fork's `tests.yml` fetches the snapshot proofs from `me2resh/apexyard`. The step still checks the three pinned SHAs with `cat-file`.
- A comment in the step marks it as a fork-local change.
- When upstream fixes the step, the next `/update` takes upstream's version. If the step conflicts, keep upstream's side.
- Fork-local AgDRs use the 9001 range from now on.

## Artifacts

- KAN-148 (Jira)
- HOSS11H/apexyard#7
