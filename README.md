# SentryKit<img width="16" height="16" alt="icon_32x32" src="https://github.com/user-attachments/assets/70a6d81c-5352-416a-b3d2-9bc7f01e6fc7" />

SentryKit is a native macOS utility that gives you full visibility into the privacy permissions (TCC) that applications request on your Mac. It reads the system's TCC database, presents every permission in a clean dashboard, and lets you take action — reset permissions, open System Settings, export audit reports, and monitor changes over time.
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
