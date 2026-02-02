#!/bin/bash
# Push local ontology changes to source repo via PR
# Permission: BATCH_CONFIRM
#
# Audit: Creates PR with full context

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="we-money/brightmatch-data-catalogue"
MANIFEST=".claude/skills/data-catalogue/.sync-manifest.json"

log() { echo "[push] $1"; }

# Pre-flight: Check manifest exists
if [ ! -f "$MANIFEST" ]; then
    log "ERROR: No manifest found. Run sync-data-catalogue.sh first."
    exit 1
fi

# Pre-flight: Check for drift
log "Checking drift..."
DRIFT_RESULT=$("$SCRIPT_DIR/check-drift.sh" 2>&1) || DRIFT_EXIT=$?
if [ "${DRIFT_EXIT:-0}" -eq 1 ]; then
    log "WARNING: Remote has changed since last sync."
    log "$DRIFT_RESULT"
    log "Consider running sync-data-catalogue.sh --full first to merge changes."
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Pre-flight: Validate local files
log "Validating local files..."
if ! "$SCRIPT_DIR/validate-local.sh"; then
    log "ERROR: Validation failed. Fix errors before pushing."
    exit 1
fi

# Detect changes
CHANGED=$(git diff --name-only .claude/skills/data-catalogue/ontology/ 2>/dev/null || true)
UNTRACKED=$(git ls-files --others --exclude-standard .claude/skills/data-catalogue/ontology/ 2>/dev/null || true)
ALL_CHANGES=$(echo -e "$CHANGED\n$UNTRACKED" | grep -v '^$' | sort -u || true)

if [ -z "$ALL_CHANGES" ]; then
    log "No changes to push."
    exit 0
fi

log "Changes detected:"
echo "$ALL_CHANGES"
echo ""

# Confirm before proceeding (BATCH_CONFIRM)
log "This will create a PR to $REPO"
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Aborted."
    exit 0
fi

# Create PR
BRANCH="sync/orchestrator-$(date +%Y%m%d-%H%M%S)"
TEMP=$(mktemp -d)
trap "rm -rf $TEMP" EXIT

log "Cloning source repo..."
gh repo clone "$REPO" "$TEMP" -- --depth 1 -q

cd "$TEMP"
git checkout -b "$BRANCH"

# Copy changes back to source structure
log "Copying changes..."
OLDPWD_SAVED="$OLDPWD"

# Map local ontology/sources -> source models
if [ -d "$OLDPWD_SAVED/.claude/skills/data-catalogue/ontology/sources" ]; then
    cp -r "$OLDPWD_SAVED/.claude/skills/data-catalogue/ontology/sources/"* public/data-catalogue/models/ 2>/dev/null || true
fi

# Map local ontology/derivations -> source derivations
if [ -d "$OLDPWD_SAVED/.claude/skills/data-catalogue/ontology/derivations" ]; then
    cp -r "$OLDPWD_SAVED/.claude/skills/data-catalogue/ontology/derivations/"* public/data-catalogue/derivations/ 2>/dev/null || true
fi

# Check if there are actual changes in the target repo
if git diff --quiet && git diff --cached --quiet; then
    log "No changes detected in target repo structure."
    exit 0
fi

git add .
git commit -m "$(cat <<'EOF'
sync: update from orchestrator

Changes from local ontology edits in wemoney-orchestrator.
Source: wemoney-orchestrator

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

git push origin "$BRANCH"

gh pr create \
    --title "sync: ontology update from orchestrator" \
    --body "$(cat <<EOF
## Source
Automated sync from \`wemoney-orchestrator\` local ontology cache.

## Changes
\`\`\`
$ALL_CHANGES
\`\`\`

## Validation
- [x] JSON syntax validated
- [x] Drift status checked before push

---
*Created by \`push-changes.sh\`*
EOF
)"

log "PR created on branch: $BRANCH"
