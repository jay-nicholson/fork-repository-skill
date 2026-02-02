# Ontology - Local Cache

This directory contains a **synced local cache** of the WeMoney data catalogue from `we-money/brightmatch-data-catalogue`.

## Source of Truth

**Repository:** `we-money/brightmatch-data-catalogue`

| Content | Source Location | Local Location |
|---------|-----------------|----------------|
| Models | `public/data-catalogue/models/` | `ontology/objects/` |
| Derivations | `public/data-catalogue/derivations/` | `ontology/derivations/` |
| Links | (future) | `ontology/links/` |
| Actions | (future kinetic layer) | `ontology/actions/` |

## Closed-Loop Workflow

```
┌──────────────────────────────────────────────────────────┐
│                    CLOSED LOOP                           │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  1. PULL (sync-data-catalogue.sh)                        │
│     Remote → Local cache                                 │
│     Updates .sync-manifest.json                          │
│                                                          │
│  2. EDIT (agent or manual)                               │
│     Modify local JSON files                              │
│     Agent adds semantic context                          │
│                                                          │
│  3. VALIDATE (validate-local.sh)                         │
│     JSON syntax check                                    │
│     API validation if available                          │
│                                                          │
│  4. PUSH (push-changes.sh)                               │
│     Creates PR to source repo                            │
│     Requires BATCH_CONFIRM                               │
│                                                          │
│  5. PULL (after merge)                                   │
│     Loop closes                                          │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Sync Commands

```bash
# Full sync (force re-download all)
./scripts/sync/sync-data-catalogue.sh --full

# Incremental sync (skip if in sync)
./scripts/sync/sync-data-catalogue.sh --incremental

# Check drift without syncing
./scripts/sync/check-drift.sh

# Validate local files
./scripts/sync/validate-local.sh

# Push local changes as PR (BATCH_CONFIRM)
./scripts/sync/push-changes.sh
```

## Manifest

The `.sync-manifest.json` file tracks sync state:

```json
{
  "source_repo": "we-money/brightmatch-data-catalogue",
  "source_commit": "abc123...",
  "synced_at": "2026-02-02T10:30:00Z",
  "synced_by": "sync-data-catalogue.sh",
  "content": {
    "models": ["member", "loan_application", ...],
    "derivation_categories": ["serviceability", "filters", ...]
  }
}
```

## Directory Structure

```
ontology/
├── README.md                    # This file
├── objects/                     # Synced models (from models/)
│   ├── member/
│   │   └── _root.json
│   ├── loan_application/
│   │   └── _root.json
│   └── ...
├── derivations/                 # Synced derivations
│   ├── serviceability/
│   ├── filters/
│   └── ...
├── links/                       # (future: relationship definitions)
└── actions/                     # (future: kinetic layer operations)
```

## Why Local Cache?

1. **Agent Context** — Agents can read local files without API calls
2. **Offline Work** — Edit without network dependency
3. **Audit Trail** — Git tracks all changes
4. **Validation** — Check before pushing to source
5. **Semantic Understanding** — Agents can reason about the full ontology

## Permission Model

| Operation | Permission | Script |
|-----------|------------|--------|
| Sync from remote | SAFE | `sync-data-catalogue.sh` |
| Check drift | SAFE | `check-drift.sh` |
| Validate local | SAFE | `validate-local.sh` |
| Push to remote | BATCH_CONFIRM | `push-changes.sh` |
