#!/bin/bash
# Sync all key WeMoney services and documentation
# This is a full orchestration sync

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "WeMoney Orchestrator - Full Sync"
echo "=========================================="
echo ""

# 0. Check drift status first
echo "Step 0: Checking drift status..."
DRIFT_RESULT=$("$SCRIPT_DIR/check-drift.sh" 2>&1) || DRIFT_EXIT=$?
case ${DRIFT_EXIT:-0} in
    0) echo "  Data catalogue: IN SYNC" ;;
    1) echo "  Data catalogue: DRIFTED - will sync" ;;
    2) echo "  Data catalogue: NO MANIFEST - will do initial sync" ;;
    *) echo "  Data catalogue: ERROR checking drift" ;;
esac
echo ""

# 1. Sync ontology/data catalogue (full content now)
echo "Step 1: Syncing data catalogue (docs + models + derivations)..."
bash "$SCRIPT_DIR/sync-ontology.sh"
echo ""

# 2. Sync priority services
PRIORITY_SERVICES=(
  "brightmatch"
  "brightmatch-data-catalogue"
  "glean"
)

echo "Step 2: Syncing priority services..."
for service in "${PRIORITY_SERVICES[@]}"; do
  echo ""
  echo "--- $service ---"
  bash "$SCRIPT_DIR/sync-service.sh" "$service"
done
echo ""

# 3. Optional: Sync supporting services (uncomment as needed)
# SUPPORTING_SERVICES=(
#   "wemoney-backend"
#   "categorizer"
#   "creditor"
#   "open-banker"
# )
#
# echo "Step 3: Syncing supporting services..."
# for service in "${SUPPORTING_SERVICES[@]}"; do
#   echo ""
#   echo "--- $service ---"
#   bash "$SCRIPT_DIR/sync-service.sh" "$service"
# done

echo "=========================================="
echo "Sync Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "  Worktrees:"
ls -la worktrees/ 2>/dev/null | grep -v "^total" | tail -n +2 || echo "    (none yet)"
echo ""
echo "  Data catalogue:"
echo "    Docs: $(ls .claude/skills/data-catalogue/docs/*.md 2>/dev/null | wc -l | tr -d ' ') files"
echo "    Models: $(ls -d .claude/skills/data-catalogue/ontology/objects/*/ 2>/dev/null | wc -l | tr -d ' ') models"
echo "    Derivations: $(ls -d .claude/skills/data-catalogue/ontology/derivations/*/ 2>/dev/null | wc -l | tr -d ' ') categories"
echo ""
if [ -f ".claude/skills/data-catalogue/.sync-manifest.json" ]; then
    echo "  Manifest:"
    jq -r '"    Source commit: " + .source_commit[:8] + "\n    Synced at: " + .synced_at' .claude/skills/data-catalogue/.sync-manifest.json
fi
