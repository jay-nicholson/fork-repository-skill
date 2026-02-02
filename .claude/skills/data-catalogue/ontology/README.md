# Ontology - Local Cache

This directory contains a **synced local cache** of the WeMoney data catalogue from `we-money/brightmatch-data-catalogue`, plus an enrichment layer for agent consumption.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     ONTOLOGY LAYERS                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ENTITIES (enriched)          ← Agents interact here           │
│   └─ member.json               ← Source + derivations combined  │
│   └─ loan_application.json                                      │
│   └─ ...                                                        │
│                                                                 │
│   ─────────────────────────────────────────────────────────     │
│                                                                 │
│   SOURCES (raw)                ← Synced from data catalogue     │
│   └─ member/_root.json         ← DB table schema                │
│   └─ loan_application/_root.json                                │
│                                                                 │
│   DERIVATIONS (raw)            ← Synced from data catalogue     │
│   └─ serviceability/           ← Computed transformations       │
│   └─ extraction/                                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Directory Structure

| Directory | Purpose | Maintained By |
|-----------|---------|---------------|
| `sources/` | Raw DB table schemas (synced) | `sync-data-catalogue.sh` |
| `derivations/` | Raw computed transformations (synced) | `sync-data-catalogue.sh` |
| `entities/` | Enriched objects (source + derivations merged) | Agent + human |
| `links/` | Relationships between entities (future) | Agent + human |
| `actions/` | Kinetic layer operations (future) | Agent + human |

## The Two Layers

### Raw Layer (synced automatically)

**Sources** are DB table schemas from various services:
- `member/` → usermanager database
- `loan_application/` → brightmatch database
- `transaction/` → categorizer database
- etc.

**Derivations** are computed transformations:
- `extraction/` → Extract fields from sources
- `selection/` → Filter and select records
- `serviceability/` → Calculate net capacity
- etc.

### Enriched Layer (agent-maintained)

**Entities** combine sources + derivations into coherent business objects:

```json
// entities/member.json (conceptual)
{
  "name": "member",
  "description": "A WeMoney member with all derived attributes",
  "source": {
    "table": "sources/member/_root.json",
    "service": "usermanager"
  },
  "fields": {
    "id": { "type": "uuid", "source": "raw" },
    "fully_onboarded_at": { "type": "datetime", "source": "raw", "aliases": ["FOBM"] },
    "primary_income": {
      "type": "money",
      "source": "derived",
      "derivation": "extraction/detected_primary_income.json",
      "fallback": "extraction/declared_primary_income.json"
    },
    "net_capacity": {
      "type": "money",
      "source": "derived",
      "derivation": "serviceability/net_capacity.json",
      "depends_on": ["total_income", "total_expenses"]
    }
  }
}
```

This gives agents a single coherent object to reason about, rather than tracing through derivation chains.

## Sync Workflow (Closed Loop)

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

### When to Sync

1. **Starting a session** — Run `check-drift.sh` to see if updates available
2. **Before editing ontology** — Ensure local cache is current
3. **After pushing changes** — Pull to close the loop
4. **Investigating data issues** — Fresh sync ensures accuracy

## Manifest

The `.sync-manifest.json` tracks sync state:

```json
{
  "source_repo": "we-money/brightmatch-data-catalogue",
  "source_commit": "abc123...",
  "synced_at": "2026-02-02T10:30:00Z",
  "content": {
    "models": ["member", "loan_application", ...],
    "derivation_categories": ["serviceability", "filters", ...]
  }
}
```

## Why This Structure?

1. **Raw layer is deterministic** — Scripts sync it, no manual intervention
2. **Enriched layer is semantic** — Agents maintain it with business understanding
3. **Separation of concerns** — Source of truth stays clean, agent layer adds value
4. **Audit trail** — Both layers tracked in git with context

## Permission Model

| Operation | Permission | Tool |
|-----------|------------|------|
| Sync sources/derivations | SAFE | `sync-data-catalogue.sh` |
| Edit entities | SAFE | Agent (local only) |
| Push to source repo | BATCH_CONFIRM | `push-changes.sh` |
