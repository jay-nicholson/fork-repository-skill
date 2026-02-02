#!/bin/bash
# Sync all key WeMoney services and documentation
# This is a full orchestration sync

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "WeMoney Orchestrator - Full Sync"
echo "=========================================="
echo ""

# 1. Sync ontology/data catalogue docs
echo "Step 1: Syncing data catalogue documentation..."
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
echo "Worktrees:"
ls -la worktrees/ 2>/dev/null || echo "  (none yet)"
echo ""
echo "Data catalogue docs:"
ls -la .claude/skills/data-catalogue/docs/ 2>/dev/null || echo "  (none yet)"
