# tmt-eye-app — Handover Assessment

**Date**: 2026-04-19
**Assessor**: HOSSAM SAID
**Status**: handover

## Origin

- **Where it came from**: Existing Sourcya project being onboarded into ApexYard governance
- **Original owner**: Sourcya Developers (https://sourcya.io)
- **Repo location**: `sourcya/tmt-eye-app` — local clone at `Github/Next JS/Sourcya/tmt-eye-app`
- **First commit date**: 2024-08-19
- **Last commit date**: 2026-04-19 (today — `fix(layout): ensure translation is initialized before fetching subscription data`)
- **Current branch**: `dev`

## Current State

### Tech stack
- **Language**: TypeScript 5.2.2 (strict mode ON)
- **Runtime**: Node.js (Docker `node:${NODE_VERSION}-alpine`)
- **Framework**: Next.js **16.2.4** (App Router, `app/[lng]` i18n routing, API routes in `app/api/`)
- **UI**: React 19, Radix UI primitives, Tailwind CSS, shadcn-style components in `components/ui/`
- **State**: Zustand (client) + nuqs (URL state) + TanStack Query (server)
- **Forms**: React Hook Form + Zod (matches Pattern 4 in `~/.claude/PATTERNS-REACT.md`)
- **i18n**: i18next + `app/[lng]` locale-based routing
- **Data fetching**: TanStack Query on client, `data/queries/` for SSR (matches Pattern 12)
- **Auth**: NextAuth v5 **beta** (`5.0.0-beta.31`) + `@auth/prisma-adapter` — but no `prisma/schema.prisma` in repo → DB lives in an external backend service
- **Realtime**: Socket.IO (client + server)
- **Notifications**: Firebase Messaging + Firebase Admin
- **Maps**: `@react-google-maps/api`, `use-places-autocomplete`, `supercluster`
- **Charts**: Recharts
- **Email**: Postmark + Nodemailer
- **Editor**: EditorJS (multiple blocks)
- **Animation**: Framer Motion, Lottie, Swiper
- **Analytics**: `@vercel/analytics`
- **Test framework**: **none** (no Vitest/Jest/Playwright config, no `*.test.*` or `*.spec.*` files found)
- **CI**: only Claude bot workflows (`claude.yml`, `claude-pr-review.yml`) — no lint/typecheck/test/build pipeline
- **Hosting**: Vercel (per onboarding.yaml) + Dockerfile for self-hosted option
- **Deployment**: Dockerized (multi-stage Alpine Node build)

### Build status
- `npm install`: not attempted (user just committed today — assumed green locally)
- `npm run build`: not attempted
- `npm run lint`: not attempted
- `npm run test`: **no test script defined in `package.json`**

### Test coverage
- **Unknown — zero tests in repo.** No coverage reports exist.

### Repo activity
- **Commits in last 90 days**: 644 — extremely active
- **Open issues** (GitHub): 0 (tracking lives in ClickUp, as expected)
- **Open PRs** (GitHub): 5
- **Top contributors**:
  - Hossamhelmyy (378)
  - Mostafa Mofeed (328)
  - Noorhesham99 (254)
  - HOSSAM SAID (250)
  - hossam (206) — likely same person as Hossamhelmyy / HOSSAM SAID under a different git identity
  - Mohamed Abassia (157)
  - mustafa (124)
  - Mutasim Issa (75)

### Developer tooling (good shape)
- Husky `commit-msg` + `pre-commit` hooks wired
- Commitlint (conventional commits)
- Prettier + `pretty-quick` + `@ianvs/prettier-plugin-sort-imports` + `prettier-plugin-tailwindcss`
- ESLint with `next/core-web-vitals` config, `eslint-plugin-tailwindcss`, `eslint-plugin-react`
- `.claude/` folder with `PATTERNS-NEXTJS.md` and `PATTERNS-REACT.md` — already using the user's personal review workflow

## Quality Risks

### Security
- **NextAuth v5 beta in production** (`5.0.0-beta.31`). Betas can ship breaking changes between minor versions. Track the v5 GA release and plan the upgrade.
- **`@auth/prisma-adapter` in deps but no Prisma schema** — dead weight, or DB proxied to a backend service? Worth confirming.
- Env files (`.env.development.local`, `.env.production.local`) are correctly **gitignored** and **not tracked**. Good.
- Auth, crypto (JWT/sessions), and user-data handling present → `security-auditor` role must activate on any PR touching `auth/`, `middleware.ts`, `app/api/auth/**`.

### Dependencies
- **`moment` (deprecated since 2020) AND `date-fns` v2.29 (v4 is current) both in deps** — redundant; pick one.
- **`lucide-react` pinned to `^1.8.0`** — extremely old; current releases are in the 0.5xx line (post-rename). Likely a typo or stale pin worth auditing.
- **`clsx` `^1.2.1`** — v2 is current (minor breakage, mostly a perf bump).
- **`@typescript-eslint/parser` v5** — very behind (v8 is current). Paired with `eslint` v8 (v9 is current). Delaying creates migration pain.
- **`@types/node` v18** alongside actual build on newer Node — version drift.
- Heavy footprint: ~100 dependencies, multiple EditorJS blocks, dual state libs historically (see `lib/stores/` AND `stores/`). No evidence of `/audit-deps` ever being run.

### Technical debt
- **README is 1 line long** (`### ` — literally just three characters). No project description, no setup instructions, no architecture overview.
- **Zero tests.** 644 commits in 90 days with no automated test coverage is the single biggest risk.
- **Two state directories** (`lib/stores/` and `stores/`) — organization drift, likely some duplication.
- `next.config.mjs.temp` committed alongside `next.config.mjs` — cruft.
- Two date libraries in use (see above).
- `webpack` listed as a direct dep — unusual for a Next.js app (Next bundles its own).

### Operational
- **No CI beyond Claude bot workflows.** No automatic lint, typecheck, test, or build on PR. The only gate is Claude bot review.
- **No observability** (no Sentry, Datadog, OpenTelemetry). Vercel Analytics captures web vitals but not errors.
- **No `.env.example`** — new contributors have no reference for required env vars.
- **Branch is `dev`** (not `main`) — non-default base branch; verify merge target conventions are well understood by every contributor.

## Integration Plan

### Roles that apply
Derived from the stack + security surface + deployment evidence:

- **tech-lead** (always)
- **frontend-engineer** (React 19 + Next.js)
- **ui-designer** (Radix + Tailwind + heavy custom component library)
- **platform-engineer** (needs CI work — currently absent)
- **security-auditor** (auth + sessions + JWT + external integrations)
- **sre** (Dockerfile + multi-env production deploy)

### Workflows that kick in
- [ ] PR workflow (`.claude/rules/pr-workflow.md`) — every change goes through a PR
- [ ] AgDR for technical decisions
- [ ] Code Reviewer agent (Rex) on every PR
- [ ] Security Reviewer (Shield) on PRs touching `app/api/auth/**`, `middleware.ts`, `auth.ts`, `auth.config.ts`
- [ ] `/audit-deps` on adoption, then monthly

### Hooks to enable
- [ ] `block-git-add-all`
- [ ] `block-main-push` — configure for `dev` as the protected base
- [ ] `validate-branch-name` — `CU` prefix (ClickUp custom task IDs)
- [ ] `validate-pr-create`
- [ ] `pre-push-gate`
- [ ] `check-secrets`

### CI templates to copy in
- [ ] `golden-paths/pipelines/ci.yml` — lint / typecheck / build
- [ ] `golden-paths/pipelines/security.yml` — Semgrep + npm audit + secret scan
- [ ] `golden-paths/pipelines/pr-title-check.yml` — enforce ticket ID

### Registry entry

Already added (commit `802ca8f`) — but with `status: active`. Per skill rule 9, this should be `handover` until the integration plan runs. **Recommended: flip to `handover` on next commit.**

Also: `apexyard.projects.yaml` has the project as generic `frontend` / `react`. It is specifically **Next.js** (App Router, i18n, API routes). Worth adding `nextjs` to the tags. See Top 3 next steps.

## Next Steps

Derived directly from the risks above:

1. **Fix the registry status + tags.** Flip `tmt-eye-app` to `status: handover` and add `nextjs` / `i18n` / `auth` to `tags` in `apexyard.projects.yaml`. Same for onboarding.yaml (tech_stack.framework should read `Next.js`, not plain `React`).
2. **Write a real README.** The one-line README is an onboarding blocker. At minimum: what the app does, how to run it locally (env vars required, ports), how to deploy, and where the external API lives.
3. **Run `/audit-deps` on tmt-eye-app.** Triage `moment` → `date-fns` consolidation, `lucide-react` pin, NextAuth v5 beta status, and `@typescript-eslint` v5 → v8.
4. **Set up test coverage baseline before the first feature PR.** Pick Vitest (matches the stack best), add `vitest.config.ts`, write 1-2 tests against the `lib/validations/` Zod schemas as a starting point, then add `npm run test` to package.json scripts.
5. **Re-enable CI.** Copy in `golden-paths/pipelines/ci.yml` — even without tests, lint + typecheck + build on every PR would catch 90% of breaks before the Claude bot needs to look.
6. **Stakeholder sync.** 11+ contributors across 644 commits in 90 days with no tests and no CI means there are conventions in people's heads that aren't written down. A 30-min walkthrough with the team would surface more risks than a static read.

## Post-Handover Checklist

- [ ] Review this assessment with the team (the 10+ active contributors)
- [ ] Write a real `README.md` (top-1 quality risk) — close before the first feature PR under ApexYard governance
- [ ] Run `/audit-deps tmt-eye-app` and triage the stale pins — scheduled in the first 2 weeks
- [ ] Set up Vitest + coverage baseline — first feature PR depends on this
- [ ] Add `tmt-eye-app` to the weekly `/stakeholder-update` rollup
- [ ] Onboard tech-lead / frontend-engineer / ui-designer / security-auditor / sre roles into the team's review rotation
- [ ] Copy golden-paths CI pipelines into `.github/workflows/` (currently only Claude bot workflows exist)
- [ ] Decide whether the `dev` branch stays as the default target or migrate to `main`
- [ ] Plan NextAuth v5 GA upgrade when it ships
- [ ] Confirm the external backend API: where is it hosted, who owns it, where's the OpenAPI spec, does it need to be registered as a separate managed project?

## Open Questions

- **Where does the backend live?** The app has `@auth/prisma-adapter` + `@prisma/client` in deps but no `prisma/schema.prisma` locally. Axios + socket.io client suggest an external API. Should that backend be its own ApexYard-managed repo?
- **Is `dev` the permanent default branch, or is there a `main` it merges to for production?** The `block-main-push.sh` hook will need configuring.
- **What does `ticket_prefix: CU` really map to?** Does every ClickUp task have a custom `CU-123` ID, or does some work still happen without tickets?
- **Contributor identity consolidation** — `HOSSAM SAID` / `Hossamhelmyy` / `hossam` appear to be the same person. Standardise git `user.name` / `user.email` across local setups to fix the blame attribution.
- **Is there a staging environment?** Dockerfile implies self-hosting; Vercel is declared in onboarding. Two deploy targets? Which is primary?
- **`claude-pr-review.yml`** already exists — is this compatible with ApexYard's Rex agent, or is it the same agent under a different invocation?
