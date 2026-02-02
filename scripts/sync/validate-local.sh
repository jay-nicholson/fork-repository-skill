#!/bin/bash
# Validate local ontology files
# Exit: 0=valid, 1+=error count
#
# Permission: SAFE

set -e

LOCAL_PATH=".claude/skills/data-catalogue/ontology"
MODE=${1:---auto}

log() { echo "[validate] $1"; }

# Check if ontology directory exists
if [ ! -d "$LOCAL_PATH" ]; then
    log "ERROR: Ontology directory not found: $LOCAL_PATH"
    log "Run sync-data-catalogue.sh first."
    exit 1
fi

# Try API first (if available)
if [ "$MODE" != "--schema-only" ]; then
    if curl -sf http://localhost:3000/api/validate > /dev/null 2>&1; then
        log "Using validation API..."
        RESULT=$(curl -s "http://localhost:3000/api/validate")
        ERRORS=$(echo "$RESULT" | jq '.errors | length // 0')
        WARNINGS=$(echo "$RESULT" | jq '.warnings | length // 0')
        log "Errors: $ERRORS, Warnings: $WARNINGS"
        exit $ERRORS
    fi
    log "API unavailable, falling back to JSON validation..."
fi

# Fallback: JSON syntax validation
log "Validating JSON syntax..."
ERRORS=0
TOTAL=0

while IFS= read -r -d '' file; do
    TOTAL=$((TOTAL + 1))
    if ! jq . "$file" > /dev/null 2>&1; then
        log "INVALID: $file"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$LOCAL_PATH" -name "*.json" -print0 2>/dev/null)

if [ $TOTAL -eq 0 ]; then
    log "No JSON files found in $LOCAL_PATH"
    log "Run sync-data-catalogue.sh first."
    exit 1
fi

if [ $ERRORS -eq 0 ]; then
    log "All $TOTAL JSON files valid."
else
    log "Found $ERRORS invalid files out of $TOTAL."
fi

exit $ERRORS
