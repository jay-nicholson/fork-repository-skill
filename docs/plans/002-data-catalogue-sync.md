# 002: Closed-Loop Data Catalogue Sync

**Parent:** `001-orchestrator-system.md` (Phase 1 complete)
**Status:** Implemented
**Scope:** Phase 2A - Data catalogue sync infrastructure

---

## End Vision

The orchestrator coordinates agents that maintain 50+ services. For agents to reason about data, they need:

1. **Local ontology cache** — Models, derivations, relationships (synced)
2. **Validation pipeline** — Deterministic checks before any change
3. **Audit trail** — Every sync, every change, traceable to source
4. **Closed loop** — Pull → Edit → Validate → Push → Pull

**Deterministic scripts are the foundation. Agents orchestrate them.**

```
┌─────────────────────────────────────────────────────────────────┐
│                     ORCHESTRATOR VISION                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   AGENT LAYER (orchestrates)                                    │
│   ├─ Reads local ontology cache for context                     │
│   ├─ Decides what needs updating (semantic understanding)       │
│   ├─ Calls deterministic scripts                                │
│   └─ Commits with audit trail (WHY, not just WHAT)              │
│                                                                 │
│   SCRIPT LAYER (deterministic)                                  │
│   ├─ sync-data-catalogue.sh   → Pull from source                │
│   ├─ check-drift.sh           → Detect divergence               │
│   ├─ validate-local.sh        → Schema + API validation         │
│   └─ push-changes.sh          → PR back to source               │
│                                                                 │
│   SOURCE LAYER (truth)                                          │
│   └─ we-money/brightmatch-data-catalogue                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phases

### Phase 2A: Sync Infrastructure (THIS PLAN) ✓
- Deterministic scripts for pull/push
- Manifest-based drift detection
- Local ontology cache populated

### Phase 2B: Validation Pipeline (Future)
- Schema extraction from TypeScript types
- Offline validation without API
- Pre-commit hooks

### Phase 2C: Agent Integration (Future)
- `/sync-catalogue` command for agents
- Semantic diff reporting (not just file diff)
- Auto-enrichment of commit messages

---

## Implementation Summary

### Scripts Created

| Script | Purpose | Permission |
|--------|---------|------------|
| `scripts/sync/sync-data-catalogue.sh` | Pull models + derivations | SAFE |
| `scripts/sync/check-drift.sh` | Compare manifest vs remote | SAFE |
| `scripts/sync/validate-local.sh` | JSON + API validation | SAFE |
| `scripts/sync/push-changes.sh` | Create PR from local edits | BATCH_CONFIRM |

### Files Created/Updated

| File | Status |
|------|--------|
| `scripts/sync/sync-data-catalogue.sh` | Created |
| `scripts/sync/check-drift.sh` | Created |
| `scripts/sync/validate-local.sh` | Created |
| `scripts/sync/push-changes.sh` | Created |
| `scripts/sync/sync-ontology.sh` | Updated (delegates to new script) |
| `scripts/sync/sync-all.sh` | Updated (adds drift check) |
| `.claude/skills/data-catalogue/ontology/README.md` | Updated (closed loop docs) |
| `.claude/skills/data-catalogue/SKILL.md` | Updated (sync workflow) |
| `docs/plans/002-data-catalogue-sync.md` | Created (this file) |

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
    "derivation_categories": ["serviceability", "filters", "lookups", "..."]
  }
}
```

---

## Directory Structure

```
.claude/skills/data-catalogue/
├── .sync-manifest.json              # Sync state
├── SKILL.md                         # Updated with sync workflow
├── ontology/
│   ├── README.md                    # Closed loop documentation
│   ├── objects/                     # Synced models
│   │   ├── member/_root.json
│   │   ├── loan_application/_root.json
│   │   └── ...
│   ├── derivations/                 # Synced derivations
│   │   ├── serviceability/
│   │   ├── filters/
│   │   └── ...
│   ├── links/                       # (empty - future)
│   └── actions/                     # (empty - future kinetic layer)
└── docs/
    ├── INDEX.md                     # Synced
    └── CATALOGUE_CLAUDE.md          # Synced

scripts/sync/
├── sync-data-catalogue.sh           # Main sync script
├── check-drift.sh                   # Drift detection
├── validate-local.sh                # Local validation
├── push-changes.sh                  # PR creation
├── sync-ontology.sh                 # Updated wrapper
├── sync-service.sh                  # (unchanged)
└── sync-all.sh                      # Updated with drift check
```

---

## Verification

| Test | Command | Expected |
|------|---------|----------|
| Full sync | `./scripts/sync/sync-data-catalogue.sh --full` | Files in ontology/objects/ |
| Drift check (clean) | `./scripts/sync/check-drift.sh` | "IN_SYNC: {sha}" |
| Idempotence | Run sync twice | No errors, same result |
| Validation | `./scripts/sync/validate-local.sh` | Exit 0 |
| Drift detection | Edit remote, run check-drift | "DRIFTED: ..." |

---

## Next Steps (Phase 2B/2C)

After this phase:

1. **Extract TypeScript schemas** for offline validation
2. **Add `/sync-catalogue` command** for agents
3. **Semantic diff reporting** — agent explains WHAT changed, not just files
4. **Pre-commit hooks** — validate before any ontology commit

---

## References

- Parent plan: `docs/plans/001-orchestrator-system.md`
- Data catalogue source: `we-money/brightmatch-data-catalogue`
- Ralph Loop pattern: EXPLORE → UPDATE → VALIDATE
