#!/bin/bash
# Deterministic sync for data catalogue models and derivations
# Usage: ./sync-data-catalogue.sh [--full | --incremental | --check-drift]
#
# Permission: SAFE (read-only from remote)
# Audit: Updates .sync-manifest.json with source commit

set -e

REPO="we-money/brightmatch-data-catalogue"
LOCAL_PATH=".claude/skills/data-catalogue"
MANIFEST="$LOCAL_PATH/.sync-manifest.json"
MODE=${1:---incremental}

log() { echo "[sync] $1"; }

# --- Drift Check ---
check_drift() {
    local LOCAL_SHA=$(jq -r '.source_commit // "none"' "$MANIFEST" 2>/dev/null || echo "none")
    local REMOTE_SHA=$(gh api repos/$REPO/commits --jq '.[0].sha')

    if [ "$LOCAL_SHA" == "$REMOTE_SHA" ]; then
        echo "IN_SYNC"
        return 0
    else
        echo "DRIFTED:local=$LOCAL_SHA,remote=$REMOTE_SHA"
        return 1
    fi
}

if [ "$MODE" == "--check-drift" ]; then
    check_drift
    exit $?
fi

# Skip if already in sync (unless --full)
if [ "$MODE" != "--full" ]; then
    if check_drift > /dev/null 2>&1; then
        log "Already in sync. Use --full to force."
        exit 0
    fi
fi

# --- Sync Models ---
log "Syncing models..."
mkdir -p "$LOCAL_PATH/ontology/sources"

MODELS=$(gh api repos/$REPO/contents/public/data-catalogue/models --jq '.[].name' 2>/dev/null || echo "")
if [ -z "$MODELS" ]; then
    log "Warning: Could not fetch models list"
else
    for model in $MODELS; do
        log "  $model"
        mkdir -p "$LOCAL_PATH/ontology/sources/$model"

        # Fetch _root.json
        gh api "repos/$REPO/contents/public/data-catalogue/models/$model/_root.json" \
            --jq '.content' 2>/dev/null | base64 -d > "$LOCAL_PATH/ontology/sources/$model/_root.json" 2>/dev/null || true

        # Fetch nested files (if any)
        NESTED=$(gh api "repos/$REPO/contents/public/data-catalogue/models/$model" \
            --jq '.[] | select(.name != "_root.json") | .name' 2>/dev/null || true)
        for file in $NESTED; do
            if [ -n "$file" ]; then
                gh api "repos/$REPO/contents/public/data-catalogue/models/$model/$file" \
                    --jq '.content' 2>/dev/null | base64 -d > "$LOCAL_PATH/ontology/sources/$model/$file" 2>/dev/null || true
            fi
        done
    done
fi

# --- Sync Derivations ---
log "Syncing derivations..."
mkdir -p "$LOCAL_PATH/ontology/derivations"

CATEGORIES=$(gh api repos/$REPO/contents/public/data-catalogue/derivations --jq '.[].name' 2>/dev/null || echo "")
if [ -z "$CATEGORIES" ]; then
    log "Warning: Could not fetch derivations list"
else
    for category in $CATEGORIES; do
        log "  $category/"
        mkdir -p "$LOCAL_PATH/ontology/derivations/$category"

        FILES=$(gh api "repos/$REPO/contents/public/data-catalogue/derivations/$category" --jq '.[].name' 2>/dev/null || true)
        for file in $FILES; do
            if [ -n "$file" ]; then
                gh api "repos/$REPO/contents/public/data-catalogue/derivations/$category/$file" \
                    --jq '.content' 2>/dev/null | base64 -d > "$LOCAL_PATH/ontology/derivations/$category/$file" 2>/dev/null || true
            fi
        done
    done
fi

# --- Update Manifest ---
REMOTE_SHA=$(gh api repos/$REPO/commits --jq '.[0].sha' 2>/dev/null || echo "unknown")
MODEL_COUNT=$(echo "$MODELS" | wc -w | tr -d ' ')
CATEGORY_COUNT=$(echo "$CATEGORIES" | wc -w | tr -d ' ')

# Build JSON arrays properly
MODELS_JSON="[]"
if [ -n "$MODELS" ]; then
    MODELS_JSON=$(echo "$MODELS" | jq -R -s 'split("\n") | map(select(length > 0))')
fi

CATEGORIES_JSON="[]"
if [ -n "$CATEGORIES" ]; then
    CATEGORIES_JSON=$(echo "$CATEGORIES" | jq -R -s 'split("\n") | map(select(length > 0))')
fi

cat > "$MANIFEST" << EOF
{
  "source_repo": "$REPO",
  "source_commit": "$REMOTE_SHA",
  "synced_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "synced_by": "sync-data-catalogue.sh",
  "content": {
    "models": $MODELS_JSON,
    "derivation_categories": $CATEGORIES_JSON
  }
}
EOF

log "Sync complete: $REMOTE_SHA"
log "Models: $MODEL_COUNT"
log "Derivation categories: $CATEGORY_COUNT"
