# tmt-cockpit-app

**Repo:** [sourcya/tmt-cockpit-app](https://github.com/sourcya/tmt-cockpit-app)
**Status:** active
**Tier:** P1
**Stack:** TypeScript + **React + Vite** (frontend SPA)
**Tracker:** ClickUp (prefix `CU`)

## Overview

_Run `/handover tmt-cockpit-app` to generate a structured assessment._

## Links

- Roadmap: [roadmap.md](roadmap.md) (not yet created)
- Stakeholder updates: `updates/` (not yet created)

## Review pattern note

This project is **React + Vite**, not Next.js. Rex should load `~/.claude/PATTERNS-REACT.md` only — **skip** `~/.claude/PATTERNS-NEXTJS.md` (patterns 11–15 don't apply: no `searchParams`-backed list state, no SSR queries, no API route handlers, no route-segment `loading.tsx` / `error.tsx`).
