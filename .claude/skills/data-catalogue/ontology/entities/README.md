# Entities (Enriched Layer)

This directory will contain **enriched entity definitions** that merge source schemas with their derivations into coherent business objects.

## Status: Not Yet Implemented

Phase 2D will populate this directory. For now, agents should work with:
- `sources/` — Raw DB table schemas
- `derivations/` — Computed transformations

## Future Structure

```
entities/
├── README.md           # This file
├── member.json         # Member entity (source + derivations)
├── loan_application.json
├── credit_profile.json
└── ...
```

## Entity Schema (Proposed)

```json
{
  "name": "member",
  "description": "A WeMoney member with all derived attributes",
  "source": {
    "table": "sources/member/_root.json",
    "service": "usermanager",
    "database": "usermanager"
  },
  "fields": {
    "id": {
      "type": "uuid",
      "source": "raw",
      "description": "Unique member identifier"
    },
    "fully_onboarded_at": {
      "type": "datetime",
      "source": "raw",
      "aliases": ["FOBM", "FOBM Date"],
      "description": "When member completed onboarding"
    },
    "primary_income": {
      "type": "money",
      "source": "derived",
      "derivation": "extraction/detected_primary_income.json",
      "fallback": "extraction/declared_primary_income.json",
      "description": "Member's primary income (detected or declared)"
    },
    "net_capacity": {
      "type": "money",
      "source": "derived",
      "derivation": "serviceability/net_capacity.json",
      "depends_on": ["total_income", "total_expenses"],
      "description": "Available borrowing capacity"
    }
  },
  "relationships": {
    "loan_applications": {
      "entity": "loan_application",
      "type": "one_to_many",
      "foreign_key": "user_id"
    }
  }
}
```

## Why Entities?

Without entities, an agent asking "What is a member's net capacity?" must:
1. Find `member/_root.json` in sources
2. Find `serviceability/net_capacity.json` in derivations
3. Trace `depends_on` to `total_income.json` and `total_expenses.json`
4. Trace those to `detected_*` and `declared_*` derivations
5. Understand the min/max conservative logic

With entities, the agent reads `entities/member.json` and sees all fields with their derivation chains pre-traced.

## Maintained By

- **Agent + Human** — Not automatically synced
- Entities are a semantic interpretation layer
- Updates require understanding of business logic
