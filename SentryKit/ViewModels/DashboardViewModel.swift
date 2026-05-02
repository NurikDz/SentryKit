// DashboardViewModel.swift
// SentryKit
//
// Main view model that drives the dashboard, managing permission data,
// filtering, sorting, and coordinating services.

import Foundation
import Combine
import AppKit

@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Published State

    @Published var permissions: [TCCPermission] = []
    @Published var appSummaries: [AppPermissionSummary] = []
    @Published var serviceSummaries: [ServicePermissionSummary] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasFullDiskAccess: Bool = false
    @Published var lastScanDate: Date?
    @Published var searchText: String = ""

    // MARK: - Filter State

    @Published var selectedService: TCCService?
    @Published var selectedApp: String?
    @Published var filterAuthValue: AuthValue?
    @Published var showOnlyGranted: Bool = false
    @Published var hideAppleApps: Bool = false

    // MARK: - Services

    let databaseService = TCCDatabaseService()
    let resetService = TCCResetService()
    let settingsService = SystemSettingsService()
    let exportService = ExportService()
    let auditLog: AuditLogStore
    let trustList: TrustListStore
    let notificationService: NotificationService

    // MARK: - Private

    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(auditLog: AuditLogStore, trustList: TrustListStore, notificationService: NotificationService) {
        self.auditLog = auditLog
        self.trustList = trustList
        self.notificationService = notificationService
    }

    // MARK: - Data Loading

    /// Performs a full scan of TCC databases.
    func loadPermissions() async {
        isLoading = true
        errorMessage = nil

        // Check Full Disk Access
        hasFullDiskAccess = databaseService.checkFullDiskAccess()

        do {
            let allPermissions = try databaseService.readAllPermissions(
                includeSystem: AppSettings.shared.readSystemDatabase
            )

            // Detect changes for audit log
            detectChanges(newPermissions: allPermissions)

            permissions = allPermissions
            buildSummaries()
            lastScanDate = Date()

            auditLog.addEntry(
                eventType: .scanCompleted,
                service: "All",
                client: "SentryKit",
                details: "Scanned \(allPermissions.count) permission entries"
            )

        } catch {
            errorMessage = error.localizedDescription
            if !hasFullDiskAccess {
                errorMessage = "Full Disk Access is required. Please grant SentryKit access in System Settings → Privacy & Security → Full Disk Access."
            }
        }

        isLoading = false
    }

    /// Refreshes data silently (no loading indicator).
    func refreshSilently() async {
        do {
            let allPermissions = try databaseService.readAllPermissions(
                includeSystem: AppSettings.shared.readSystemDatabase
            )
            detectChanges(newPermissions: allPermissions)
            permissions = allPermissions
            buildSummaries()
            lastScanDate = Date()
        } catch {
            // Silent failure for background refresh
            print("[DashboardViewModel] Silent refresh failed: \(error)")
        }
    }

    // MARK: - Auto Refresh

    func startAutoRefresh(interval: TimeInterval) {
        stopAutoRefresh()
        guard interval > 0 else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshSilently()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Filtered Data

    var filteredPermissions: [TCCPermission] {
        var result = permissions

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.client.lowercased().contains(query) ||
                $0.clientDisplayName.lowercased().contains(query) ||
                $0.serviceDisplayName.lowercased().contains(query)
            }
        }

        // Service filter
        if let service = selectedService {
            result = result.filter { $0.service == service.rawValue }
        }

        // App filter
        if let app = selectedApp {
            result = result.filter { $0.client == app }
        }

        // Auth value filter
        if let authValue = filterAuthValue {
            result = result.filter { $0.authValue == authValue }
        }

        // Show only granted
        if showOnlyGranted {
            result = result.filter { $0.authValue == .allowed }
        }

        // Hide Apple apps
        if hideAppleApps {
            result = result.filter { !$0.client.hasPrefix("com.apple.") }
        }

        return result
    }

    var filteredAppSummaries: [AppPermissionSummary] {
        var result = appSummaries

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.id.lowercased().contains(query) ||
                $0.displayName.lowercased().contains(query)
            }
        }

        if hideAppleApps {
            result = result.filter { !$0.id.hasPrefix("com.apple.") }
        }

        return result
    }

    var filteredServiceSummaries: [ServicePermissionSummary] {
        var result = serviceSummaries

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.service.displayName.lowercased().contains(query)
            }
        }

        return result
    }

    // MARK: - Statistics

    var totalApps: Int { appSummaries.count }
    var totalPermissions: Int { permissions.count }
    var totalAllowed: Int { permissions.filter { $0.authValue == .allowed }.count }
    var totalDenied: Int { permissions.filter { $0.authValue == .denied }.count }
    var highRiskCount: Int {
        permissions.filter { $0.authValue == .allowed && $0.resolvedService?.riskLevel == .high }.count
    }

    // MARK: - Actions

    /// Opens System Settings to the specified service pane.
    func openSettings(for service: TCCService) {
        settingsService.openPrivacyPane(for: service)
    }

    /// Opens System Settings to Full Disk Access.
    func openFullDiskAccessSettings() {
        settingsService.openFullDiskAccess()
    }

    /// Resets a service for a specific app.
    func resetPermission(service: TCCService, bundleID: String) async -> ResetResult {
        let result = await resetService.resetServiceForApp(service: service, bundleID: bundleID)

        auditLog.addEntry(
            eventType: .resetPerformed,
            service: service.rawValue,
            client: bundleID,
            details: result.success ? "Reset successful" : "Reset failed: \(result.error)"
        )

        // Refresh after reset
        await refreshSilently()

        return result
    }

    /// Resets a service for all apps.
    func resetServiceForAll(service: TCCService) async -> ResetResult {
        let result = await resetService.resetServiceForAll(service: service)

        auditLog.addEntry(
            eventType: .resetPerformed,
            service: service.rawValue,
            client: "All",
            details: result.success ? "Reset all successful" : "Reset all failed: \(result.error)"
        )

        await refreshSilently()

        return result
    }

    // MARK: - Export

    func exportCSV() {
        guard let url = exportService.presentSavePanel(
            allowedTypes: ["csv"],
            defaultName: "SentryKit_Permissions_\(dateStamp())"
        ) else { return }

        do {
            try exportService.exportToCSV(permissions: filteredPermissions, to: url)
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    func exportAuditLog() {
        guard let url = exportService.presentSavePanel(
            allowedTypes: ["csv"],
            defaultName: "SentryKit_AuditLog_\(dateStamp())"
        ) else { return }

        do {
            try exportService.exportAuditLogToCSV(entries: auditLog.entries, to: url)
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    func exportTextReport() {
        guard let url = exportService.presentSavePanel(
            allowedTypes: ["txt"],
            defaultName: "SentryKit_Report_\(dateStamp())"
        ) else { return }

        let report = exportService.generateTextReport(
            permissions: filteredPermissions,
            appSummaries: filteredAppSummaries
        )

        do {
            try report.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Helpers

    private func buildSummaries() {
        // Build app summaries
        let byApp = Dictionary(grouping: permissions, by: { $0.client })
        appSummaries = byApp.map { (client, perms) in
            AppPermissionSummary(
                id: client,
                clientType: perms.first?.clientType ?? .bundleID,
                permissions: perms
            )
        }.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

        // Build service summaries
        let byService = Dictionary(grouping: permissions, by: { $0.service })
        serviceSummaries = TCCService.allCases.compactMap { service in
            guard let perms = byService[service.rawValue], !perms.isEmpty else { return nil }
            return ServicePermissionSummary(service: service, permissions: perms)
        }
    }

    private func detectChanges(newPermissions: [TCCPermission]) {
        guard !permissions.isEmpty else { return }

        let oldMap = Dictionary(
            permissions.map { ("\($0.service)|\($0.client)", $0.authValue) },
            uniquingKeysWith: { first, _ in first }
        )

        for p in newPermissions {
            let key = "\(p.service)|\(p.client)"
            if let oldValue = oldMap[key] {
                if oldValue != p.authValue {
                    let eventType: AuditEventType = p.authValue == .allowed ? .permissionGranted :
                        (p.authValue == .denied ? .permissionDenied : .permissionChanged)

                    auditLog.addEntry(
                        eventType: eventType,
                        service: p.service,
                        client: p.client,
                        previousValue: oldValue.rawValue,
                        newValue: p.authValue.rawValue,
                        source: p.source
                    )
                }
            } else {
                auditLog.addEntry(
                    eventType: .permissionAdded,
                    service: p.service,
                    client: p.client,
                    newValue: p.authValue.rawValue,
                    source: p.source
                )
            }
        }
    }

    private func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}
