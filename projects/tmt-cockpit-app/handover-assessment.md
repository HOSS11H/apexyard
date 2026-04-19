# tmt-cockpit-app — Handover Assessment

**Date**: 2026-04-19
**Assessor**: HOSSAM SAID
**Status**: handover

## Origin

- **Where it came from**: Long-running Sourcya project being onboarded into ApexYard governance
- **Original owner**: Sourcya (repo owner `sourcya` on GitHub)
- **Repo location**: `sourcya/tmt-cockpit-app` (GitHub resolved name — **was renamed** from `tmt-cockpit-react-app`; local clone's origin URL still uses the old name and redirects)
- **Local clone path**: `Github/React/Sourcya/tmt-cockpit-react-app/`
- **First commit date**: 2022-08-04 (~3.5 years old)
- **Last commit date**: 2026-04-12 (`feat(consoles): add CSV export dialog and fix skeleton component naming`, HOSSAM SAID)
- **Current branch**: `dev`
- **Release path**: `dev` → `main` → Firebase Hosting auto-deploy

## Current State

### Tech stack
- **Language**: TypeScript (`strict: true`, but `target: "es5"` — ancient target)
- **Build tool**: **Vite 3.0.4** (current is Vite 7 — three majors behind)
- **Package manager**: pnpm (`pnpm-lock.yaml`)
- **UI framework**: React 18
- **Routing**: `react-router-dom` 6 **and** `react-router` 7 both present — conflict
- **State**: unclear — no Zustand / Redux / Jotai in deps. Likely context + React Query.
- **Server state**: TanStack Query v4 (v5 is current)
- **Forms**: React Hook Form + **both Yup and Zod** — two validation libs
- **UI libraries** (stacked): **`@mui/material` v5 + Radix UI + `@base-ui/react` + `react-select`** — four overlapping primitive systems
- **Styling**: **styled-components + emotion + Tailwind CSS** — three styling approaches
- **Date**: **`moment` + `moment-timezone` + `date-fns` + `date-fns-tz` + `@date-io/moment`** — five date libraries in one repo
- **Rich text**: Tiptap 3 (many extensions)
- **Mobile**: **Capacitor 3.6** (android/ios/cli) — current is Capacitor 7. Capacitor 3 has known build issues on modern Android.
- **PWA**: `vite-plugin-pwa` 0.12 (current is 0.20+)
- **HTTP**: axios v0.27 (current is v1.x — security patches since)
- **Auth**: manual JWT (`jwt-decode`). No NextAuth / Clerk / Auth0.
- **Maps**: `@react-google-maps/api`, `use-places-autocomplete`
- **Exports**: `papaparse`, `react-papaparse`, `xlsx`, `html2pdf.js`, `html2canvas`, `qrcode`, `qrcode.react`
- **I18n / RTL**: `i18next` v21 (v24 is current), `stylis-plugin-rtl`
- **Test framework**: **none** (no vitest/jest/playwright, no `*.test.*` files)
- **CI**: `firebase-hosting-merge.yml` (deploy on push to `main`, Node 20 + pnpm), `firebase-hosting-pull-request.yml` (PR preview), `claude-pr-review.yml` — **no lint / typecheck / test CI**
- **Hosting**: **Firebase Hosting** (NOT Vercel). `vercel.json` file is present but unused — dead config.
- **Deployment**: auto-deploy to Firebase on merge to `main`

### Build status
- `pnpm install`: not attempted (you pushed last week — assumed green)
- `pnpm build`: not attempted
- `lint`: **no `lint` script in package.json**
- `typecheck`: **no `typecheck` script in package.json** (would need to add `tsc --noEmit`)
- `test`: **no `test` script in package.json**

### Test coverage
- **Zero** — no test files, no coverage config.

### Repo activity
- **Commits in last 90 days**: 224 (very active)
- **Open issues** (GitHub): 0 (tracking in ClickUp)
- **Open PRs** (GitHub): 1
- **Top contributors**:
  - mustafa (359) — primary author
  - Mostafa Mofeed (304) / MostafaMofeed67 (126) — same person, two identities
  - Hossam (171) / HOSSAM SAID (159) / Hossamhelmyy (126) / HossamHelmyy (86) / hossam (64) — same person across 5 different git identities
  - Mohamed Abassia (152)
  - Mutasim Issa (128)
- **Identity sprawl**: at least 2 contributors have multiple git `user.name` values, distorting blame history.

### Developer tooling (lighter than tmt-eye-app)
- **No husky / commitlint / prettier config detected** (unlike tmt-eye-app)
- ESLint 8 + `eslint-config-react-app`
- `.claude/` folder with `PATTERNS-REACT.md` — already set up for Rex review
- `.claude/pr-review-744.md` — archived PR review artifact
- `docs/CRM.md` — one short domain doc
- **No README.md at all**

## Quality Risks

### Security
- **`loadsh` typosquat dependency** (`^0.0.4`) is installed (not imported anywhere in `src/`). The package on npm is harmless, but keeping a typo-looking dep in the lockfile is a weak signal that the supply chain isn't audited. **Remove it.**
- **Capacitor 3.6 in production** — three majors behind (current v7). Capacitor 3 has unresolved Android build issues and lacks security patches shipped in 4/5/6/7.
- **axios 0.27** — 3+ years of security patches unapplied. Move to 1.x.
- Manual JWT handling (`jwt-decode`) — no abstraction layer, easier to misuse. Confirm token refresh + secure storage patterns with the team.
- `.env` is correctly gitignored (listed twice in `.gitignore` — duplicate entry, worth cleaning). `.env.example` is tracked and minimal (two vars: `VITE_API_URI`, `VITE_GOOGLE_MAPS_API_KEY`).

### Dependencies
- **Duplicate routing libs**: `react-router` v7 + `react-router-dom` v6 — pick one.
- **Duplicate validation libs**: `yup` + `zod` — per Pattern 4, standardise on Zod.
- **Four UI primitive systems**: MUI v5 + Radix + base-ui + react-select. Heavy bundle, inconsistent interaction patterns, multiplicative pattern divergence.
- **Three styling systems**: styled-components + emotion + Tailwind. Pick Tailwind (matches tmt-eye-app and Pattern-family defaults); migrate styled/emotion piecemeal.
- **Five date libraries**: moment + moment-timezone + date-fns + date-fns-tz + `@date-io/moment`. Moment is deprecated since 2020. Consolidate on date-fns-tz.
- **TanStack Query v4** — v5 is current; breaking changes around `isLoading`/`isPending`.
- **Vite 3 → 7**: three majors of perf + ecosystem improvements missed. Paired with `@vitejs/plugin-react` v1 (v4 current).
- **`loadsh` typo dep** (see security).
- No evidence of `/audit-deps` ever run.

### Technical debt
- **No README.** Worse than tmt-eye-app (which has 1 line). Zero onboarding doc for a 3.5-year-old project with 10+ contributors.
- **Identity sprawl**: at least 9 git identities for 5 humans. Standardise `user.name` / `user.email` per contributor.
- **`tsconfig` target is `es5`** — modern Vite outputs ES modules; es5 target here is either vestigial or deliberately supporting ancient browsers. Verify intent.
- **`vite.config.js` is JavaScript**, not TypeScript — the rest of the codebase is TS.
- **Four to five parallel paradigms** (UI libs, styling, date, routing, validation). The project grew organically without consolidation checkpoints.
- Dead `vercel.json` (misleading — deploys are Firebase).
- `dev-dist/` directory exists at the root — looks like a committed dev build artefact. Worth checking `.gitignore`.
- No `lint` / `typecheck` / `test` scripts — you can't even run quality gates from npm without hand-rolling commands.

### Operational
- **No CI beyond Firebase deploy workflows + Claude bot.** Zero lint / typecheck / build validation on PR. A PR can ship to production without any automated sanity check.
- **No observability** (no Sentry, LogRocket, Datadog). Errors in production are invisible.
- **Deploy gate is "PR merged to main"** — no staging, no manual approval step between merge and production traffic.
- **Husky hooks absent** — unlike tmt-eye-app, no pre-commit / commit-msg enforcement locally.

## Integration Plan

### Roles that apply
- **tech-lead** (always)
- **frontend-engineer** (React 18 SPA)
- **ui-designer** (MUI + Radix + base-ui + Tailwind — heavy consolidation work ahead)
- **platform-engineer** (Firebase deploy + missing lint/typecheck/test CI)
- **security-auditor** (JWT handling + Capacitor mobile + typo dep hygiene)
- **sre** (Firebase Hosting production target, zero observability, no staging)

### Workflows that kick in
- [ ] PR workflow (`.claude/rules/pr-workflow.md`) — every change goes through a PR
- [ ] AgDR for technical decisions (ESPECIALLY the consolidation calls: date lib, validation lib, UI lib, styling)
- [ ] Code Reviewer agent (Rex) on every PR — already present via `claude-pr-review.yml`, verify it matches ApexYard Rex
- [ ] Security Reviewer (Shield) on PRs touching `src/**/auth/**`, JWT handling, Capacitor native bridges
- [ ] `/audit-deps tmt-cockpit-app` — **highest-priority first action** (typo dep + multi-version drift)

### Hooks to enable
- [ ] `block-git-add-all`
- [ ] `block-main-push` — `main` is the production deploy trigger, protect it hard
- [ ] `validate-branch-name` — `CU` prefix
- [ ] `validate-pr-create`
- [ ] `pre-push-gate`
- [ ] `check-secrets`
- [ ] Consider adding Husky + commitlint locally (tmt-eye-app has this; tmt-cockpit-app doesn't)

### CI templates to copy in
- [ ] `golden-paths/pipelines/ci.yml` — lint + typecheck + build (NEED to add `lint` and `typecheck` npm scripts first)
- [ ] `golden-paths/pipelines/security.yml` — Semgrep + npm audit + secret scan
- [ ] `golden-paths/pipelines/pr-title-check.yml` — enforce ticket ID
- Note: existing `firebase-hosting-*.yml` workflows stay; just add quality gates alongside.

### Registry entry
Already added (commits `802ca8f` + `dba4564` + `4bfe19c`):

```yaml
- name: tmt-cockpit-app
  repo: sourcya/tmt-cockpit-app
  docs: projects/tmt-cockpit-app
  status: active          # RECOMMENDED: flip to `handover` — integration plan not yet run
  tier: P1
  roles:
    - tech-lead
    - frontend-engineer
    - ui-designer          # RECOMMENDED: also add platform-engineer, security-auditor, sre
  tags:
    - frontend
    - react
    - vite                 # RECOMMENDED: also add firebase, pwa, capacitor
  ticket_prefix: CU
```

## Next Steps

Derived from the risks above:

1. **`/audit-deps tmt-cockpit-app`** — remove `loadsh` typosquat, plan Capacitor 3 → 7 upgrade (security), plan axios 0.27 → 1.x, tackle date-library consolidation (5 → 1).
2. **Write a real README.md** — zero doc for a 3.5-year-old app with 10+ contributors is an onboarding wall.
3. **Add `lint`, `typecheck`, `test` npm scripts** — `package.json.scripts` currently only has `dev`, `build`, `preview`. Without these, CI can't run quality gates.
4. **Set up Vitest + coverage baseline** before the next feature PR. Start with 1-2 tests on `src/lib/validations` (if Zod schemas exist there) or `src/utils/`.
5. **AgDR: pick one validation library** — Yup vs Zod. Per Pattern 4, Zod. Migrate Yup schemas incrementally.
6. **AgDR: pick one date library** — `date-fns-tz` recommended. `moment` is deprecated.
7. **AgDR: pick one routing version** — `react-router` v7 (the ecosystem has moved). Remove `react-router-dom` v6.
8. **AgDR: UI library consolidation plan** — MUI + Radix + base-ui is overkill. Likely direction: Radix + Tailwind to match tmt-eye-app, migrate MUI out.
9. **Add CI lint/typecheck/build pipeline** (`golden-paths/pipelines/ci.yml`) alongside existing Firebase deploy workflows.
10. **Standardise git identities** — `HOSSAM SAID` across 5 aliases, `Mostafa Mofeed` across 2 aliases. Share a git config across team laptops.
11. **Fix cosmetics before they rot**: duplicate `.env` line in `.gitignore`, dead `vercel.json`, `dev-dist/` committed artefact, `vite.config.js` → `.ts`.

## Post-Handover Checklist

- [ ] Review this assessment with the team (10+ active contributors)
- [ ] Remove `loadsh` typosquat dep — before the next release (security hygiene, < 5 min)
- [ ] Write `README.md` — close before the first feature PR under ApexYard
- [ ] Add `lint`, `typecheck`, `test` scripts to `package.json`
- [ ] Add Vitest + coverage baseline — gate for the first feature PR
- [ ] AgDRs for the 4 consolidation calls (validation, date, routing, UI libs)
- [ ] Flip registry status `active` → `handover` until integration plan runs
- [ ] Flip registry roles: add `platform-engineer`, `security-auditor`, `sre`
- [ ] Expand registry tags: add `firebase`, `pwa`, `capacitor`
- [ ] Copy golden-paths CI pipelines into `.github/workflows/` alongside Firebase deploys
- [ ] Add `tmt-cockpit-app` to the weekly `/stakeholder-update` rollup
- [ ] Run `/audit-deps` monthly for the next 3 months

## Open Questions

- **Where does the backend live?** The app uses `VITE_API_URI` + JWT — same external backend as tmt-eye-app, or a different service? If shared, should the backend be its own ApexYard-registered project?
- **What does Capacitor 3 deploy to today?** Is the mobile build still live on app stores, or is it legacy? If alive, upgrading to v7 is a project in itself. If dead, remove Capacitor entirely.
- **Is `vercel.json` a leftover from a migration, or a planned fallback?** Dead configs confuse future readers.
- **`dev-dist/` at the root** — is this meant to be committed, or should it be gitignored alongside `dist/`?
- **PWA installs in the wild?** If so, `vite-plugin-pwa` config + service worker version strategy need review.
- **Staging environment?** Firebase Hosting supports channels — is there a preview channel for `dev` before `main`?
- **`claude-pr-review.yml` compatibility** — same bot as ApexYard's Rex, or a separate config? Worth aligning.
- **Default branch reality check** — the Firebase deploy workflow fires on `main`, but the local default is `dev`. Is `main` only touched via merge-from-`dev`?
