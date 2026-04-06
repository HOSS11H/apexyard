# Workflow Gates

| Gate | Before | Verify |
|------|--------|--------|
| 1 | PRD → Tech Design | PRD approved, parent epic exists |
| 2 | Tech Design → Build | Design approved, story tickets exist, **AgDR for key decisions** |
| 3 | Starting code | Ticket exists, branch created, design review if UI work |
| 4 | Creating PR | Tests pass, checks pass, **> 80% coverage**, **AgDR linked if decisions made** |
| 5 | Merging PR | 2 reviews (agent + human), CI green, **commit SHA matches review** |
| 6 | Ticket → Done | QA verified, signed off |

**If a gate fails → STOP. Complete the missing step first.**

## One Ticket at a Time

Work on **one** ticket at a time. Complete it fully before starting the next. Each PR = one ticket only.

```
WRONG:
  Start ticket A → Start ticket B → Start ticket C → PR with all 3

RIGHT:
  Start A → PR → Review → QA → Done
  Start B → PR → Review → QA → Done
  Start C → PR → Review → QA → Done
```

## Pre-Build Gate

Do not start coding until **all** of these exist in your ticket tracker:

- Parent epic / feature ticket (with link to the PRD)
- User story tickets (sub-issues)
- Each story has acceptance criteria
- Technical tasks broken down
- Tickets moved to "Todo" or "In Progress"

## QA State is Mandatory

A merged PR moves the ticket to **QA** state, **not** Done. A QA Engineer manually verifies the acceptance criteria, then moves the ticket to Done.

```
In Progress → In Review → QA → Done
                          ^
                    MANDATORY STOP
                    QA must verify
```
