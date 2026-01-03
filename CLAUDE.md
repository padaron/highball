# Claude Code Instructions for Highball

## Project Overview

Highball is a macOS menu bar app for monitoring Railway deployments. Built with Swift/SwiftUI.

- **Repo**: https://github.com/padaron/highball
- **Product Manager**: Ron Clarkson
- **Technical Lead**: Claude (Opus 4.5)

---

## GitHub Workflow

Follow the GitHub Workflow Spec at `~/projects/resources/docs/GITHUB-WORKFLOW.md` (v2.17)

Check version on `checkpoint` command.

### Project-Specific Settings

**Commit scopes for this project**: `ui`, `api`, `config`, `menu`

**All Claude commits include**:
```
Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

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
