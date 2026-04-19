# tmt-eye-app

**Repo:** [sourcya/tmt-eye-app](https://github.com/sourcya/tmt-eye-app)
**Status:** handover (see [handover-assessment.md](handover-assessment.md))
**Tier:** P1
**Stack:** Next.js 16 (App Router) + React 19 + TypeScript (strict) + Radix/Tailwind + NextAuth v5 beta + TanStack Query + Zustand + Socket.IO + Firebase Messaging + Google Maps + Postmark
**Backend:** External REST + WebSocket service (not in this repo)
**Tracker:** ClickUp (prefix `CU`)
**Default branch:** `dev`

## Overview

Fleet management / dispatch web app — drivers, vehicles, maintenance, dispatch jobs, warehouses, reports, realtime tracking. Multilingual via `app/[lng]` i18n routing.

## Links

- [Handover assessment](handover-assessment.md) — 2026-04-19
- [Architecture — L2 containers](architecture/container.md)
- Roadmap: _not yet created_ — run `/roadmap` when ready
- Stakeholder updates: `updates/` _(not yet created)_

## Review pattern note

This project is **Next.js 16 (App Router)**. Rex should load both `~/.claude/PATTERNS-REACT.md` (universal patterns 1–10) **and** `~/.claude/PATTERNS-NEXTJS.md` (App Router patterns 11–15: URL searchParams for list state, SSR queries in `data/queries/`, API route proxies, SSR cache invalidation, `loading.tsx` / `error.tsx`).

## Known risks (from handover)

1. No automated tests — 644 commits in 90 days with no safety net
2. No CI beyond Claude bot workflows
3. README in the app repo is 1 line
4. NextAuth v5 **beta** in production
5. Dependency drift (`moment` + `date-fns`, stale `lucide-react` pin, `@typescript-eslint` v5)

See the handover assessment for the full list and next steps.
