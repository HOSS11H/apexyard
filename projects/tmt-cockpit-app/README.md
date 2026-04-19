# tmt-cockpit-app

**Repo:** [sourcya/tmt-cockpit-app](https://github.com/sourcya/tmt-cockpit-app) (renamed from `tmt-cockpit-react-app` — GitHub redirects)
**Status:** handover (see [handover-assessment.md](handover-assessment.md))
**Tier:** P1
**Stack:** TypeScript + **React 18 + Vite 3** (SPA / installable PWA) + Capacitor 3 native shell
**Backend:** External REST service via `VITE_API_URI`, JWT auth (`jwt-decode`)
**Hosting:** **Firebase Hosting** (auto-deploy on merge to `main`) — `vercel.json` is present but unused
**Tracker:** ClickUp (prefix `CU`)
**Default branch:** `dev` (releases to production via `main`)

## Overview

Long-running (3.5 years, 224 commits in last 90 days) operator cockpit UI — dashboards, CSV/XLSX/PDF exports, maps, rich-text editing, multilingual + RTL. Installable as a PWA and wrapped as a Capacitor native app for Android/iOS.

## Links

- [Handover assessment](handover-assessment.md) — 2026-04-19
- [Architecture — L2 containers](architecture/container.md)
- Roadmap: _not yet created_ — run `/roadmap` when ready
- Stakeholder updates: `updates/` _(not yet created)_

## Review pattern note

This project is **React + Vite**, not Next.js. Rex should load `~/.claude/PATTERNS-REACT.md` only — **skip** `~/.claude/PATTERNS-NEXTJS.md` (patterns 11–15 don't apply: no `searchParams`-backed list state, no SSR queries, no API route handlers, no route-segment `loading.tsx` / `error.tsx`).

## Known risks (from handover)

1. **No README in the app repo** — zero onboarding doc for 10+ contributors
2. **No automated tests** — and no `lint`/`typecheck`/`test` npm scripts either
3. **No CI quality gates** — only Firebase deploy + Claude bot review; lint/build/tests not enforced
4. **Consolidation debt**: 5 date libs, 2 validation libs (Yup+Zod), 2 routing versions, 4 UI primitive systems (MUI + Radix + base-ui + react-select), 3 styling systems
5. **Stale major versions**: Vite 3, Capacitor 3, axios 0.27, TanStack Query v4, i18next v21
6. **`loadsh` typosquat dep** in `package.json` (unused but installed — cosmetic security hygiene)
7. **No observability** — no Sentry / Datadog / error tracking
8. **Identity sprawl** — 10 git identities across ~5 humans, distorting blame

See the handover assessment for the full list and next steps.
