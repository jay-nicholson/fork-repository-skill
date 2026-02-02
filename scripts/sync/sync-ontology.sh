#!/bin/bash
# Sync data catalogue documentation from we-money/brightmatch-data-catalogue
# This fetches key documentation files for reference, not the full repo

set -e

REPO="we-money/brightmatch-data-catalogue"
LOCAL_PATH=".claude/skills/data-catalogue/docs"

echo "Syncing data catalogue documentation from $REPO..."

# Create docs directory if it doesn't exist
mkdir -p "$LOCAL_PATH"

# Sync INDEX.md
echo "  Fetching docs/INDEX.md..."
gh api repos/$REPO/contents/docs/INDEX.md --jq '.content' 2>/dev/null | base64 -d > "$LOCAL_PATH/INDEX.md" 2>/dev/null || echo "  Warning: Could not fetch INDEX.md"

# Sync CLAUDE.md
echo "  Fetching .claude/CLAUDE.md..."
gh api repos/$REPO/contents/.claude/CLAUDE.md --jq '.content' 2>/dev/null | base64 -d > "$LOCAL_PATH/CATALOGUE_CLAUDE.md" 2>/dev/null || echo "  Warning: Could not fetch CLAUDE.md"

# List available models (for reference)
echo "  Listing available models..."
gh api repos/$REPO/contents/public/data-catalogue/models --jq '.[].name' 2>/dev/null > "$LOCAL_PATH/MODELS_LIST.txt" || echo "  Warning: Could not list models"

# List available derivations (for reference)
echo "  Listing available derivations..."
gh api repos/$REPO/contents/public/data-catalogue/derivations --jq '.[].name' 2>/dev/null > "$LOCAL_PATH/DERIVATIONS_LIST.txt" || echo "  Warning: Could not list derivations"

echo "Sync complete. Files in $LOCAL_PATH:"
ls -la "$LOCAL_PATH"
