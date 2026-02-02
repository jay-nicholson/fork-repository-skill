# WeMoney Agent Orchestration System

## Project Purpose

This repository is being transformed from a fork-terminal skill into an **agent orchestration operating system** for the WeMoney engineering organization.

## Architecture: Model / Context / Tool / Prompt

### Model (Ontology)
The ontology defines what exists in the WeMoney universe. NOT just schema documentation - business meaning.

**Palantir-inspired layers:**
- **Semantic** — Objects, Properties, Links (Member, FinancialProfile, Goal, Application, Lender, LenderCriteria)
- **Kinetic** — Actions and Functions (generate_offer, send_nudge, request_testimonial)
- **Dynamic** — Security, governance, evolution

**Key derived properties:**
- Approval Probability = f(FinancialProfile, LenderCriteria)
- Savings Potential = f(Current Debt, Available Offers)
- Conversion Likelihood = f(Goal Alignment, Engagement Signals, Approval Probability)

### Context (Knowledge Base)
- `DATA_CATALOG.md` — Schema for `wm_cleansed` in Redshift
- Lender criteria rules
- Slack tribal knowledge
- Amplitude product behavior

### Tool (Connectors)
MCP servers for: Slack, ClickUp, Google Suite, AirTable, Splunk, Honeycomb, PagerDuty, Vercel, n8n

**DANGEROUS - Confirm each command:** AWS CLI, Terraform, Google Cloud

### Prompt (Skills)
Skills that orchestrate agent work threads.

## Key Business Concepts

### WeMoney Vernacular
- **FOBM** — Fully Onboarded Member (completed onboarding flow)
- **BrightMatch** — Loan matching product (portal module)
- **CAC** — Customer Acquisition Cost
- **RPM** — Revenue Per Member
- **CDR** — Consumer Data Right (Open Banking)

### The "Mary Journey" (North Star)
1. Mary downloads WeMoney after seeing ad
2. Sets debt consolidation goal during onboarding
3. CDR shows 82% credit utilization
4. Agent identifies: high-intent, approvable, not converted
5. Personalized push: "Mary, 3 lenders could save you $247/month"
6. She applies, gets approved, leaves testimonial
7. Testimonial feeds next ad cycle → flywheel

### The Golden Question
> "Which members should get a consolidation offer today and what should it say?"

This requires ontology + context + tools + prompts working together.

## Repository Structure

```
.claude/
├── skills/
│   ├── fork-terminal/          # Agent spawning (existing)
│   ├── data-catalogue/         # Ontology management (Phase 1)
│   └── orchestrator/           # Multi-agent coordination (Phase 3)
├── mcp/                        # MCP server connectors (Phase 2)
└── commands/
    └── prime.md                # Bootstrap context

loose_files/                    # Reference documents
├── full_doc.md                 # Palantir ontology thinking
├── glean_founder_thoughts.md   # NL query examples
└── DATA_CATALOG.md             # wm_cleansed schema
```

## Phase Plan

1. **Phase 1: Ontology Foundation** — Transform DATA_CATALOG into true ontology
2. **Phase 2: Connector Framework** — MCP servers for tool integrations
3. **Phase 3: Agent Orchestration** — Sub-agent spawning with skill inheritance

## Key References

- Palantir Foundry Ontology documentation
- Jessica Talisman, "Ontologies, Context Graphs, and Semantic Layers: What AI Actually Needs in 2026"
- Uber QueryGPT, Airbnb Minerva, ThoughtSpot (see full_doc.md for links)

## External Integrations

### we-money/glean
Starting point for data agent. Reference for ontology design.

### we-money/brightmatch → portal
The module this ontology serves. Upstream sources flow through here.

## Commits

Commit regularly at checkpoints. Track lifecycle in ClickUp.
