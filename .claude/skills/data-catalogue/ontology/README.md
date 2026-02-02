# Ontology Reference

This directory contains pointers to the canonical source of truth for WeMoney data models and derivations.

## Source of Truth

**Repository:** `we-money/brightmatch-data-catalogue`

| Content | Location |
|---------|----------|
| Models | `public/data-catalogue/models/` |
| Derivations | `public/data-catalogue/derivations/` |
| Documentation | `docs/` |
| Agent Guide | `.claude/CLAUDE.md` |

## Why Not Sync?

The data catalogue is a **live application** with:
- Validation API (`/api/validate`)
- Real-time schema checks
- CI/CD integration

Syncing static files here would create drift. Instead, query the source directly:

```bash
# List models
gh api repos/we-money/brightmatch-data-catalogue/contents/public/data-catalogue/models --jq '.[].name'

# Read a model
gh api repos/we-money/brightmatch-data-catalogue/contents/public/data-catalogue/models/member/_root.json --jq '.content' | base64 -d | jq

# List derivations
gh api repos/we-money/brightmatch-data-catalogue/contents/public/data-catalogue/derivations --jq '.[].name'
```

## Local Development

To work on the data catalogue directly:

```bash
# Clone to worktree
bash scripts/sync/sync-service.sh brightmatch-data-catalogue

# Start dev server (for validation API)
cd worktrees/brightmatch-data-catalogue
npm install && npm run dev
```
