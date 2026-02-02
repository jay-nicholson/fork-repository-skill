---
name: Orchestrator
description: Central coordination skill for the WeMoney agent system. Use this for multi-service operations, permission checks, and cross-service queries. Triggers on 'orchestrate', 'coordinate', 'which services', 'permission check'.
---

# Purpose

Central coordination point for the WeMoney agent orchestration system. Manages permissions, coordinates multi-service operations, and maintains pulse on the codebase.

## Environment

```bash
ORCHESTRATOR_STATUS=local  # Options: local | promoted
# TODO: Remove this once promoted to we-money/wemoney-orchestrator
```

## Permission Model

### Default Behavior

**All operations require human confirmation unless explicitly marked safe.**

### Permission Levels

```yaml
permissions:
  default: CONFIRM_EACH  # Human approves each command

  safe_operations:       # Agent can execute freely
    - read files
    - search code
    - run tests (read-only)
    - query ontology
    - generate documentation
    - git status/log/diff

  batch_confirm:         # Human confirms batch
    - deploy to staging
    - update dependencies
    - create pull requests
    - run test suites
    - sync services

  confirm_each:          # Human confirms EACH command
    - terraform apply/destroy
    - aws cli mutations
    - production deployments
    - database migrations
    - delete operations
```

## Service Inventory

### Core Applications

| Service | Repo | Priority | Language |
|---------|------|----------|----------|
| brightmatch | we-money/brightmatch | HIGH | Go |
| wemoney-backend | we-money/wemoney-backend | HIGH | Go |
| wemoney-mobile-app | we-money/wemoney-mobile-app | MEDIUM | TypeScript |
| brightmatch-admin-portal | we-money/brightmatch-admin-portal | MEDIUM | TypeScript |

### Data & Intelligence

| Service | Repo | Has Agent Context |
|---------|------|-------------------|
| glean | we-money/glean | Yes (AGENTS.md) |
| brightmatch-data-catalogue | we-money/brightmatch-data-catalogue | Yes (.claude/) |
| categorizer | we-money/categorizer | No |
| txformer | we-money/txformer | No |

### Supporting Services

| Service | Repo | Purpose |
|---------|------|---------|
| open-banker | we-money/open-banker | CDR/Open Banking |
| creditor | we-money/creditor | Credit bureau integration |
| usermanager | we-money/usermanager | User management |
| offerer | we-money/offerer | Offer generation |
| notifier | we-money/notifier | Push/email notifications |

### Infrastructure (DANGEROUS)

| Service | Repo | Risk |
|---------|------|------|
| shared-infrastructure | we-money/shared-infrastructure | CONFIRM_EACH |
| aws-org | we-money/aws-org | CONFIRM_EACH |
| automation-iam | we-money/automation-iam | CONFIRM_EACH |

## Coordination Patterns

### Cross-Service Query

When user asks "Which services handle X?":

1. Search across worktrees or via GitHub API
2. Report matching files with context
3. Trace data flow between services

```bash
# Example: Find services handling member data
for repo in brightmatch wemoney-backend creditor usermanager; do
  gh api repos/we-money/$repo/contents --jq '.[].name' 2>/dev/null | head -5
done
```

### Diff Check

Before any operation, compare against main:

```bash
git diff main..HEAD --stat
git log main..HEAD --oneline
```

### Health Check

Verify service health across the stack:

1. Check GitHub Actions status
2. Query observability tools (Honeycomb, Splunk)
3. Check deployment status (Vercel, EKS)

### Incident Response

When investigating issues:

1. Trace error across service boundaries
2. Check recent deployments in affected services
3. Query observability for correlated signals
4. Propose remediation with CONFIRM_EACH for production changes

## Workflow

### Starting Work

1. Read CLAUDE.md for context
2. Check git status and branch
3. Review task list
4. Confirm permission level for planned operations

### During Work

1. Commit at checkpoints
2. Push regularly to preserve audit trail
3. Document decisions in commit messages

### Completing Work

1. Run tests for affected services
2. Create PR if changes ready
3. Update task status
4. Push final state

## Tool Connectors

### Safe (Agent can use freely)

| Tool | Purpose |
|------|---------|
| Slack | Communication, tribal knowledge |
| ClickUp | Task tracking |
| Google Suite | Docs, Sheets, Mail |
| AirTable | Data management |
| Splunk | Observability (read-only) |
| Honeycomb | Observability (read-only) |

### Medium Risk (Batch confirm)

| Tool | Purpose |
|------|---------|
| Vercel | Deployments |
| n8n | Workflow automation |
| PagerDuty | Incident response |

### Dangerous (Confirm each)

| Tool | Purpose |
|------|---------|
| AWS CLI | Infrastructure mutations |
| Terraform | Infrastructure as Code |
| Google Cloud | GCP operations |

## Harness Role

This orchestrator is the **harness layer** between:
- **Deployed code** (deterministic application layer)
- **Observability** (Splunk, Honeycomb, PagerDuty)

Responsibilities:
- Compare diffs against main branch
- Respond to GitHub checks
- Monitor deployment status
- Bridge code changes → observability signals
