---
name: BrightMatch Service
description: Context for working with the BrightMatch loan matching service. Use when the user asks about loan applications, matching engine, serviceability, or BrightMatch modules.
---

# Purpose

Provide agent context for working with the BrightMatch service - a Go-based monorepo providing loan matching, applications, and serviceability assessment for WeMoney.

## Repository

**Source:** `we-money/brightmatch`
**Language:** Go 1.24+
**Architecture:** Hexagonal (ports/adapters)

## Architecture Overview

### Hexagonal Pattern

```
modules/<module>/
├── module/          # HTTP handlers, routes, module registration
├── domain/          # Core business logic (NO external dependencies)
│   ├── commands/    # Command objects for write operations
│   ├── events/      # Domain events
│   ├── queries/     # Query objects for read operations
│   ├── valueobjects/# Value objects and validations
│   └── ports/       # Driven port interfaces
└── adapters/        # External system implementations (database, APIs)
```

### Event Sourcing

Core business logic uses event sourcing:
- Events stored in PostgreSQL `events` table
- Projections built from event streams
- Loan applications reconstructed from event history

## Modules

### Business Modules

| Module | Path | Purpose |
|--------|------|---------|
| Loan Application v1 | `src/modules/loanapplication/v1/` | Original workflow with direct lender integration |
| Loan Application v2 | `src/modules/loanapplication/v2/` | Enhanced with matching engine |
| Serviceability Wizard | `src/modules/serviceabilitywizard/` | Multi-step loan assessment |
| Member Insight | `src/modules/memberinsight/` | Member profile and credit insights |
| Matching Engine | `src/modules/matchingengine/` | Rules-based loan product matching |
| Product Catalogue | `src/modules/productcatalogue/` | Loan products and lender info |

### Integration Modules

| Module | Path | Purpose |
|--------|------|---------|
| Relay | `src/modules/relay/` | External lender webhook handler |
| Payslip Upload | `src/modules/payslipupload/` | Document upload service |

### Operational Modules

| Module | Path | Purpose |
|--------|------|---------|
| Health | `src/modules/health/` | System health check |
| Admin | `src/modules/admin/` | Administrative operations |

## Technology Stack

| Component | Technology |
|-----------|------------|
| Language | Go 1.24+ |
| Database | PostgreSQL (event store + projections) |
| Auth | AWS Cognito |
| Job Queue | River (PostgreSQL-based) |
| Rules Engine | Grule (GRL) |
| Storage | AWS S3 (documents) |
| Deploy | Kubernetes (Helm charts) |

## Development Commands

```bash
# Lint the codebase
bash ./scripts/lint.sh

# Build the application
bash ./scripts/build.sh

# Run tests
go test ./...

# Run specific module tests
go test ./src/modules/loanapplication/...
```

## Rules Engine (Grule)

Lender eligibility rules are defined in GRL (Grule Rule Language):

**Location:** `rules/`

**Key concepts:**
- Rules evaluate member data against lender criteria
- Each lender has its own rule set
- Rules return eligibility boolean + reasons

**Source tracing:**
- Rule evaluation: `src/shared/matchingengine/engine.go:126-160`

## Key Source Files

| Purpose | Location |
|---------|----------|
| Event store | `src/core/eventstore/` |
| Module interface | `src/core/module.go` |
| Matching engine | `src/modules/matchingengine/` |
| Serviceability | `src/modules/serviceabilitywizard/` |
| Net capacity calc | `src/shared/queries/member/calculate_net_capacity.go` |
| HEM benchmark | `src/shared/queries/member/map_hem.go` |
| Detected values | `src/shared/queries/member/map_detected.go` |
| Declared values | `src/shared/queries/member/map_declared.go` |

## Working with BrightMatch

### Cloning to Worktree

```bash
bash scripts/sync/sync-service.sh brightmatch
cd worktrees/brightmatch
```

### Understanding a Module

1. Read module README: `src/modules/<name>/README.md`
2. Check domain model: `src/modules/<name>/domain/`
3. Review ports: `src/modules/<name>/domain/ports/`
4. Trace adapters: `src/modules/<name>/adapters/`

### Adding a Feature

1. Define domain commands/events first
2. Implement port interfaces
3. Build adapters for external systems
4. Register routes in module.go
5. Add tests for each layer

## Related Services

| Service | Relation |
|---------|----------|
| `wemoney-backend` | API gateway that routes to BrightMatch |
| `categorizer` | Provides transaction analysis for serviceability |
| `creditor` | Provides credit scores for matching |
| `open-banker` | Provides CDR data for analysis |
| `brightmatch-data-catalogue` | Documents all models and derivations |
