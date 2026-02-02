#!/bin/bash
# Sync data catalogue from we-money/brightmatch-data-catalogue
# Now includes full model/derivation sync (not just file lists)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="we-money/brightmatch-data-catalogue"
LOCAL_PATH=".claude/skills/data-catalogue/docs"

echo "=========================================="
echo "Data Catalogue Sync"
echo "=========================================="

# 1. Sync documentation (existing behavior)
echo ""
echo "Step 1: Documentation..."
mkdir -p "$LOCAL_PATH"

echo "  Fetching docs/INDEX.md..."
gh api repos/$REPO/contents/docs/INDEX.md \
    --jq '.content' 2>/dev/null | base64 -d > "$LOCAL_PATH/INDEX.md" 2>/dev/null || echo "  Warning: INDEX.md not found"

echo "  Fetching .claude/CLAUDE.md..."
gh api repos/$REPO/contents/.claude/CLAUDE.md \
    --jq '.content' 2>/dev/null | base64 -d > "$LOCAL_PATH/CATALOGUE_CLAUDE.md" 2>/dev/null || echo "  Warning: CLAUDE.md not found"

# 2. Sync models and derivations (NEW - full content sync)
echo ""
echo "Step 2: Models and derivations..."
bash "$SCRIPT_DIR/sync-data-catalogue.sh" --incremental

echo ""
echo "=========================================="
echo "Sync complete."
echo ""
echo "Files synced to:"
echo "  - Documentation: $LOCAL_PATH/"
echo "  - Models: .claude/skills/data-catalogue/ontology/objects/"
echo "  - Derivations: .claude/skills/data-catalogue/ontology/derivations/"
