# Development Guide

This document covers the architecture and implementation details of Highball.

## Project Structure

```
Highball/
├── HighballApp.swift          # App entry point, window definitions
├── Info.plist                 # App configuration
├── Highball.entitlements      # Sandbox and permissions
├── Assets.xcassets/           # Images and assets
├── Models/
│   ├── RailwayTypes.swift     # GraphQL response types
│   └── ServiceStatus.swift    # Deployment status enum, MonitoredService
├── Services/
│   ├── RailwayAPIClient.swift # GraphQL API client
│   ├── StatusMonitor.swift    # Main state management
│   ├── KeychainManager.swift  # Secure token storage
│   ├── NotificationManager.swift # macOS notifications
│   ├── LaunchAtLoginManager.swift # Login item management
│   └── HotKeyManager.swift    # Global keyboard shortcut
└── Views/
    ├── MenuBarIcon.swift      # Status icon in menu bar
    ├── StatusDropdownView.swift # Main dropdown menu
    ├── ServiceRowView.swift   # Individual service row
    ├── OnboardingView.swift   # First-time setup wizard
    ├── SettingsView.swift     # Preferences window
    └── AboutView.swift        # About window
```

## Architecture

### State Management

`StatusMonitor` is the central state manager, an `@MainActor` `ObservableObject` that:
- Holds the list of monitored services and their statuses
- Polls the Railway API every 5 seconds
- Triggers notifications on status changes
- Persists configuration to UserDefaults (token in Keychain)

### Railway API Integration

The app uses Railway's GraphQL API (`https://backboard.railway.com/graphql/v2`).

Key queries:
- `projects` - List user's projects and services
- `deployments` - Get latest deployment status (filtered by environment)

**Environment Filtering**: Deployments are filtered by `environmentId` to show only production status, avoiding confusion with staging/preview deployments.

### Menu Bar Implementation

Uses SwiftUI's `MenuBarExtra` with `.menuBarExtraStyle(.window)` for a native dropdown experience.

The icon changes based on aggregate status:
- Green arrow: All healthy
- Purple hammer: Building
- Blue ellipsis: Deploying
- Red exclamation: Failed/crashed
- Gray circle: Unknown

### Performance Optimizations

- Background polling doesn't show loading spinner (reduces UI churn)
- Services array only updates when status actually changes
- Environment migration runs once, not on every poll

## Building

### Requirements
- Xcode 15+
- macOS 13.0+ SDK
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

### Build Steps

```bash
# Generate Xcode project
xcodegen generate

# Build
xcodebuild -scheme Highball -configuration Debug build

# Or open in Xcode
open Highball.xcodeproj
```

### Dependencies

- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) - Keychain wrapper for secure token storage

## Key Implementation Details

### Token Storage
API tokens are stored in the macOS Keychain via KeychainAccess, not in UserDefaults.

### Notifications
Uses `UNUserNotificationCenter` with a custom delegate to handle notification actions (opening Railway dashboard).

### Global Shortcut
Implements `Cmd+Shift+H` using `NSEvent.addGlobalMonitorForEvents` to show/hide the menu from anywhere.

### Auto-Migration
Existing configurations without `environmentId` are automatically migrated on first refresh by fetching project environments and selecting "production".

## Adding New Features

1. **New API queries**: Add to `RailwayAPIClient.swift`, create response types in `RailwayTypes.swift`
2. **New UI**: Create view in `Views/`, add window in `HighballApp.swift` if needed
3. **New settings**: Add to `SettingsView.swift`, persist in appropriate manager
4. **Regenerate project**: Run `xcodegen generate` after adding new files
