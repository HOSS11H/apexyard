---
name: write-spec
description: Write a feature spec or PRD from a problem statement or feature idea. Use when creating product requirements documents.
argument-hint: "<feature or problem statement>"
---

# /write-spec — Feature Specification

Write a feature specification or product requirements document (PRD).

## Usage

```
/write-spec SSO support for enterprise
/write-spec Users want to export data as CSV
/write-spec We need better onboarding
```

## Workflow

### 1. Understand the Feature

Accept any of: a feature name, a problem statement, a user request, or a vague idea.

### 2. Gather Context

Ask conversationally:

- **User problem** — what problem does this solve? Who experiences it?
- **Target users** — which user segment(s)?
- **Success metrics** — how will we know this worked?
- **Constraints** — technical, timeline, dependencies?
- **Prior art** — has this been attempted before?

### 3. Pull Context from Connected Tools

If the project has integrations available:

- **Ticket tracker (Linear / Jira / GitHub Issues)** — search for related tickets, epics, or features
- **Notion / Confluence** — search for related research, specs, or design docs
- **Figma** — pull related mockups or wireframes

### 4. Generate the PRD

Use `templates/prd.md` as the base. The PRD should include:

```markdown
# {Feature Name} — PRD

## Problem Statement
## Goals
   3–5 specific, measurable outcomes

## Non-Goals
   3–5 things explicitly out of scope

## User Stories
   As a [user type], I want [capability] so that [benefit]

## Requirements
### Must-Have (P0)
### Nice-to-Have (P1)
### Future (P2)

## Success Metrics
### Leading Indicators (days–weeks)
### Lagging Indicators (weeks–months)

## Open Questions
## Timeline
```

### 5. Review and Iterate

After generating the draft: ask if sections need adjustment, offer follow-ups.

### 6. Create the Tracking Ticket

Offer to create an epic / feature ticket in the team's tracker with the PRD content.
