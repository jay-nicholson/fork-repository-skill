---
name: Data Catalogue
description: Manage the WeMoney data catalogue and ontology. Use this when the user asks about data definitions, relationships between entities, derivations, or needs to update models. Triggers on 'what is [term]', 'how does X relate to Y', 'update ontology', 'data catalogue', 'derivation', 'model'.
---

# Purpose

Manage the WeMoney data catalogue - the semantic layer that defines business meaning for data entities. This skill maintains the source → derivation → display chain for all data objects.

## Architecture

The data catalogue follows a **3-Tier Model**:

1. **Models** = Source data (DB tables, APIs, events)
2. **Operations** = Built-in primitives (min, max, select, filter, etc.)
3. **Derivations** = Step-based pipelines chaining operations

## Variables

SOURCE_REPO: we-money/brightmatch-data-catalogue
MODELS_PATH: public/data-catalogue/models/
DERIVATIONS_PATH: public/data-catalogue/derivations/
DOCS_PATH: docs/
VALIDATION_API: http://localhost:3000/api/validate
LOCAL_CACHE: .claude/skills/data-catalogue/ontology/
SYNC_MANIFEST: .claude/skills/data-catalogue/.sync-manifest.json

## Source Repository Structure

The canonical source of truth is `we-money/brightmatch-data-catalogue`:

```
brightmatch-data-catalogue/
├── public/data-catalogue/
│   ├── models/              # JSON model definitions
│   │   ├── loan_application/
│   │   ├── member/
│   │   ├── credit_score/
│   │   └── ...
│   └── derivations/         # JSON derivation pipelines
│       ├── filter_user_loan_applications.json
│       ├── extract_declared_primary_income.json
│       └── ...
├── docs/
│   ├── INDEX.md             # Agent entry point
│   ├── spec/                # Master specifications
│   ├── json/                # JSON creation guides
│   ├── derivations/         # Model relationships
│   ├── quickstart/          # Implementation guides
│   └── validation/          # QA procedures
└── .claude/
    └── CLAUDE.md            # Agent-specific guidance
```

## Instructions

### Query Models

When the user asks "what is [term]" or "define [term]":

1. Search `public/data-catalogue/models/` for matching model
2. Check for aliases in field definitions
3. Return business definition with source tracing

**Example:**
```bash
gh api repos/we-money/brightmatch-data-catalogue/contents/public/data-catalogue/models/member/_root.json --jq '.content' | base64 -d | jq
```

### Query Derivations

When the user asks "how is X calculated" or "what derives Y":

1. Search `public/data-catalogue/derivations/` for matching derivation
2. Trace `depends_on` chain to understand data flow
3. Explain the derivation pattern (filter, select, aggregate, etc.)

**Derivation Patterns:**
| Pattern | Description |
|---------|-------------|
| `filter` | Filter records by condition (WHERE user_id = :user_id) |
| `select` | Pick one from many (latest by submitted_at) |
| `transform` | Convert value format |
| `aggregate` | Combine multiple values (sum, count) |
| `coalesce` | First non-null from sources |
| `min/max` | Conservative min/max logic |
| `lookup` | Table-based derivation (HEM, housing floor) |
| `rule_evaluation` | GRL rules engine |

### The Ralph Loop (Creating Derivations)

When creating derivations, follow this 3-step pattern:

**Step 1: EXPLORE**
```bash
# Check source model exists
gh api repos/we-money/brightmatch-data-catalogue/contents/public/data-catalogue/models/{model}/_root.json
```

**Step 2: UPDATE**
- Create derivation JSON following schema
- Add `depends_on.derivations` for upstream dependencies

**Step 3: VALIDATE**
```bash
# Requires local dev server running
curl -s http://localhost:3000/api/validate?type=derivations | jq '.errors'
```

**CRITICAL:** Do not claim completion until validation returns 0 errors.

### Serviceability Flow

The key derivation chain for loan serviceability:

```
loan_application → Declared values (user-provided)
user_transaction_analysis → Detected values (from streams)
                                    ↓
Adjusted values = min/max(declared, detected, benchmarks)
                                    ↓
total_income - total_expenses = net_capacity
```

**Conservative Logic:**
- Income: `min(detected, declared)` - use lower value
- Expenses: `max(detected, declared, benchmark)` - use higher value

## Key Models by Source Type

### Database Sources
| Model | Database | Table |
|-------|----------|-------|
| `user_lender_outcomes` | brightmatch | user_lender_outcomes |
| `loan_application_event` | brightmatch | events |
| `consent` | openbanker | consents |
| `user_transaction_analysis` | categorizer | user_transaction_analysis |

### HTTP API Sources
| Model | Service |
|-------|---------|
| `member` | usermanager |
| `credit_report` | creditor |

### Derived Models
| Model | Derives From |
|-------|--------------|
| `portal_pipeline_member` | member, combined_profile, user_lender_outcomes, loan_application |
| `portal_admin_member` | member, combined_profile, consents, credit_reports, loan_applications |

## Completed Derivations

| Category | Derivations |
|----------|-------------|
| User Filters | `filter_user_loan_applications`, `select_user_transactions` |
| Stream Processing | `group_transactions_into_streams`, `categorize_streams` |
| Detected (streams) | `extract_*_from_streams` (income, housing, loans, living) |
| Declared (loan_app) | `extract_declared_*` (income, housing, living) |
| Benchmarks | `lookup_hem_benchmark`, `lookup_housing_floor` |
| Calculation | `calculate_net_capacity` |

## Vernacular

| Term | Definition |
|------|------------|
| FOBM | Fully Onboarded Member - completed all onboarding steps |
| CAC | Customer Acquisition Cost |
| RPM | Revenue Per Member |
| CDR | Consumer Data Right (Open Banking) |
| BrightMatch | Loan matching product/portal |
| HEM | Household Expenditure Measure (benchmark) |
| GRL | Grule Rules Language |

## Source Code Tracing

Key source files for derivation logic:

| Derivation Type | Go Source Location |
|-----------------|-------------------|
| Stream grouping | `categorizer/analysis/analysis.go:333-432` |
| Stream categorization | `categorizer/analysis/rules.go:1029-1049` |
| Detected values | `brightmatch/src/shared/queries/member/map_detected.go` |
| Declared values | `brightmatch/src/shared/queries/member/map_declared.go` |
| HEM benchmark | `brightmatch/src/shared/queries/member/map_hem.go:66-94` |
| Net capacity | `brightmatch/src/shared/queries/member/calculate_net_capacity.go:46-158` |
| Rule evaluation | `brightmatch/src/shared/matchingengine/engine.go:126-160` |

## Sync Workflow (Closed Loop)

The data catalogue follows a closed-loop sync pattern:

```
PULL → EDIT → VALIDATE → PUSH → PULL
```

### Commands

| Command | Purpose | Permission |
|---------|---------|------------|
| `./scripts/sync/sync-data-catalogue.sh --full` | Full sync from remote | SAFE |
| `./scripts/sync/sync-data-catalogue.sh --incremental` | Skip if in sync | SAFE |
| `./scripts/sync/check-drift.sh` | Check if local has drifted | SAFE |
| `./scripts/sync/validate-local.sh` | Validate local JSON | SAFE |
| `./scripts/sync/push-changes.sh` | Create PR from local edits | BATCH_CONFIRM |

### Local Cache Structure

```
.claude/skills/data-catalogue/
├── .sync-manifest.json          # Sync state tracking
├── ontology/
│   ├── objects/                 # Synced models
│   │   ├── member/_root.json
│   │   ├── loan_application/_root.json
│   │   └── ...
│   ├── derivations/             # Synced derivations
│   │   ├── serviceability/
│   │   └── ...
│   ├── links/                   # (future)
│   └── actions/                 # (future kinetic layer)
└── docs/                        # Synced documentation
```

### When to Sync

1. **Starting a session** — Run `check-drift.sh` to see if updates available
2. **Before editing ontology** — Ensure local cache is current
3. **After pushing changes** — Pull to close the loop
4. **Investigating data issues** — Fresh sync ensures accuracy

### Manifest

The `.sync-manifest.json` tracks:
- Source commit SHA
- Sync timestamp
- List of synced models and derivation categories

Use `jq` to inspect:
```bash
jq . .claude/skills/data-catalogue/.sync-manifest.json
```
