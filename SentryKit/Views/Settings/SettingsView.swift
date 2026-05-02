// SettingsView.swift
// SentryKit
//
// Application settings and preferences.

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .environmentObject(settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            DashboardSettingsTab()
                .environmentObject(settings)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }

            NotificationSettingsTab()
                .environmentObject(settings)
                .environmentObject(notificationService)
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            AdvancedSettingsTab()
                .environmentObject(settings)
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Section("Auto Refresh") {
                Picker("Refresh interval", selection: $settings.autoRefreshInterval) {
                    Text("Disabled").tag(0)
                    Text("Every 1 minute").tag(60)
                    Text("Every 5 minutes").tag(300)
                    Text("Every 15 minutes").tag(900)
                    Text("Every 30 minutes").tag(1800)
                    Text("Every hour").tag(3600)
                }
            }

            Section("Data") {
                Toggle("Enable audit logging", isOn: $settings.enableAuditLog)

                Picker("Max audit entries", selection: $settings.maxAuditEntries) {
                    Text("1,000").tag(1000)
                    Text("5,000").tag(5000)
                    Text("10,000").tag(10000)
                    Text("50,000").tag(50000)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Dashboard Settings

struct DashboardSettingsTab: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Display") {
                Picker("Default view", selection: $settings.dashboardViewMode) {
                    ForEach(DashboardViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Picker("Sort order", selection: $settings.sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
            }

            Section("Filters") {
                Toggle("Show only granted permissions", isOn: $settings.showOnlyGranted)
                Toggle("Hide Apple system apps", isOn: $settings.hideAppleApps)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Notification Settings

struct NotificationSettingsTab: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable notifications", isOn: $settings.showNotifications)

                if settings.showNotifications {
                    Text("SentryKit will notify you when app permissions change.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Open Notification Settings") {
                        SystemSettingsService().openNotifications()
                    }
                }
            }

            Section("Monitoring") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(notificationService.isMonitoring ? "Active" : "Inactive")
                        .foregroundColor(notificationService.isMonitoring ? .green : .secondary)
                }

                if notificationService.isMonitoring {
                    Button("Stop Monitoring") {
                        notificationService.stopMonitoring()
                    }
                } else {
                    Button("Start Monitoring") {
                        notificationService.startMonitoring()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Advanced Settings

struct AdvancedSettingsTab: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Database") {
                Toggle("Read system-level database (requires admin)", isOn: $settings.readSystemDatabase)
                Toggle("Show unrecognized TCC services", isOn: $settings.showUnknownServices)
            }

            Section("Safety") {
                Toggle("Confirm before resetting permissions", isOn: $settings.confirmBeforeReset)
            }

            Section("Plugins") {
                Toggle("Enable plugin system", isOn: $settings.enablePlugins)

                if settings.enablePlugins {
                    Text("Plugins can extend SentryKit with custom functionality. Place plugin bundles in ~/Library/Application Support/SentryKit/Plugins/")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Open Plugins Folder") {
                        let path = FileManager.default.homeDirectoryForCurrentUser
                            .appendingPathComponent("Library/Application Support/SentryKit/Plugins")
                        try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
                        NSWorkspace.shared.open(path)
                    }
                }
            }

            Section("Danger Zone") {
                Button("Reset All Settings") {
                    // Reset UserDefaults
                    if let bundleID = Bundle.main.bundleIdentifier {
                        UserDefaults.standard.removePersistentDomain(forName: bundleID)
                    }
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("SentryKit")
                .font(.title.bold())

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Your macOS Privacy Permission Dashboard")
                .font(.body)
                .foregroundColor(.secondary)

            Divider()
                .frame(width: 200)

            Text("SentryKit helps you understand and manage the privacy permissions that apps request on your Mac.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 350)

            Text("Built with SwiftUI for macOS 13+")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}
