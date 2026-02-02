---
name: Install
description: Onboarding command for engineering newcomers. Checks environment setup, validates MCP connections, and guides through required configuration. Triggers on 'install', 'onboard', 'setup environment'.
---

# Purpose

Guide engineering newcomers through setting up their development environment for WeMoney. This skill fetches live content from ClickUp and validates the local environment.

## Trigger

Run `/install` when:
- Starting on a new machine
- Joining the team
- After a fresh clone of this repo
- MCP connections aren't working

---

# Source of Truth

**Engineering Onboarding documentation lives in ClickUp, not here.**

| Document | ID | Pages |
|----------|-----|-------|
| Engineering Onboarding | `2kz09mtg-12656` | Machine Setup, Git Commit Signing |

When this skill runs, fetch the current content:

```
clickup_get_document_pages(
  document_id: "2kz09mtg-12656",
  page_ids: ["2kz09mtg-17316", "2kz09mtg-8316", "2kz09mtg-17336"],
  content_format: "text/md"
)
```

Present the live content to the user. Do not maintain a copy here.

---

# Instructions

## Step 1: Check MCP Connection

Run `/mcp` to verify ClickUp is connected. If not authenticated, complete OAuth flow.

## Step 2: Fetch Live Onboarding Content

Use `clickup_get_document_pages` to fetch:
- **Machine Setup** (page `2kz09mtg-8316`) — Required tools, brew commands
- **Git Commit Signing** (page `2kz09mtg-17336`) — SSH/GPG signing setup

Present the content to the user.

## Step 3: Validate Environment

Run verification commands to check what's installed vs what's needed:

```bash
# Core tools
command -v brew && echo "✓ Homebrew" || echo "✗ Homebrew"
command -v node && echo "✓ Node $(node --version)" || echo "✗ Node"
command -v go && echo "✓ Go $(go version)" || echo "✗ Go"
command -v terraform && echo "✓ Terraform" || echo "✗ Terraform"
command -v aws && echo "✓ AWS CLI" || echo "✗ AWS CLI"
command -v gh && echo "✓ GitHub CLI" || echo "✗ GitHub CLI"
command -v jq && echo "✓ jq" || echo "✗ jq"

# Git signing
git config --get commit.gpgsign && echo "✓ Commit signing enabled" || echo "✗ Commit signing not configured"

# GitHub auth
gh auth status 2>/dev/null && echo "✓ GitHub authenticated" || echo "✗ GitHub not authenticated"
```

## Step 4: Guide Remediation

For any missing tools, provide the specific install command from the ClickUp doc.

## Step 5: Orchestrator-Specific Setup

After base machine setup, ensure MCP servers are configured:

| Server | URL | Check |
|--------|-----|-------|
| ClickUp | `https://mcp.clickup.com/mcp` | `/mcp` shows connected |
| Slack | `https://mcp.slack.com/mcp` | Pending partner access |

---

# Why Live Fetch?

From CLAUDE.md:
> "Trace to source — Always link to actual code, not assumptions"

The Engineering Onboarding doc in ClickUp is maintained by the team. This skill is a pointer to that source, not a copy. When the team updates onboarding steps, this skill automatically reflects those changes.

**ClickUp URL:** https://app.clickup.com/90161074992/docs/2kz09mtg-12656

---

# Tech Debt

- [ ] **Slack MCP**: Pending partner access
- [ ] Auto-create onboarding tracking task in ClickUp for new starters
- [ ] Add validation for AWS VPN, 1Password CLI
