# Claude Code Instructions for Highball

## Project Overview

Highball is a macOS menu bar app for monitoring Railway deployments. Built with Swift/SwiftUI.

- **Repo**: https://github.com/padaron/highball
- **Product Manager**: Ron Clarkson
- **Technical Lead**: Claude (Opus 4.5)

## GitHub Workflow

**All bugs and features go through GitHub Issues.**

### When a Bug is Found

1. Create a GitHub issue immediately with:
   - Clear title describing the bug
   - **Problem**: What's happening, steps to reproduce
   - **Expected**: What should happen
   - **Environment**: macOS version, app version if relevant

2. After fixing, update the issue with:
   - **Root Cause**: Why the bug occurred
   - **Solution**: What was changed to fix it
   - **Files Changed**: List of modified files
   - **Commit**: Reference the commit hash

3. Close the issue with the fix commit

### When a Feature is Requested

1. Create a GitHub issue with:
   - Clear title describing the feature
   - **Description**: What the feature does
   - **User Value**: Why this is needed
   - **Acceptance Criteria**: How we know it's done

2. After implementing, update the issue with:
   - **Implementation**: How it was built
   - **Files Changed**: List of new/modified files
   - **Commit**: Reference the commit hash

3. Close the issue with the implementation commit

### Issue Commands

```bash
# Create bug issue
gh issue create --title "Bug: [description]" --body "..."

# Create feature issue
gh issue create --title "Feature: [description]" --body "..."

# Close issue with commit reference
gh issue close [number] --comment "Fixed in commit [hash]"
```

## Build Commands

```bash
# Regenerate Xcode project (after adding files)
xcodegen generate

# Build
xcodebuild -scheme Highball -configuration Debug build

# Run the built app
open ~/Library/Developer/Xcode/DerivedData/Highball-*/Build/Products/Debug/Highball.app
```

## Code Conventions

- Use SwiftUI for all views
- State management through `StatusMonitor` (ObservableObject)
- API tokens stored in Keychain, other config in UserDefaults
- Commit messages should be concise, explain the "why"
- All Claude commits include `Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>`

## Key Files

- `StatusMonitor.swift` - Central state management
- `RailwayAPIClient.swift` - GraphQL API calls
- `StatusDropdownView.swift` - Main menu UI
- `project.yml` - XcodeGen configuration
