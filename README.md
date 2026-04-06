# ApexStack

**A complete AI-native software development stack for Claude Code.**

ApexStack packages a production-tested development workflow into a reusable stack that any team can adopt. It provides role definitions, workflow processes, document templates, and Claude Code configuration that turns your AI assistant into a structured Chief of Staff for your engineering org.

Inspired by [gstacks.org](https://gstacks.org/) -- but purpose-built for software teams using Claude Code.

## What's Inside

```
apexstack/
├── CLAUDE.md              # Stack entry point -- Claude Code reads this first
├── onboarding.yaml        # Your company config -- fill this in to adopt the stack
│
├── roles/                 # AI agent role definitions
│   ├── engineering/       # Backend, Frontend, QA, Platform, SRE, Tech Lead, Head of Eng
│   ├── product/           # Product Manager, Product Analyst, Head of Product
│   ├── design/            # UI Designer, UX Designer, Head of Design
│   ├── security/          # Security Auditor, Penetration Tester, Head of Security
│   └── data/              # Data Analyst, Data Engineer, Head of Data
│
├── workflows/             # Development lifecycle processes
│   ├── sdlc.md            # Full software development lifecycle
│   ├── code-review.md     # Code review process and standards
│   └── deployment.md      # Deployment and release process
│
├── templates/             # Reusable document templates
│   ├── prd.md             # Product Requirements Document
│   ├── technical-design.md # Technical design document
│   ├── adr.md             # Architecture Decision Record
│   └── agdr.md            # Agent Decision Record (AI-specific)
│
├── .claude/               # Claude Code primitives (the runnable layer)
│   ├── settings.json      # Hook wiring (PreToolUse)
│   ├── hooks/             # Shell scripts: block git add -A, block main push, secrets scan, branch & PR validation, pre-push reminder
│   ├── rules/             # Modular rule files imported via @.claude/rules/* (AgDR triggers, code standards, git conventions, PR quality, workflow gates)
│   ├── agents/            # Sub-agents: Code Reviewer (Rex), Security Reviewer (Shield), Dependency Auditor (Guardian), PR Manager, Ticket Manager
│   └── skills/            # Slash commands: /decide, /code-review, /security-review, /audit-deps, /write-spec
│
├── golden-paths/          # Reusable infra & ops templates
│   └── pipelines/         # Drop-in GitHub Actions workflows (CI, code quality, security, dependency audit, PR title check, review check, SEO check)
│
├── docs/                  # Documentation
│   └── getting-started.md # Setup guide
│
└── site/                  # Landing page
    └── index.html
```

## Quick Start

### 1. Copy the stack into your repo

```bash
# Clone ApexStack
git clone https://github.com/me2resh/apexstack.git

# Copy into your project
cp -r apexstack/ your-project/.apexstack/
```

### 2. Fill in your company config

Edit `onboarding.yaml` with your company details:

```yaml
company:
  name: "Your Company"
  mission: "What you're building and why"

team:
  - name: "Alice"
    role: "tech-lead"
```

### 3. Point Claude Code at the stack

Add to your project's `CLAUDE.md`:

```markdown
# Development Stack
@.apexstack/CLAUDE.md
```

### 4. Install the `.claude/` layer (optional but recommended)

The markdown content above (roles, workflows, templates, rules) lives under `.apexstack/`. To activate the **executable** layer (hooks, agents, skills) you also need to make `.claude/` visible at the project root, because Claude Code only looks for hooks, agents, skills, and `settings.json` at `.claude/`:

```bash
# Option A — copy
cp -r apexstack/.claude your-project/.claude

# Option B — symlink (so updates to apexstack stay in sync)
ln -s "$(pwd)/apexstack/.claude" your-project/.claude
```

After this, the hooks fire on `git`/`gh` commands, `/decide` and `/code-review` are available as slash commands, and the Code Reviewer agent can be invoked.

### 5. Start working

Claude Code now understands your team structure, processes, and standards. It can:

- Act as any defined role (code reviewer, QA engineer, security auditor, etc.)
- Follow your SDLC workflow with proper gates
- Generate documents from templates (PRDs, technical designs, ADRs)
- Make structured technical decisions with Agent Decision Records
- Enforce code review standards and quality gates
- Run `/decide`, `/code-review`, `/security-review`, `/audit-deps`, `/write-spec` as slash commands
- Block `git add -A`, direct pushes to main, and committed secrets via hooks
- Drop the `golden-paths/pipelines/*.yml` files into `.github/workflows/` for CI

## Why ApexStack?

**The problem**: Claude Code is powerful, but without structure it produces inconsistent results. Every team reinvents the same processes -- role definitions, review checklists, document templates, workflow gates.

**The solution**: ApexStack provides that structure as a reusable, open-source stack. One config file to customize, 20+ role definitions to use, battle-tested workflows to follow.

### What makes it different

| Feature | Without ApexStack | With ApexStack |
|---------|-------------------|----------------|
| Code reviews | Ad-hoc prompts | Structured checklist with role-based review |
| Technical decisions | Lost in chat history | Documented as Agent Decision Records |
| Quality gates | Hope and pray | Enforced workflow stages |
| Role consistency | Re-explain every session | Persistent role definitions |
| Onboarding | Days of context-setting | One config file |

## Roles

ApexStack includes 20 software development roles across 5 departments:

### Engineering (7 roles)
- **Head of Engineering** -- Technical strategy, architecture standards, quality
- **Tech Lead** -- Feature design, code review, team coordination
- **Backend Engineer** -- Domain logic, APIs, infrastructure
- **Frontend Engineer** -- UI components, design system, accessibility
- **QA Engineer** -- Test strategy, automation, quality gates
- **Platform Engineer** -- CI/CD, infrastructure as code, developer tooling
- **Site Reliability Engineer** -- Monitoring, incidents, SLOs

### Product (3 roles)
- **Head of Product** -- Roadmap, prioritization, feasibility
- **Product Manager** -- PRDs, user stories, acceptance criteria
- **Product Analyst** -- Market research, metrics, competitive analysis

### Design (3 roles)
- **Head of Design** -- Design system, UX principles, visual standards
- **UI Designer** -- Visual design tokens, component specifications
- **UX Designer** -- User flows, information architecture, usability

### Security (3 roles)
- **Head of Security** -- Security strategy, threat modeling, compliance
- **Security Auditor** -- Static analysis, vulnerability detection, OWASP
- **Penetration Tester** -- Active testing, exploit discovery, API security

### Data (3 roles)
- **Head of Data** -- Analytics strategy, data governance, reporting
- **Data Analyst** -- SQL, dashboards, A/B testing, metrics
- **Data Engineer** -- ETL pipelines, data modeling, data quality

## Workflows

### Software Development Lifecycle (SDLC)

```
Planning --> Design --> Build --> Review --> QA --> Deploy --> Monitor
```

Each phase has entry criteria, activities, exit criteria, and quality gates.

### Code Review Process

Structured review with:
- Author responsibilities and PR description format
- Reviewer checklist (architecture, security, testing, performance)
- Feedback severity levels (blocking, suggestion, question)
- Response time targets

### Deployment Process

- Infrastructure as Code patterns
- CI/CD pipeline stages
- Environment promotion (staging -> production)
- Rollback procedures

## Templates

| Template | Purpose |
|----------|---------|
| PRD | Product Requirements Document with user stories, acceptance criteria |
| Technical Design | Architecture, domain model, API design, implementation plan |
| ADR | Architecture Decision Record for significant technical decisions |
| AgDR | Agent Decision Record -- AI-specific decision tracking |

## Customization

ApexStack is designed to be customized. Every role, workflow, and template can be modified to fit your team:

1. **Add roles**: Create new `.md` files in `roles/your-department/`
2. **Modify workflows**: Edit files in `workflows/`
3. **Add templates**: Drop new templates in `templates/`
4. **Override anything**: The stack is just markdown files -- edit freely

## Contributing

Contributions are welcome. Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with a clear description

## License

MIT License. See [LICENSE](LICENSE) for details.

---

Built with real-world experience shipping software with Claude Code.
