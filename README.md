# WeMoney Agent Orchestrator

> An agent orchestration system that coordinates AI agents across 50+ services with mandatory human oversight.

**Status:** `local` (not yet promoted to we-money org)

---

## The North Star

> "Which members should get a consolidation offer today and what should it say?"

This question requires:
- **Ontology** — Member → Goal → FinancialProfile → LenderCriteria → Offer
- **Context** — Business rules, lender criteria, approval thresholds
- **Tools** — Redshift query, notification trigger, email generation
- **Permission** — Human confirms before sending

This is the shift from retrieval to action—with human oversight.

---

## Architecture

```
Model (Ontology)     →  What exists: Objects, Properties, Links
Context (Knowledge)  →  Business rules, tribal knowledge, service docs
Tool (Connectors)    →  GitHub, Slack, Redshift, ClickUp
Prompt (Skills)      →  Agent instructions per domain
```

### Skills

```
.claude/skills/
├── fork-terminal/       # Spawn parallel agents ✓
├── data-catalogue/      # Ontology management ✓
├── orchestrator/        # Central coordination (planned)
└── services/
    ├── brightmatch/     # Loan matching service (planned)
    └── ...              # 50+ services
```

---

## Fork Terminal Skill

Spawn new terminal windows with AI coding agents or raw CLI commands. Useful for delegating work to parallel agents.

### Supported Tools

| Tool | Example | Default Model |
|------|---------|---------------|
| Claude Code | `fork terminal use claude code to...` | opus |
| Codex CLI | `fork terminal use codex to...` | (configurable) |
| Gemini CLI | `fork terminal use gemini to...` | (configurable) |
| Raw CLI | `fork terminal run npm test` | N/A |

### Context Handoff

Pass conversation history to forked agents:

```
fork terminal use claude code to implement the auth module, summarize work so far
```

### Platform Support

| Platform | Status |
|----------|--------|
| macOS | Supported (AppleScript → Terminal.app) |
| Windows | Supported (cmd /k) |
| Linux | Not yet implemented |

---

## Data Catalogue

Two-layer ontology architecture synced from `we-money/brightmatch-data-catalogue`:

```
ENTITIES (enriched)     ← Agents interact here
└─ member.json          ← Source + derivations combined

SOURCES (raw)           ← Synced from data catalogue
└─ member/_root.json    ← DB table schema

DERIVATIONS (raw)       ← Synced from data catalogue
└─ serviceability/      ← Computed transformations
```

### Sync Commands

```bash
# Pull sources + derivations from remote
./scripts/sync/sync-data-catalogue.sh --full

# Check for drift against remote
./scripts/sync/check-drift.sh

# Validate local ontology
./scripts/sync/validate-local.sh
```

---

## Permission Model

All operations require appropriate oversight:

| Level | Operations |
|-------|------------|
| **SAFE** | Read, search, test, document, query ontology |
| **BATCH_CONFIRM** | Deploy staging, create PRs, sync |
| **CONFIRM_EACH** | Terraform, AWS, production, databases |

---

## Repository Structure

```
wemoney-orchestrator/
├── CLAUDE.md                    # Orchestrator memory
├── .claude/
│   ├── skills/
│   │   ├── fork-terminal/       # Agent spawning
│   │   ├── data-catalogue/      # Ontology management
│   │   └── services/            # Per-service contexts
│   └── commands/
├── scripts/
│   └── sync/                    # Deterministic sync scripts
├── docs/
│   └── plans/                   # Decision trail
├── worktrees/                   # Cloned services (gitignored)
└── loose_files/                 # Reference materials
```

---

## Roadmap

### Phase 1: Vertical Slice ✓
- [x] Fork terminal skill
- [x] Data catalogue sync infrastructure
- [x] CLAUDE.md orchestrator memory

### Phase 2: Data Layer
- [x] Sync scripts (sources + derivations)
- [x] Manifest-based drift detection
- [ ] Validation pipeline
- [ ] Entity enrichment (sources + derivations merged)

### Phase 3: Service Coverage
- [ ] Orchestrator skill (central coordination)
- [ ] Brightmatch service skill
- [ ] wemoney-backend service skill
- [ ] Expand to remaining services

### Phase 4: Connectors
- [x] ClickUp (MCP)
- [ ] Slack
- [ ] Redshift
- [ ] Honeycomb
- [ ] GitHub Actions

---

## Installation

1. Copy `.claude/skills/` to your project or `~/.claude/skills/`
2. Copy `scripts/sync/` if using data catalogue features
3. Set up `.mcp.json` for connector integrations
4. Run `/install` for onboarding checks

---

## Key Concepts

### Ontology vs Data Catalogue

> "A data catalogue says: 'This field is usr_crd_scr, it's an integer.'
> An ontology says: 'This represents a Member's creditworthiness, derived from credit bureau data, updated monthly, predicting loan approval probability.'"

We're building an ontology—not just schema documentation.

### The Mary Journey

1. Mary downloads WeMoney after seeing an ad
2. She sets debt consolidation as her goal
3. Her CDR data shows 82% credit utilisation
4. System identifies her as high-intent, approvable, not yet converted
5. She receives a personalised push with 3 matching lenders
6. She applies, gets approved, leaves a testimonial
7. That testimonial feeds the next ad cycle

**This is the flywheel.** The orchestrator enables it.

### Ralph Loop

The core pattern for ontology maintenance:

```
EXPLORE → UPDATE → VALIDATE
```

---

## References

- [Fork Terminal Demo](https://youtu.be/X2ciJedw2vU) — Building the skill from scratch
- [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code)
- `docs/plans/001-orchestrator-system.md` — Full implementation plan
- `docs/plans/002-data-catalogue-sync.md` — Data layer details
- `loose_files/full_doc.md` — Ontology thinking (Palantir patterns)

---

## Contributing

This repo preserves tribal knowledge through deliberate commits:

```
<type>(<scope>): <description>

Types: feat, fix, docs, refactor, test, sync
Scopes: orchestrator, data-catalogue, brightmatch, fork-terminal

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

Every commit should be meaningful enough that an agent reading `git log --oneline` can understand the project evolution.
