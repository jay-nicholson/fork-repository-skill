# 002: Closed-Loop Data Catalogue Sync

**Parent:** `001-orchestrator-system.md` (Phase 1 complete)
**Status:** Implemented (Phase 2A), Restructured
**Scope:** Phase 2A-D - Data catalogue sync and enrichment infrastructure

---

## End Vision

The orchestrator coordinates agents that maintain 50+ services. For agents to reason about data, they need:

1. **Local ontology cache** — Sources, derivations, relationships (synced)
2. **Enriched entities** — Source + derivations merged into coherent business objects
3. **Validation pipeline** — Deterministic checks before any change
4. **Audit trail** — Every sync, every change, traceable to source
5. **Closed loop** — Pull → Edit → Validate → Push → Pull

**Deterministic scripts sync the raw layer. Agents maintain the enriched layer.**

```
┌─────────────────────────────────────────────────────────────────┐
│                     ONTOLOGY ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ENTITIES (enriched)          ← Agents interact here           │
│   └─ member.json               ← Source + derivations combined  │
│   └─ loan_application.json     ← Full semantic meaning          │
│                                                                 │
│   ─────────────────────────────────────────────────────────     │
│                                                                 │
│   SOURCES (raw)                ← Synced from data catalogue     │
│   └─ member/_root.json         ← DB table schema                │
│   └─ loan_application/_root.json                                │
│                                                                 │
│   DERIVATIONS (raw)            ← Synced from data catalogue     │
│   └─ serviceability/           ← Computed transformations       │
│   └─ extraction/               ← Field extractions              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phases

### Phase 2A: Sync Infrastructure ✓
- Deterministic scripts for pull/push
- Manifest-based drift detection
- Local ontology cache populated

### Phase 2A.1: Directory Restructure ✓
- Renamed `objects/` → `sources/` (clearer semantics)
- Created `entities/` directory for enrichment layer
- Updated scripts and documentation

### Phase 2B: Validation Pipeline (Future)
- Schema extraction from TypeScript types
- Offline validation without API
- Pre-commit hooks

### Phase 2C: Agent Integration (In Progress)
- `/sync-catalogue` command for agents
- Semantic diff reporting (not just file diff)
- Auto-enrichment of commit messages
- **MCP Connectors**: ClickUp integration via `.mcp.json`
- **`/install` command**: Engineering onboarding automation

### Phase 2D: Entity Enrichment Layer (Future)
- Merge sources + derivations into entity definitions
- Agent-maintained with business understanding
- Single coherent object for agent reasoning

---

## Implementation Summary

### Scripts Created

| Script | Purpose | Permission |
|--------|---------|------------|
| `scripts/sync/sync-data-catalogue.sh` | Pull sources + derivations | SAFE |
| `scripts/sync/check-drift.sh` | Compare manifest vs remote | SAFE |
| `scripts/sync/validate-local.sh` | JSON + API validation | SAFE |
| `scripts/sync/push-changes.sh` | Create PR from local edits | BATCH_CONFIRM |

### Directory Structure

```
.claude/skills/data-catalogue/
├── .sync-manifest.json              # Sync state
├── SKILL.md                         # Skill documentation
├── ontology/
│   ├── README.md                    # Architecture documentation
│   ├── sources/                     # Raw DB table schemas (synced)
│   │   ├── member/_root.json
│   │   ├── loan_application/_root.json
│   │   └── ...
│   ├── derivations/                 # Raw transformations (synced)
│   │   ├── serviceability/
│   │   ├── extraction/
│   │   └── ...
│   ├── entities/                    # Enriched objects (agent-maintained)
│   │   └── (future: source + derivations merged)
│   ├── links/                       # (future: relationships)
│   └── actions/                     # (future: kinetic layer)
└── docs/
    ├── INDEX.md                     # Synced
    └── CATALOGUE_CLAUDE.md          # Synced

scripts/sync/
├── sync-data-catalogue.sh           # Main sync script
├── check-drift.sh                   # Drift detection
├── validate-local.sh                # Local validation
├── push-changes.sh                  # PR creation
├── sync-ontology.sh                 # Wrapper (docs + data)
├── sync-service.sh                  # (unchanged)
└── sync-all.sh                      # Full orchestration sync
```

---

## Two-Layer Architecture

### Raw Layer (synced automatically)

**Sources** (`ontology/sources/`):
- DB table schemas from various services
- Synced by `sync-data-catalogue.sh`
- 21 tables across brightmatch, usermanager, categorizer, etc.

**Derivations** (`ontology/derivations/`):
- Computed transformations and field extractions
- 7 categories: account, credit, extraction, lookup, profile, selection, serviceability
- Define how raw fields become business values

### Enriched Layer (agent-maintained)

**Entities** (`ontology/entities/`):
- Combine source schema + relevant derivations
- Single coherent object with full semantic meaning
- Agent can reason about "member" without tracing derivation chains

Example entity structure:
```json
{
  "name": "member",
  "description": "A WeMoney member with all derived attributes",
  "source": {
    "table": "sources/member/_root.json",
    "service": "usermanager"
  },
  "fields": {
    "id": { "type": "uuid", "source": "raw" },
    "primary_income": {
      "type": "money",
      "source": "derived",
      "derivation": "extraction/detected_primary_income.json"
    },
    "net_capacity": {
      "type": "money",
      "source": "derived",
      "derivation": "serviceability/net_capacity.json"
    }
  }
}
```

---

## Manifest Schema

`.claude/skills/data-catalogue/.sync-manifest.json`:

```json
{
  "source_repo": "we-money/brightmatch-data-catalogue",
  "source_commit": "08f8d425dcbbc2e9057b6aa6a60d1a0a5bdf1e1b",
  "synced_at": "2026-02-02T10:30:00Z",
  "synced_by": "sync-data-catalogue.sh",
  "content": {
    "models": ["member", "loan_application", "credit_score", "..."],
    "derivation_categories": ["serviceability", "extraction", "..."]
  }
}
```

---

## Verification

| Test | Command | Expected |
|------|---------|----------|
| Full sync | `./scripts/sync/sync-data-catalogue.sh --full` | Files in ontology/sources/ |
| Drift check (clean) | `./scripts/sync/check-drift.sh` | "IN_SYNC: {sha}" |
| Idempotence | Run sync twice | No errors, same result |
| Validation | `./scripts/sync/validate-local.sh` | Exit 0 |
| Drift detection | Edit remote, run check-drift | "DRIFTED: ..." |

---

## Next Steps

### Phase 2B: Validation Pipeline
1. Extract TypeScript schemas for offline validation
2. Pre-commit hooks for ontology changes

### Phase 2C: Agent Integration
1. Add `/sync-catalogue` command
2. Semantic diff reporting

### Phase 2D: Entity Enrichment
1. Define entity schema format
2. Create initial entities (member, loan_application)
3. Document derivation → entity mapping

---

## References

- Parent plan: `docs/plans/001-orchestrator-system.md`
- Data catalogue source: `we-money/brightmatch-data-catalogue`
- Ralph Loop pattern: EXPLORE → UPDATE → VALIDATE
