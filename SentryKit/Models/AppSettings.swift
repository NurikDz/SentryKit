// AppSettings.swift
// SentryKit
//
// User preferences and application settings.

import Foundation
import SwiftUI

/// Application-wide settings stored in UserDefaults.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - General

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("showMenuBarIcon") var showMenuBarIcon: Bool = true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("autoRefreshInterval") var autoRefreshInterval: Int = 300 // seconds, 0 = disabled
    @AppStorage("showNotifications") var showNotifications: Bool = true

    // MARK: - Dashboard

    @AppStorage("dashboardViewMode") var dashboardViewMode: DashboardViewMode = .byService
    @AppStorage("showOnlyGranted") var showOnlyGranted: Bool = false
    @AppStorage("hideAppleApps") var hideAppleApps: Bool = false
    @AppStorage("sortOrder") var sortOrder: SortOrder = .alphabetical

    // MARK: - Audit

    @AppStorage("enableAuditLog") var enableAuditLog: Bool = true
    @AppStorage("maxAuditEntries") var maxAuditEntries: Int = 10000

    // MARK: - Advanced

    @AppStorage("readSystemDatabase") var readSystemDatabase: Bool = true
    @AppStorage("showUnknownServices") var showUnknownServices: Bool = false
    @AppStorage("confirmBeforeReset") var confirmBeforeReset: Bool = true

    // MARK: - Plugin

    @AppStorage("enablePlugins") var enablePlugins: Bool = true
}

// MARK: - Enums

enum DashboardViewMode: String, CaseIterable {
    case byService = "By Service"
    case byApp     = "By App"
    case timeline  = "Timeline"
}

enum SortOrder: String, CaseIterable {
    case alphabetical  = "Alphabetical"
    case recentlyChanged = "Recently Changed"
    case riskLevel     = "Risk Level"
    case permissionCount = "Permission Count"
}
