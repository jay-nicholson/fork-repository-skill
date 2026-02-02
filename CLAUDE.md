# WeMoney Agent Orchestration System

## Production Control Environment

This repository is the **control plane** for the WeMoney engineering organization's codebase. It coordinates AI agents that maintain, monitor, and evolve 50+ services with mandatory human oversight.

**Status:** `ORCHESTRATOR_STATUS=local` (not yet promoted to we-money org)

---

## Core Responsibilities

### 1. Harness Layer
Bridge between deployed code and observability:
- Compare diffs against main branch
- Respond to GitHub checks
- Monitor deployment status
- Trace code changes → observability signals

### 2. Permission Enforcement
All operations require appropriate oversight:
```
SAFE:           Read, search, test, document
BATCH_CONFIRM:  Deploy staging, create PRs, sync
CONFIRM_EACH:   Terraform, AWS, production, databases
```

### 3. Audit Trail
Every significant action is committed with context:
- WHY decisions were made
- WHAT was changed
- WHERE to trace source

---

## Service Inventory

### Tier 1: Core Applications
| Service | Repo | Language | Purpose |
|---------|------|----------|---------|
| brightmatch | we-money/brightmatch | Go | Loan matching, serviceability |
| wemoney-backend | we-money/wemoney-backend | Go | API gateway |
| brightmatch-data-catalogue | we-money/brightmatch-data-catalogue | TypeScript | Ontology source of truth |

### Tier 2: Data & Intelligence
| Service | Repo | Purpose |
|---------|------|---------|
| glean | we-money/glean | NL data querying |
| categorizer | we-money/categorizer | Transaction categorization |
| txformer | we-money/txformer | ML categorization |
| data-platform | we-money/data-platform | Redshift IaC |

### Tier 3: Supporting Services
| Service | Purpose |
|---------|---------|
| open-banker | CDR/Open Banking |
| creditor | Credit bureau integration |
| usermanager | User management |
| offerer | Offer generation |
| notifier | Push/email notifications |

### Tier 4: Infrastructure (DANGEROUS)
| Service | Purpose | Risk |
|---------|---------|------|
| shared-infrastructure | Core AWS infra | CONFIRM_EACH |
| aws-org | AWS Organization | CONFIRM_EACH |
| automation-iam | IAM modules | CONFIRM_EACH |

---

## Architecture: Model / Context / Tool / Prompt

### Model (Ontology)
**Source of truth:** `we-money/brightmatch-data-catalogue`

3-Tier structure:
- **Models** = Source data (DB tables, APIs, events)
- **Operations** = Primitives (filter, select, aggregate, min, max)
- **Derivations** = Pipelines chaining operations

Key pattern: **Ralph Loop** (EXPLORE → UPDATE → VALIDATE)

### Context (Knowledge Base)
| Source | Location |
|--------|----------|
| Data models | `brightmatch-data-catalogue/public/data-catalogue/models/` |
| Derivations | `brightmatch-data-catalogue/public/data-catalogue/derivations/` |
| Documentation | `brightmatch-data-catalogue/docs/` |
| Tribal knowledge | Slack history (to be mined) |

### Tool (Connectors)
**Implemented:**
- GitHub (`gh` CLI)
- ClickUp (MCP server via `.mcp.json`)

**Planned:**
- Slack (pending official MCP release), Redshift, Honeycomb, Splunk

**Setup:** Run `/install` for onboarding or see `.env.example` for required credentials.

### Prompt (Skills)
```
.claude/skills/
├── orchestrator/           # Central coordination, permissions
├── data-catalogue/         # Ontology management
├── services/
│   └── brightmatch/        # Service-specific context
└── fork-terminal/          # Agent spawning
```

---

## Key Business Concepts

### Vernacular
| Term | Meaning |
|------|---------|
| FOBM | Fully Onboarded Member |
| CAC | Customer Acquisition Cost |
| RPM | Revenue Per Member |
| CDR | Consumer Data Right (Open Banking) |
| BrightMatch | Loan matching portal |
| HEM | Household Expenditure Measure |

### The North Star
> "Which members should get a consolidation offer today and what should it say?"

This requires:
- Ontology (Member → Goal → FinancialProfile → LenderCriteria → Offer)
- Context (business rules, approval thresholds)
- Tools (Redshift query, notification trigger)
- Permission (human confirms before sending)

---

## Repository Structure

```
wemoney-orchestrator/
├── CLAUDE.md                    # This file - orchestrator memory
├── .claude/
│   ├── skills/
│   │   ├── orchestrator/        # Central coordination
│   │   ├── data-catalogue/      # Ontology management
│   │   └── services/            # Per-service contexts
│   └── commands/
│       └── prime.md             # Context bootstrap
├── scripts/
│   └── sync/                    # Deterministic sync scripts
├── docs/
│   └── plans/                   # Decision trail
├── worktrees/                   # Cloned services (gitignored)
└── loose_files/                 # Reference materials
```

---

## Workflow

### Starting a Session
1. Run `/install` if first time (checks tools, env vars, MCP connections)
2. Run `/prime` to load context
3. Check `git status` and recent commits
4. Review task list or plan
5. Confirm permission level for planned work

### During Work
1. Commit at meaningful checkpoints
2. Push regularly to preserve audit trail
3. Document decisions in commit messages
4. Respect permission boundaries

### Completing Work
1. Run relevant tests
2. Create PR if changes ready for review
3. Update task tracking
4. Push final state

---

## External References

### Internal Docs
- `docs/plans/001-orchestrator-system.md` — Implementation plan
- `loose_files/full_doc.md` — Palantir ontology thinking
- `loose_files/glean_founder_thoughts.md` — NL query examples

### External
- Palantir Foundry Ontology documentation
- Jessica Talisman, "Ontologies, Context Graphs, and Semantic Layers"

---

## Commit Convention

```
<type>(<scope>): <description>

Types: feat, fix, docs, refactor, test, sync
Scopes: orchestrator, data-catalogue, brightmatch, phase1, etc.

Always include:
Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```
