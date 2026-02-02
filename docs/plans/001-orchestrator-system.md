# WeMoney Agent Orchestration System - Implementation Plan

## Pre-Implementation: Preserve Context (CRITICAL)

Before any implementation, commit all planning artifacts to preserve tribal knowledge for future agents.

### Artifacts to Commit

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Orchestrator memory - service inventory, architecture decisions |
| `.claude/plans/gentle-bubbling-nygaard.md` | This plan file - decision trail |
| `loose_files/full_doc.md` | Palantir ontology thinking - foundational reference |
| `loose_files/glean_founder_thoughts.md` | NL query examples - user intent patterns |
| `loose_files/DATA_CATALOG.md` | Schema documentation - data model reference |

### Commit Message Template
```
feat(orchestrator): preserve planning context for audit trail

Decision trail for WeMoney Agent Orchestration System:
- Service inventory captured (50+ repos analyzed)
- Architecture: Model/Context/Tool/Prompt
- Ontology synced from we-money/glean
- Permission model: safe/medium/dangerous
- Repository strategy: worktrees + deterministic scripts

References:
- Palantir Foundry ontology patterns
- Jessica Talisman on semantic layers vs ontologies
```

### Why This Matters

Future agents exploring this repo should be able to:
1. Understand WHY decisions were made (not just WHAT)
2. Reference original tribal knowledge sources
3. Trace the evolution of the orchestrator
4. Avoid re-discovering patterns already documented

---

## Vision Statement

Build an **agent orchestration operating system** that encapsulates the WeMoney service cluster into a unified, agent-directed monorepo. The orchestrator controls services with **mandatory human intervention** unless explicit permissions are granted.

**End State**: Each service becomes an agent-aware module. The orchestrator maintains pulse on the entire codebase, coordinating deterministic application code with intelligent agent layers.

---

## WeMoney Service Inventory

### Core Applications (Deterministic Code Layer)

| Service | Language | Purpose | Agent Priority |
|---------|----------|---------|----------------|
| **brightmatch** | Go | Loan matching, applications, serviceability | HIGH - vertical slice |
| **wemoney-backend** | Go | API gateway to all services | HIGH |
| **wemoney-mobile-app** | TypeScript | React Native frontend | MEDIUM |
| **brightmatch-admin-portal** | TypeScript | Admin view for transactions/credit | MEDIUM |

### Data & Intelligence Layer

| Service | Language | Purpose |
|---------|----------|---------|
| **glean** | TypeScript | NL data querying (HAS ONTOLOGY) |
| **brightmatch-data-catalogue** | TypeScript | Field catalogue (HAS .claude/) |
| **data-platform** | PLpgSQL | IaC for Redshift |
| **categorizer** | Go | Transaction categorization |
| **txformer** | Python | Transformer-based categorization |

### Supporting Services

| Service | Language | Purpose |
|---------|----------|---------|
| **open-banker** | Go | CDR/Open Banking aggregation |
| **creditor** | Go | Credit bureau integration |
| **usermanager** | Go | User management |
| **offerer** | Go | Offer generation |
| **notifier** | Go | Push/email notifications |
| **yodler** | Go | Yodlee aggregation |
| **budgeter** / **cdr-budgeter** | Go | Budget management |

### Infrastructure (DANGEROUS - Confirm Each)

| Service | Language | Purpose |
|---------|----------|---------|
| **shared-infrastructure** | HCL | Core AWS infra |
| **aws-org** | HCL | AWS Organization IaC |
| **automation-iam** | HCL | IAM modules |

---

## Architecture: Model / Context / Tool / Prompt

### Model (Ontology) — EXISTS IN `we-money/glean`

**Discovered Pattern:**
```
glean/ontology/
├── objects/           # Entity definitions (YAML)
│   ├── member.yml
│   ├── loan_application.yml
│   ├── credit_scores.yml
│   └── ... (13 objects total)
└── links/             # Relationships
    ├── member_daily_cac.yml
    └── member_loan_applications.yml
```

**Example (member.yml):**
```yaml
object_name: member
description: Details pertaining to a WeMoney member
fields:
  - name: fully_onboarded_at
    type: datetime
    description: Date when member completed onboarding
    aliases: [FOBM, FOBM Date, Initial Bank Connect]
  - name: ourmoneymarket_eligible
    type: boolean
    description: Eligible for OurMoneyMarket debt consolidation
```

**Key Insight**: Glean already has the semantic layer (objects + links). Missing: Kinetic layer (actions) and Dynamic layer (governance).

### Context (Knowledge Base)

| Source | Location | Purpose |
|--------|----------|---------|
| Data Catalog | `DATA_CATALOG.md` | Schema for `wm_cleansed` |
| Ontology Objects | `glean/ontology/objects/` | Business entities |
| Ontology Links | `glean/ontology/links/` | Relationships |
| Tribal Knowledge | Slack history | Vernacular, edge cases |
| Lender Rules | `brightmatch/rules/` | Approval criteria |

### Tool (Connectors)

**Safe (Agent can use freely):**
- Slack, ClickUp, Google Suite, AirTable
- Splunk, Honeycomb (read-only observability)

**Medium Risk (Agent proposes, user confirms batch):**
- Vercel (deployments)
- n8n (workflow automation)
- PagerDuty (incident response)

**Dangerous (Confirm EACH command):**
- AWS CLI, Terraform, Google Cloud
- Any `shared-infrastructure` or `aws-org` operations

### Prompt (Skills)

```
.claude/skills/
├── orchestrator/              # Super-agent: coordinates all services
│   └── SKILL.md
├── services/                  # Per-service agent contexts
│   ├── brightmatch/
│   ├── wemoney-backend/
│   └── ...
├── data-catalogue/            # Ontology management
│   ├── SKILL.md
│   └── ontology/              # Synced from glean
├── connectors/                # Tool integrations
└── fork-terminal/             # Agent spawning (existing)
```

---

## Phase 1: Vertical Slice (brightmatch + ontology)

### Objective
Build end-to-end agent control for ONE service (brightmatch) with full ontology support.

### Deliverables

#### 1. CLAUDE.md (Orchestrator Memory)
Root-level project memory for the orchestrator. Includes:
- Service inventory with ownership
- Ontology reference pointers
- Permission model (safe/medium/dangerous)
- Workflow patterns for common operations

#### 2. Data Catalogue Skill
`.claude/skills/data-catalogue/SKILL.md`

**Triggers:** "update ontology", "what is [term]", "how does X relate to Y"

**Workflow:**
1. Maintain sync with `we-money/glean/ontology/`
2. Track source → derivation → display chain
3. Validate changes against existing definitions
4. Document in `docs/` as markdown

**Ontology Structure (synced from glean):**
```
.claude/skills/data-catalogue/
├── SKILL.md
├── ontology/
│   ├── objects/          # Synced from glean
│   ├── links/            # Synced from glean
│   └── actions/          # NEW: Kinetic layer
└── docs/                 # Human-readable docs
```

#### 3. Brightmatch Service Skill
`.claude/skills/services/brightmatch/SKILL.md`

**Context:**
- Hexagonal architecture (domain/ports/adapters)
- Event sourcing for business logic
- Modules: loanapplication, matchingengine, memberinsight, etc.
- Rules engine: Grule

**Capabilities:**
- Read module READMEs for context
- Run tests: `bash ./scripts/lint.sh`, `bash ./scripts/build.sh`
- Navigate hexagonal structure
- Understand event sourcing patterns

#### 4. Orchestrator Skill
`.claude/skills/orchestrator/SKILL.md`

**Purpose:** Coordinate multi-service operations

**Permission Model:**
```yaml
permissions:
  default: CONFIRM_EACH  # Human approves each command

  safe_operations:       # Agent can execute freely
    - read files
    - run tests
    - generate documentation
    - query ontology

  batch_confirm:         # Human confirms batch
    - deploy to staging
    - update dependencies
    - create PRs

  confirm_each:          # Human confirms EACH command
    - terraform apply
    - aws cli mutations
    - production deployments
```

---

## Phase 2: Expand Service Coverage

### Objective
Encapsulate additional services into agent-aware modules.

### Priority Order
1. **wemoney-backend** — API gateway, central coordination point
2. **glean** — Already has ontology, add agent layer
3. **categorizer** — Transaction intelligence
4. **open-banker** — CDR data flow

### Per-Service Skill Template
```
.claude/skills/services/<service>/
├── SKILL.md           # Agent instructions
├── context/           # Service-specific knowledge
│   ├── architecture.md
│   ├── modules.md
│   └── testing.md
└── workflows/         # Common operations
    ├── deploy.md
    ├── debug.md
    └── extend.md
```

---

## Phase 3: Connector Framework

### Objective
MCP servers for external tool integration.

### Architecture
```
.claude/mcp/
├── slack/             # Communication + tribal knowledge
├── clickup/           # Task lifecycle
├── redshift/          # Data queries
├── honeycomb/         # Observability (read-only)
└── github/            # Code operations
```

### Priority
1. **GitHub** — PR creation, issue tracking, code search
2. **Slack** — Notifications, tribal knowledge mining
3. **ClickUp** — Task lifecycle management
4. **Redshift** — Query execution for ontology validation

---

## Repository Strategy

### Approach: Worktrees + Deterministic Sync Scripts

**Current State**: Local development repo (jay-nicholson/fork-repository-skill)
**Promoted Name**: `wemoney-orchestrator` (when earned)

**Environment Variable:**
```bash
ORCHESTRATOR_STATUS=local  # Options: local | promoted
# TODO: Remove this once promoted to we-money/wemoney-orchestrator
```

### Purpose: Deterministic Harness

This repo is the **harness layer** between:
- **Deployed code** (deterministic application layer)
- **Observability** (Splunk, Honeycomb, PagerDuty)

**Agent Responsibilities:**
- Compare diffs against main branch
- Respond to GitHub checks
- Monitor deployment status
- Bridge code changes → observability signals

**Sync Strategy:**
- Agent creates **git worktrees** or **branches** for each service
- **Deterministic scripts** handle sync (not manual agent actions)
- Scripts can be triggered via hooks or scheduled runs

### Structure
```
wemoney-orchestrator/
├── CLAUDE.md                   # Orchestrator memory
├── .claude/
│   ├── skills/
│   │   ├── orchestrator/       # Central coordination
│   │   ├── data-catalogue/     # Ontology management
│   │   └── services/           # Per-service agent contexts
│   └── mcp/                    # Tool connectors
├── scripts/
│   └── sync/
│       ├── sync-ontology.sh    # Pull glean/ontology/* → local
│       ├── sync-service.sh     # Clone/update service worktree
│       └── sync-all.sh         # Full sync orchestration
├── worktrees/                  # Git worktrees for services (gitignored)
│   ├── brightmatch/            # worktree: we-money/brightmatch
│   ├── glean/                  # worktree: we-money/glean
│   └── ...
├── docs/                       # Generated documentation
└── loose_files/                # Reference materials
```

### Sync Scripts (Deterministic)

**`scripts/sync/sync-ontology.sh`:**
```bash
#!/bin/bash
# Sync ontology from glean to local
gh api repos/we-money/glean/contents/ontology/objects --jq '.[].name' | \
  while read file; do
    gh api repos/we-money/glean/contents/ontology/objects/$file \
      --jq '.content' | base64 -d > .claude/skills/data-catalogue/ontology/objects/$file
  done
```

**`scripts/sync/sync-service.sh`:**
```bash
#!/bin/bash
# Create or update worktree for a service
SERVICE=$1
if [ ! -d "worktrees/$SERVICE" ]; then
  git worktree add worktrees/$SERVICE -b sync/$SERVICE
  cd worktrees/$SERVICE
  gh repo clone we-money/$SERVICE .
else
  cd worktrees/$SERVICE && git pull
fi
```

### Coordination Patterns
- **Pulse Check**: Run sync, then check service health across worktrees
- **Cross-Service Query**: "Which services handle member data?" → Search across worktrees
- **Coordinated Deploy**: Stage → Test → Promote via scripts
- **Incident Response**: Trace issues across worktrees

---

## Files to Create (Phase 1)

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Orchestrator memory with service inventory |
| `.claude/skills/orchestrator/SKILL.md` | Central coordination skill |
| `.claude/skills/data-catalogue/SKILL.md` | Ontology management |
| `.claude/skills/data-catalogue/ontology/objects/` | Synced from glean |
| `.claude/skills/data-catalogue/ontology/links/` | Synced from glean |
| `.claude/skills/data-catalogue/ontology/actions/` | NEW: Kinetic layer |
| `.claude/skills/services/brightmatch/SKILL.md` | Brightmatch agent context |
| `scripts/sync/sync-ontology.sh` | Deterministic ontology sync |
| `scripts/sync/sync-service.sh` | Deterministic service worktree sync |
| `scripts/sync/sync-all.sh` | Full sync orchestration |
| `.gitignore` | Ignore worktrees/ directory |

---

## Verification

### Phase 1 Tests
1. **Ontology Query**: "What is an FOBM?" → Returns business definition with aliases
2. **Service Context**: "How does brightmatch handle loan applications?" → Navigates hexagonal structure
3. **Permission Check**: "Deploy to production" → Requires explicit confirmation
4. **Sync Test**: Run `scripts/sync/sync-ontology.sh` → Ontology files appear locally

### Integration Tests
1. Fork agent to analyze brightmatch module
2. Agent proposes PR with test coverage
3. Human reviews and approves
4. Agent executes merge

### Harness Verification
1. **Diff Check**: Agent compares branch against main, reports changes
2. **GitHub Checks**: Agent responds to check status (pass/fail/pending)
3. **Observability Bridge**: Change in code → expected signal in Honeycomb/Splunk

---

## Key References

### Internal
- `we-money/glean` — Existing ontology (objects/, links/)
- `we-money/brightmatch` — Vertical slice target
- `we-money/brightmatch-data-catalogue` — Has .claude/ setup
- `loose_files/full_doc.md` — Palantir ontology thinking

### External
- Palantir Foundry Ontology documentation
- Jessica Talisman, "Ontologies, Context Graphs, and Semantic Layers"

---

## The North Star

> "Which members should get a consolidation offer today and what should it say?"

**Requires:**
- **Ontology**: Member → Goal → FinancialProfile → LenderCriteria → Offer
- **Context**: Business rules, lender criteria, approval thresholds
- **Tools**: Redshift query, notification trigger, email generation
- **Permission**: Human confirms member list before sending

**This is the shift from retrieval to action — with human oversight.**

---

## Audit Trail & Knowledge Preservation

### Commit Strategy

The orchestrator maintains an audit trail through deliberate commits at checkpoints:

**Checkpoint Types:**
| Type | When | What to Commit |
|------|------|----------------|
| **Planning** | After plan approval | Plan file, decision context |
| **Discovery** | After exploration | Findings, service analysis |
| **Implementation** | After each deliverable | Code + rationale in commit message |
| **Sync** | After ontology/service sync | Updated files + sync metadata |

### Knowledge Files

```
docs/
├── decisions/           # Architecture Decision Records (ADRs)
│   ├── 001-model-context-tool-prompt.md
│   ├── 002-permission-model.md
│   └── 003-worktree-strategy.md
├── exploration/         # Service analysis notes
│   ├── brightmatch.md
│   ├── glean.md
│   └── ...
└── tribal/              # Captured tribal knowledge
    ├── vernacular.md    # FOBM, CAC, RPM definitions
    └── patterns.md      # Common code patterns
```

### Git History as Memory

Each commit should be meaningful enough that an agent reading `git log --oneline` can understand the project evolution:

```
abc1234 feat(orchestrator): add permission model for dangerous ops
def5678 docs(tribal): capture FOBM definition from Slack
ghi9012 sync(ontology): update member.yml from glean
jkl3456 feat(brightmatch): add service skill with hexagonal context
```

### Remote Sync

Push to remote after each checkpoint to ensure:
1. Knowledge is not lost on local machine failure
2. Other agents can access the trail
3. Team visibility into orchestrator evolution
