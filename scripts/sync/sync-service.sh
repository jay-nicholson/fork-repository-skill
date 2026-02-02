#!/bin/bash
# Clone or update a WeMoney service into the worktrees directory
# Usage: ./sync-service.sh <service-name>
# Example: ./sync-service.sh brightmatch

set -e

SERVICE=$1

if [ -z "$SERVICE" ]; then
  echo "Usage: ./sync-service.sh <service-name>"
  echo "Example: ./sync-service.sh brightmatch"
  exit 1
fi

WORKTREES_DIR="worktrees"
SERVICE_PATH="$WORKTREES_DIR/$SERVICE"

# Ensure worktrees directory exists
mkdir -p "$WORKTREES_DIR"

if [ -d "$SERVICE_PATH" ]; then
  echo "Updating existing worktree: $SERVICE_PATH"
  cd "$SERVICE_PATH"

  # Fetch latest
  git fetch origin

  # Get current branch
  BRANCH=$(git rev-parse --abbrev-ref HEAD)

  # Pull if on a tracking branch
  if git config branch.$BRANCH.remote > /dev/null 2>&1; then
    git pull --rebase
  else
    echo "  Branch $BRANCH is not tracking remote, skipping pull"
  fi

  cd - > /dev/null
  echo "Updated $SERVICE"
else
  echo "Cloning new service: we-money/$SERVICE"

  # Clone the repo
  gh repo clone "we-money/$SERVICE" "$SERVICE_PATH"

  echo "Cloned $SERVICE to $SERVICE_PATH"
fi

# Show status
echo ""
echo "Service: $SERVICE"
echo "Path: $SERVICE_PATH"
cd "$SERVICE_PATH" && git log --oneline -3 && cd - > /dev/null
