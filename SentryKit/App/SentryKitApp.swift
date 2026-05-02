// SentryKitApp.swift
// SentryKit
//
// Main application entry point.
// Configures the menu bar extra, main window, and shared state.

import SwiftUI

@main
struct SentryKitApp: App {

    // MARK: - Shared State

    @StateObject private var auditLog = AuditLogStore()
    @StateObject private var trustList = TrustListStore()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var settings = AppSettings.shared

    // MARK: - App Delegate

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Body

    var body: some Scene {
        // Main Window
        WindowGroup {
            MainContentView()
                .environmentObject(auditLog)
                .environmentObject(trustList)
                .environmentObject(notificationService)
                .environmentObject(settings)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    setupNotifications()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1100, height: 750)
        .commands {
            SentryKitCommands()
        }

        // Menu Bar Extra
        MenuBarExtra("SentryKit", systemImage: "lock.shield") {
            MenuBarView()
                .environmentObject(auditLog)
                .environmentObject(trustList)
                .environmentObject(notificationService)
                .environmentObject(settings)
        }
        .menuBarExtraStyle(.window)

        // Settings Window
        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(notificationService)
        }
    }

    // MARK: - Setup

    private func setupNotifications() {
        if settings.showNotifications {
            Task {
                let granted = await notificationService.requestAuthorization()
                if granted {
                    notificationService.startMonitoring(
                        interval: TimeInterval(settings.autoRefreshInterval > 0 ? settings.autoRefreshInterval : 300)
                    )
                }
            }
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app doesn't terminate when the last window is closed
        // (keeps running in menu bar)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in menu bar
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Re-open main window when clicking dock icon
            for window in NSApplication.shared.windows {
                if window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
        }
        return true
    }
}

// MARK: - Menu Commands

struct SentryKitCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Refresh Permissions") {
                NotificationCenter.default.post(name: .refreshPermissions, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)

            Divider()

            Button("Export Permissions as CSV…") {
                NotificationCenter.default.post(name: .exportCSV, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Button("Export Audit Log…") {
                NotificationCenter.default.post(name: .exportAuditLog, object: nil)
            }

            Button("Export Security Report…") {
                NotificationCenter.default.post(name: .exportReport, object: nil)
            }
        }

        CommandGroup(replacing: .help) {
            Button("SentryKit Help") {
                // Open help documentation
            }

            Button("Open Privacy & Security Settings") {
                SystemSettingsService().openPrivacySecurity()
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let refreshPermissions = Notification.Name("SentryKit.refreshPermissions")
    static let exportCSV = Notification.Name("SentryKit.exportCSV")
    static let exportAuditLog = Notification.Name("SentryKit.exportAuditLog")
    static let exportReport = Notification.Name("SentryKit.exportReport")
}
