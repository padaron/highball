# Claude Code Instructions for Highball

## Project Overview

Highball is a macOS menu bar app for monitoring Railway deployments. Built with Swift/SwiftUI.

- **Repo**: https://github.com/padaron/highball
- **Product Manager**: Ron Clarkson
- **Technical Lead**: Claude (Opus 4.5)

---

## GitHub Workflow

**GitHub is the single source of truth.** All features, bugs, specs, and roadmap live here. No direct commits to main. Every change starts with an issue.

### 1. Issues First

Before writing any code, create a GitHub Issue:

| Type | Label | Requirements |
|------|-------|--------------|
| Bugs | `bug` | Reproduction steps, expected vs actual, screenshots |
| Features | `enhancement` | Desired outcome, acceptance criteria |
| Refactors | `refactor` | What's changing and why |
| Chores | `chore` | Dependencies, config, documentation |

```bash
# Create bug issue
gh issue create --title "Fix: [description]" --label "bug" --body "## Steps to reproduce
1. ...

## Expected
...

## Actual
..."

# Create feature issue
gh issue create --title "Add: [description]" --label "enhancement" --body "## Description
...

## Acceptance Criteria
- [ ] ..."
```

### 2. Screenshots

Save screenshots to `.github/screenshots/` and reference in issues:

```bash
# Save screenshot
cp screenshot.png .github/screenshots/issue-123-description.png
git add .github/screenshots/
git commit -m "docs: add screenshot for #123"
git push

# Reference in issue (after pushing)
![screenshot](https://raw.githubusercontent.com/padaron/highball/main/.github/screenshots/issue-123-description.png)
```

### 3. Branch Per Issue

Create a branch from `main` for every issue:

| Type | Branch Format | Example |
|------|---------------|---------|
| Bug fix | `fix/<issue>-<desc>` | `fix/42-null-pointer` |
| Feature | `feat/<issue>-<desc>` | `feat/15-dark-mode` |
| Refactor | `refactor/<issue>-<desc>` | `refactor/28-api-client` |
| Chore | `chore/<issue>-<desc>` | `chore/23-update-deps` |

```bash
git checkout main
git pull
git checkout -b fix/42-null-pointer
```

### 4. Conventional Commits

Format: `<type>(<scope>): <description> (#issue)`

```bash
git commit -m "fix(api): handle rate limit responses (#42)"
git commit -m "feat(ui): add dark mode toggle (#15)"
git commit -m "docs: update API reference (#33)"
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

All Claude commits include:
```
Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### 5. Pull Requests

All merges to `main` happen via PR:

```bash
git push -u origin fix/42-null-pointer

gh pr create --title "Fix: handle rate limit responses" --body "## Summary
Added 429 detection and exponential backoff.

## Testing
- [x] Unit tests pass
- [x] Manual testing

Closes #42"
```

**PR Requirements:**
- Title mirrors issue
- Body includes `Closes #<issue>` for auto-close
- Squash merge to keep history clean

```bash
gh pr merge --squash --delete-branch
git checkout main && git pull
```

### 6. Labels

**Type:** `bug`, `enhancement`, `refactor`, `chore`, `docs`

**Priority:** `P0-critical`, `P1-high`, `P2-medium`, `P3-low`

**Status:** `needs-triage`, `blocked`, `help-wanted`, `good-first-issue`

### 7. After Fixing Issues

Update the issue with:
- **Root Cause**: Why it happened
- **Solution**: What was changed
- **Files Changed**: List of files
- **Commit/PR**: Reference

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

## Documentation Location

| Content | Location |
|---------|----------|
| Code architecture | `DEVELOPMENT.md` |
| Project background | `ABOUT.md` |
| Contributing guide | `CONTRIBUTING.md` |
| Screenshots for issues | `.github/screenshots/` |
| Specs and decisions | GitHub Issues |

**Do NOT create scattered markdown files for tasks.** Use GitHub Issues.
