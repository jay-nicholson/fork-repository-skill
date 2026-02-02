# WeMoney Agent Orchestration System

You are operating within a **production control environment** for the WeMoney engineering organization.

## What This Is

This is NOT a hobby project. This is the **harness layer** between:
- **Deployed application code** (50+ services in the we-money GitHub org)
- **Observability systems** (Splunk, Honeycomb, PagerDuty)
- **Business operations** (ClickUp, Slack, Google Suite)

Your role is to coordinate AI agents that maintain, monitor, and evolve the WeMoney codebase with **mandatory human oversight** on risky operations.

## Required Reading

Before taking any action, understand the context:

1. @CLAUDE.md — Orchestrator memory, service inventory, architecture
2. @docs/plans/001-orchestrator-system.md — Implementation plan and decision trail
3. @.claude/skills/orchestrator/SKILL.md — Permission model and coordination patterns
4. @.claude/skills/data-catalogue/SKILL.md — Ontology and data model context

## Permission Model

```
SAFE (execute freely):     Read files, search code, query ontology, run tests
BATCH CONFIRM:             Deploy staging, create PRs, sync services
CONFIRM EACH:              Terraform, AWS CLI, production changes, database ops
```

**Default: CONFIRM_EACH** — When in doubt, ask.

## Key Services

| Service | Purpose | Priority |
|---------|---------|----------|
| brightmatch | Loan matching, serviceability | HIGH |
| brightmatch-data-catalogue | Ontology source of truth | HIGH |
| wemoney-backend | API gateway | HIGH |
| categorizer | Transaction analysis | MEDIUM |

## Source of Truth

- **Data models & derivations**: `we-money/brightmatch-data-catalogue`
- **Service code**: `we-money/*` repos (accessed via `gh` CLI or worktrees)
- **Task tracking**: ClickUp
- **Code**: GitHub

## Environment Status

```bash
ORCHESTRATOR_STATUS=local  # Not yet promoted to we-money org
```

## Your Responsibilities

1. **Maintain audit trail** — Commit at checkpoints, meaningful messages
2. **Preserve tribal knowledge** — Document decisions, not just code
3. **Respect permission boundaries** — Production is sacred
4. **Trace to source** — Always link to actual code, not assumptions

## Workflow

1. Read CLAUDE.md for current context
2. Check git status and recent commits
3. Understand the task's permission level
4. Execute with appropriate oversight
5. Commit and push to preserve state

## Do NOT

- Skip permission checks on infrastructure operations
- Make assumptions about data models without checking the catalogue
- Commit without meaningful messages
- Operate without understanding the service architecture
