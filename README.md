# SentryKit

**macOS Privacy Permission Dashboard**

SentryKit is a native macOS utility that gives you full visibility into the privacy permissions (TCC) that applications request on your Mac. It reads the system's TCC database, presents every permission in a clean dashboard, and lets you take action — reset permissions, open System Settings, export audit reports, and monitor changes over time.

---

## Features

- **Central Dashboard** — See every app and every permission in one place. No more digging through System Settings panes one by one.
- **Menu Bar Quick Access** — Always-visible menu bar icon with quick stats, recent activity, and one-click actions.
- **25+ TCC Services** — Full coverage of Screen Recording, Accessibility, Full Disk Access, Input Monitoring, Microphone, Camera, Photos, Contacts, Calendar, Bluetooth, Location, Automation, and more.
- **Risk Classification** — Every permission is tagged Low / Medium / High risk so you can focus on what matters.
- **One-Click Reset** — Reset any permission for any app (or all apps for a service) using `tccutil` under the hood. Safety confirmations included.
- **Deep Links to System Settings** — Jump directly to the exact Privacy & Security pane for any service.
- **Audit Log** — Tracks permission changes over time. Know exactly when an app gained or lost access.
- **Trust List** — Mark apps as Trusted, Neutral, Suspicious, or Blocked. Visual indicators throughout the dashboard.
- **Export** — CSV export of all permissions, audit log export, and plain-text security reports for compliance.
- **Notifications** — Get notified when new permissions are granted or existing ones change.
- **Plugin System** — Extensible architecture for adding custom functionality via `.bundle` plugins.
- **Onboarding** — First-launch walkthrough explaining TCC and guiding Full Disk Access setup.
- **Launch at Login** — Uses `SMAppService` for clean login item registration (macOS 13+).

---

## Requirements

| Requirement | Minimum |
|---|---|
| macOS | 13.0 (Ventura) or later |
| Xcode | 15.0 or later |
| Swift | 5.9 or later |
| Architecture | Universal (Apple Silicon + Intel) |

**Full Disk Access** is required for SentryKit to read the TCC database. The app will guide you through granting this on first launch.

---

## Build Instructions

### 1. Open in Xcode

```bash
cd SentryKit
open SentryKit.xcodeproj
```

### 2. Configure Signing

1. Select the **SentryKit** target in the project navigator
2. Go to **Signing & Capabilities**
3. Select your **Team** from the dropdown
4. Xcode will automatically manage provisioning

### 3. Build & Run

- Press **⌘R** to build and run
- Or use **Product → Build** (⌘B) for a build-only

### 4. Grant Full Disk Access

After launching SentryKit for the first time:

1. Open **System Settings → Privacy & Security → Full Disk Access**
2. Click the **+** button
3. Navigate to SentryKit.app and add it
4. Enable the toggle
5. Restart SentryKit

### 5. Archive for Distribution

1. **Product → Archive**
2. In the Organizer, click **Distribute App**
3. Choose **Copy App** for direct distribution, or **Developer ID** for notarized distribution

---

## Project Structure

```
SentryKit/
├── SentryKit.xcodeproj/
│   └── project.pbxproj
├── SentryKit/
│   ├── App/
│   │   └── SentryKitApp.swift          # App entry point, menu bar, window config
│   ├── Models/
│   │   ├── TCCService.swift            # 25+ TCC service definitions with metadata
│   │   ├── TCCPermission.swift         # Permission entry model from TCC.db
│   │   ├── AuditLogEntry.swift         # Audit log entry model and store
│   │   ├── TrustEntry.swift            # Trust list entry model and store
│   │   └── AppSettings.swift           # User preferences (UserDefaults-backed)
│   ├── Services/
│   │   ├── TCCDatabaseService.swift    # SQLite reader for user/system TCC.db
│   │   ├── TCCResetService.swift       # tccutil reset command wrapper
│   │   ├── SystemSettingsService.swift # Deep links to System Settings panes
│   │   ├── AppInfoService.swift        # Bundle ID → app name/icon resolver
│   │   ├── ExportService.swift         # CSV and text report generation
│   │   └── NotificationService.swift   # Permission change monitoring
│   ├── ViewModels/
│   │   └── DashboardViewModel.swift    # Main ViewModel driving all views
│   ├── Views/
│   │   ├── Dashboard/
│   │   │   ├── MainContentView.swift   # Root NavigationSplitView with sidebar
│   │   │   └── DashboardOverviewView.swift # Stats cards and service grid
│   │   ├── Detail/
│   │   │   ├── ServiceDetailView.swift # Per-service permission list
│   │   │   ├── AppListView.swift       # All apps with permission summaries
│   │   │   ├── AuditLogView.swift      # Filterable audit log viewer
│   │   │   └── TrustListView.swift     # Trust list management
│   │   ├── MenuBar/
│   │   │   └── MenuBarView.swift       # Menu bar extra with quick actions
│   │   ├── Onboarding/
│   │   │   └── OnboardingView.swift    # First-launch walkthrough
│   │   └── Settings/
│   │       └── SettingsView.swift      # Preferences window (5 tabs)
│   ├── Plugins/
│   │   └── PluginProtocol.swift        # Plugin protocol and manager
│   ├── Utilities/
│   │   ├── LaunchAtLogin.swift         # SMAppService wrapper
│   │   └── Formatters.swift            # Date/string/color extensions
│   ├── Assets.xcassets/                # App icon and accent color
│   ├── SentryKit.entitlements          # App entitlements
│   └── Info.plist                      # App configuration
└── README.md
```

---

## Architecture

SentryKit follows the **MVVM** (Model-View-ViewModel) pattern:

- **Models** define the data structures (TCC services, permissions, audit entries, trust entries, settings)
- **Services** handle all system interaction (database reading, process execution, URL opening, notifications)
- **ViewModels** bridge models and views, managing state and business logic
- **Views** are pure SwiftUI, declarative, and stateless where possible

The app runs **outside the App Sandbox** (required to read `/Library/Application Support/com.apple.TCC/TCC.db`) but uses hardened runtime for security.

---

## How It Works

SentryKit reads the macOS TCC database files:

| Database | Path | Contains |
|---|---|---|
| User | `~/Library/Application Support/com.apple.TCC/TCC.db` | Per-user permission decisions |
| System | `/Library/Application Support/com.apple.TCC/TCC.db` | System-wide permission decisions (requires admin) |

These are SQLite databases with an `access` table containing columns like `service`, `client`, `auth_value`, `auth_reason`, `last_modified`, and more. SentryKit reads these in read-only mode and never modifies them directly.

Permission resets are performed via Apple's official `tccutil` command-line tool, which is the only supported way to programmatically reset TCC decisions.

---

## Plugin Development

SentryKit supports plugins via `.bundle` files placed in:

```
~/Library/Application Support/SentryKit/Plugins/
```

Plugins must conform to the `SentryKitPlugin` protocol (defined in `PluginProtocol.swift`) and implement at minimum:

```swift
@objc public protocol SentryKitPlugin: NSObjectProtocol {
    var pluginIdentifier: String { get }
    var pluginName: String { get }
    var pluginVersion: String { get }
    var pluginDescription: String { get }
    func pluginDidLoad()
    func pluginWillUnload()
}
```

Optional hooks include `didScanPermissions`, `permissionDidChange`, `customMenuItems`, and `generateReportSection`.

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| ⌘R | Refresh permissions |
| ⌘⇧E | Export permissions as CSV |
| ⌘, | Open Settings |

---

## Privacy & Security

- SentryKit **only reads** the TCC database. It never writes to it.
- Permission resets use Apple's official `tccutil` tool.
- **No data leaves your Mac.** No analytics, no telemetry, no network calls.
- All audit data is stored locally in `~/Library/Application Support/SentryKit/`.
- The app uses Hardened Runtime for additional security.

---

## Troubleshooting

**"No permissions found"**
→ Grant Full Disk Access to SentryKit in System Settings → Privacy & Security → Full Disk Access.

**"System database not accessible"**
→ The system-level TCC.db requires running with admin privileges. Enable "Read system-level database" in Settings → Advanced.

**Reset not working for some services**
→ Some services (like Accessibility) may require a logout/restart to fully take effect after reset.

---

## License

All rights reserved.
