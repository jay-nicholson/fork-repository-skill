#!/bin/bash
# Check if local ontology has drifted from source
# Exit: 0=in-sync, 1=drifted, 2=no-manifest
#
# Permission: SAFE

set -e

MANIFEST=".claude/skills/data-catalogue/.sync-manifest.json"
REPO="we-money/brightmatch-data-catalogue"

if [ ! -f "$MANIFEST" ]; then
    echo "NO_MANIFEST"
    exit 2
fi

LOCAL=$(jq -r '.source_commit' "$MANIFEST")
REMOTE=$(gh api repos/$REPO/commits --jq '.[0].sha' 2>/dev/null || echo "unknown")

if [ "$REMOTE" == "unknown" ]; then
    echo "ERROR: Could not fetch remote commit"
    exit 3
fi

if [ "$LOCAL" == "$REMOTE" ]; then
    echo "IN_SYNC: $LOCAL"
    exit 0
else
    echo "DRIFTED: local=$LOCAL remote=$REMOTE"
    exit 1
fi
