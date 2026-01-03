# Claude Code Instructions for Highball

## Project Overview

Highball is a macOS menu bar app for monitoring Railway deployments. Built with Swift/SwiftUI.

- **Repo**: https://github.com/padaron/highball
- **Product Manager**: Ron Clarkson
- **Technical Lead**: Claude (Opus 4.5)

---

## GitHub Workflow Specification

| | |
|---|---|
| **Version** | 2.6 |
| **Status** | Active |
| **Last Updated** | 2025-01-03 |
| **Owner** | Ron |

### Changelog

| Version | Date | Changes |
|---------|------|---------|
| 2.6 | 2025-01-03 | Updated screenshot paths, enhanced checkpoint with issue coverage |
| 2.5 | 2025-01-03 | Enhanced checkpoint to verify all work has corresponding GitHub issues |
| 2.4 | 2025-01-03 | Added issue completeness requirements - mandatory fields for each issue type |
| 2.3 | 2025-01-03 | Added `/usage` reporting to checkpoint command |
| 2.2 | 2025-01-03 | Added `checkpoint` command (Section 14) - single-word GitHub sync verification |
| 2.1 | 2025-01-03 | Added CLAUDE.md integration (Section 13) - discuss modifications, save agreed process |
| 2.0 | 2025-01-03 | Added multi-session coordination (Section 10), screenshot handling workflow (Section 2), `in-progress` label for parallel work |
| 1.0 | 2025-01-03 | Initial spec: issues-first workflow, branch naming, conventional commits, PR requirements, documentation location guidelines |

### Core Principle

GitHub is the single source of truth for all features, bugs, specs, and roadmap. All code changes flow through GitHub Issues and PRs. No direct commits to main. **Every change starts with an issue.**

#### The Golden Rule

**No code without an issue.** Before writing any code, there must be a GitHub issue that:
- Documents what problem is being solved or what feature is being added
- Will be referenced in commits and PRs
- Can be understood by another session without additional context

If you're about to write code and there's no issue, **stop and create one first.**

---

### 1. Issues First

Before writing any code, create a GitHub Issue. **Every issue must be self-contained** - another Claude Code session should understand the full context without asking questions.

#### Issue Completeness Rule

**Never create a partial issue.** If you don't have enough information, ask the user before creating the issue.

#### Bug Reports - Required Fields

- **Title**: Action-oriented (e.g., "Fix crash on empty form submission")
- **Steps to Reproduce**: Numbered, specific steps anyone can follow
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens (include error messages verbatim)
- **Environment**: macOS version, app version

#### Feature Requests - Required Fields

- **Title**: User-focused outcome (e.g., "Add dark mode support")
- **User Story**: Who wants this and why
- **Acceptance Criteria**: Specific, testable conditions for "done"
- **Scope**: What's included and explicitly what's NOT included

#### Refactors - Required Fields

- **Title**: What's being refactored (e.g., "Refactor API client to use async/await")
- **Current State**: What exists now and why it's problematic
- **Proposed Change**: What will change
- **Files Affected**: List of files/modules
- **Risk Assessment**: What could break, how to verify

#### Chores - Required Fields

- **Title**: Specific task (e.g., "Update Swift to 5.9")
- **What**: Specific change being made
- **Why**: Reason for the change
- **Verification**: How to confirm it worked

**Issue titles**: Concise and actionable (e.g., "Fix crash on empty input" not "Bug found")

---

### 2. Screenshot Handling

When screenshots are needed for bug reports or feature documentation, commit them to the repository for fully automated workflow:

```bash
# Create screenshots directory if needed
mkdir -p .github/screenshots

# Save screenshot with timestamp or issue reference
# (screenshot provided by user is saved here)
mv screenshot.png .github/screenshots/issue-$(date +%Y%m%d-%H%M%S).png

# Commit and push
git add .github/screenshots/
git commit -m "docs: add screenshot for bug report"
git push
```

**Reference in issues using relative paths:**

```bash
gh issue create \
  --title "Bug: UI element misaligned" \
  --label "bug" \
  --body "## Screenshot
![bug screenshot](.github/screenshots/issue-20250103-142301.png)

## Description
Button overlaps text on mobile viewport"
```

**Naming convention**: `issue-YYYYMMDD-HHMMSS.png` or `issue-<number>-description.png` after issue is created.

**Maintenance**: For long-running projects, periodically archive old screenshots or add Git LFS if repo size becomes a concern.

---

### 3. Branch Per Issue

Create a branch from `main` for every issue:

**Format**: `<type>/<issue-number>-<short-description>`

| Type | Example |
|------|---------|
| Bug fix | `fix/42-null-pointer-crash` |
| Feature | `feat/15-add-dark-mode` |
| Refactor | `refactor/28-extract-api-client` |
| Chore | `chore/23-update-dependencies` |

```bash
# Create and switch to branch
gh issue develop 42 --checkout
# Or manually:
git checkout -b fix/42-null-pointer-crash
```

---

### 4. Conventional Commits

All commits reference the issue number and follow conventional commit format:

**Format**: `<type>(<scope>): <description> (#issue)`

```bash
# Examples
git commit -m "fix(input): handle null pointer on empty submission (#42)"
git commit -m "feat(ui): add dark mode toggle to settings (#15)"
git commit -m "docs: update API reference (#33)"
git commit -m "chore(deps): bump swift-algorithms to 1.2.0 (#23)"
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

All Claude commits include:
```
Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

---

### 5. Pull Requests Required

All merges to `main` happen via PR:

```bash
# Create PR linked to issue
gh pr create --fill --body "Closes #42"

# Or with more detail
gh pr create \
  --title "Fix null pointer on empty input" \
  --body "## Summary
Adds validation before processing user input.

## Testing
- Added unit test for empty input case
- Manual testing on device

Closes #42"
```

**PR Requirements**:
- Title mirrors issue title
- Description includes `Closes #<issue-number>` for auto-close
- Self-review the diff before merging
- Squash merge to keep history clean

```bash
# Merge with squash
gh pr merge --squash --delete-branch
```

---

### 6. Close the Loop

After merging:
1. Verify issue auto-closed (or close manually)
2. Branch is deleted (automatic with `--delete-branch`)
3. Pull latest main

```bash
git checkout main
git pull
```

---

### 7. Roadmap and Project Management

**Active work**: Track in GitHub Projects with columns for `Backlog`, `Up Next`, `In Progress`, `Done`

**Strategic roadmap**: Maintain `ROADMAP.md` in repo root for high-level vision, linking to GitHub Project for details

```bash
# Add issue to project
gh project item-add <project-number> --owner <username> --url <issue-url>
```

---

### 8. Documentation Location

| Content | Location | Rationale |
|---------|----------|-----------|
| Technical specs | `/docs/specs/` | Version-controlled with code |
| API reference | `/docs/api/` | Changes with code |
| Architecture decisions | `/docs/adr/` | Historical context preserved |
| Screenshots for issues | `.github/screenshots/` | Referenced in issues |
| Active roadmap | GitHub Projects | Interactive, auto-updated |
| Strategic vision | `ROADMAP.md` | Stable reference |

**Do NOT create scattered markdown files** for features, bugs, or tasks. Use GitHub Issues instead.

---

### 9. Quick Reference Commands

```bash
# Full workflow example
gh issue create --title "Add user authentication" --label "enhancement"
# Returns: Created issue #15

gh issue develop 15 --checkout
# Creates and checks out: feat/15-add-user-authentication

# ... do work ...

git add .
git commit -m "feat(auth): implement login flow (#15)"
git push -u origin feat/15-add-user-authentication

gh pr create --fill --body "Closes #15"
gh pr merge --squash --delete-branch

git checkout main && git pull
```

---

### 10. Multi-Session Coordination (Multiple Claude Code Instances)

When running multiple Claude Code sessions in parallel (simulating multiple developers), GitHub is the **single source of truth** for coordination. Each session must check GitHub before starting work.

#### Before Starting Any Work

```bash
# Always sync and check for conflicts
git fetch origin
git pull origin main

# Check for existing issues to avoid duplicates
gh issue list --state open

# Check for in-progress branches that might conflict
git branch -r | grep -E "(feat|fix|refactor)/"

# Check open PRs
gh pr list --state open
```

#### Claim Work via GitHub

Assign yourself to an issue before starting to prevent parallel sessions from duplicating effort:

```bash
# Assign issue to prevent other sessions from picking it up
gh issue edit 42 --add-assignee @me

# Add "in-progress" label
gh issue edit 42 --add-label "in-progress"
```

#### Session Identification

Each Claude Code session should identify itself in commits and PR descriptions when relevant:

```bash
# Include session context in commit if helpful
git commit -m "feat(auth): add OAuth flow (#15)

Co-authored-by: Claude Code <claude@anthropic.com>"
```

#### Conflict Prevention Rules

1. **One issue = one session**: Never have two sessions working on the same issue
2. **Check before branching**: Always verify no existing branch for that issue
3. **Small, focused PRs**: Merge frequently to reduce conflict surface
4. **Communicate via issues**: Add comments to issues about approach before coding

```bash
# Add comment about intended approach before starting
gh issue comment 42 --body "Starting work on this. Approach: will add input validation in FormValidator.swift"
```

#### Resolving Conflicts

If a session discovers another session is working on related code:

```bash
# Check what the other branch changed
git fetch origin
git log origin/feat/15-related-feature --oneline -5

# Rebase onto their changes if they merged first
git rebase origin/main

# Or coordinate via issue comment
gh issue comment 42 --body "Noticed PR #18 touches the same files. Waiting for that to merge before continuing."
```

#### Recommended Parallel Workflow

```
Session A                          Session B
─────────                          ─────────
gh issue list                      gh issue list
Pick issue #10                     Pick issue #11 (different area)
gh issue edit 10 --add-assignee    gh issue edit 11 --add-assignee
Create branch fix/10-*             Create branch feat/11-*
Work...                            Work...
gh pr create                       gh pr create
gh pr merge                        Wait if touching same files
                                   git pull origin main
                                   gh pr merge
```

---

### 11. When to Skip (Emergencies Only)

Direct commits to `main` acceptable only for:
- Single-line typo fixes in documentation
- Broken CI that blocks all work

**Even then**: Create a retroactive issue documenting what was done.

---

### 12. Labels Taxonomy

**Type**: `bug`, `enhancement`, `refactor`, `chore`, `docs`

**Priority**: `P0-critical`, `P1-high`, `P2-medium`, `P3-low`

**Status**: `needs-triage`, `in-progress`, `blocked`, `help-wanted`, `good-first-issue`

---

### 13. CLAUDE.md Integration

This spec is a starting template. Each project may need modifications based on its specific requirements, tech stack, or team preferences.

#### Before Implementing This Workflow

When first applying this spec to a project, Claude Code should:

1. **Review the project context** - tech stack, existing conventions, team size
2. **Propose modifications** - suggest adaptations before implementing
3. **Discuss with user** - get explicit agreement on any deviations
4. **Document in CLAUDE.md** - save the agreed-upon workflow

#### Updating the Workflow

If workflow changes are needed mid-project:

1. **Discuss the change** - explain rationale, get user agreement
2. **Update CLAUDE.md** - document the new process
3. **Note the change** - add a comment in CLAUDE.md with date and reason

#### Why This Matters

- **Persistence**: Claude Code reads CLAUDE.md at session start - agreed rules carry forward
- **Consistency**: Multiple sessions follow the same customized workflow
- **Transparency**: User always knows what rules Claude Code is following
- **Adaptability**: Easy to evolve the process as the project matures

---

### 14. Checkpoint Command

When the user types **`checkpoint`**, Claude Code must verify GitHub is the complete source of truth before proceeding.

#### What Claude Code Does on `checkpoint`

Run these checks and report status:

```bash
# 1. Check for uncommitted changes
git status --porcelain

# 2. Check for unpushed commits
git log origin/main..HEAD --oneline

# 3. Check current branch (should be main if work is complete)
git branch --show-current

# 4. Check for open PRs that should be merged
gh pr list --state open --author @me

# 5. Check for issues still marked in-progress
gh issue list --label "in-progress" --assignee @me

# 6. Check remaining usage capacity
/usage
```

#### Critical: Issue Coverage Check

**For any uncommitted or session work, verify a GitHub issue exists that documents:**
- What problem was solved or feature was added
- The approach/solution taken
- Any decisions made during implementation

If work was done without a corresponding issue:
1. **Stop and create the issue first** with full details (see Section 1)
2. Then commit referencing that issue number
3. Report this gap in the checkpoint response

#### Response Format

**All clear:**
```
✓ CHECKPOINT PASSED
- No uncommitted changes
- No unpushed commits
- On main branch
- No open PRs
- No in-progress issues
- All work documented in issues

⏱ USAGE: X% remaining | Resets in Xh Xm
Ready to proceed.
```

**Issues found:**
```
⚠ CHECKPOINT FAILED
- 2 uncommitted files (src/App.swift, README.md)
- 1 unpushed commit
- Still on branch feat/42-dark-mode
- PR #18 still open

⏱ USAGE: X% remaining | Resets in Xh Xm
Fix these before moving on?
```

**Undocumented work found:**
```
⚠ CHECKPOINT FAILED - UNDOCUMENTED WORK
Work done this session without GitHub issue:
- [list of changes]

Creating issue to document this work before committing...
```

#### When to Use

- Before switching to a new feature/task
- Before ending a session
- Before starting parallel sessions
- Anytime you want to verify clean state

---

## Build Commands

```bash
# Regenerate Xcode project (after adding files)
xcodegen generate

# Build
xcodebuild -scheme Highball -configuration Debug build

# Run the built app
open ~/Library/Developer/Xcode/DerivedData/Highball-*/Build/Products/Debug/Highball.app

# Kill running app
pkill -f Highball
```

---

## Code Conventions

- **SwiftUI** for all views
- **StatusMonitor** (ObservableObject) for state management
- **Keychain** for API tokens, **UserDefaults** for other config
- **30-second polling** with exponential backoff on rate limits

---

## Key Files

| File | Purpose |
|------|---------|
| `StatusMonitor.swift` | Central state management |
| `RailwayAPIClient.swift` | GraphQL API calls |
| `StatusDropdownView.swift` | Main menu UI |
| `project.yml` | XcodeGen configuration |

---

## Project Documentation

| Content | Location |
|---------|----------|
| Code architecture | `DEVELOPMENT.md` |
| Project background | `ABOUT.md` |
| Contributing guide | `CONTRIBUTING.md` |
| Screenshots for issues | `.github/screenshots/` |
| Specs and decisions | GitHub Issues |
