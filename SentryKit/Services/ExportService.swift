// ExportService.swift
// SentryKit
//
// Exports permission data to CSV and PDF formats for security audits.

import Foundation
import AppKit

/// Service for exporting permission data.
final class ExportService {

    // MARK: - CSV Export

    /// Exports permissions to a CSV file.
    func exportToCSV(permissions: [TCCPermission], to url: URL) throws {
        var csv = "Service,Client,Client Type,Status,Reason,Source,Last Modified,Indirect Object,Flags\n"

        for p in permissions {
            let service = escapeCSV(p.serviceDisplayName)
            let client = escapeCSV(p.client)
            let clientType = p.clientType == .bundleID ? "Bundle ID" : "Path"
            let status = p.authValue.description
            let reason = p.authReason?.description ?? "Unknown"
            let source = p.source.rawValue
            let lastModified = p.lastModifiedFormatted
            let indirect = escapeCSV(p.indirectObjectIdentifier ?? "")
            let flags = "\(p.flags)"

            csv += "\(service),\(client),\(clientType),\(status),\(reason),\(source),\(lastModified),\(indirect),\(flags)\n"
        }

        try csv.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Exports audit log to a CSV file.
    func exportAuditLogToCSV(entries: [AuditLogEntry], to url: URL) throws {
        var csv = "Timestamp,Event Type,Service,Client,Previous Value,New Value,Source,Details\n"

        for e in entries {
            let timestamp = e.timestampFormatted
            let eventType = e.eventType.rawValue
            let service = escapeCSV(e.serviceDisplayName)
            let client = escapeCSV(e.client)
            let prev = e.previousAuthValue?.description ?? ""
            let new = e.newAuthValue?.description ?? ""
            let source = e.source.rawValue
            let details = escapeCSV(e.details ?? "")

            csv += "\(timestamp),\(eventType),\(service),\(client),\(prev),\(new),\(source),\(details)\n"
        }

        try csv.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Plain Text Report

    /// Generates a plain-text security audit report.
    func generateTextReport(permissions: [TCCPermission], appSummaries: [AppPermissionSummary]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        var report = """
        ╔══════════════════════════════════════════════════════════════╗
        ║                    SentryKit Security Audit                  ║
        ║                    Permission Report                        ║
        ╚══════════════════════════════════════════════════════════════╝

        Generated: \(dateFormatter.string(from: Date()))
        Machine: \(Host.current().localizedName ?? "Unknown")
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Total Permissions: \(permissions.count)
        Total Apps: \(appSummaries.count)

        ══════════════════════════════════════════════════════════════

        SUMMARY BY SERVICE
        ──────────────────────────────────────────────────────────────

        """

        // Group by service
        let byService = Dictionary(grouping: permissions, by: { $0.service })
        let sortedServices = byService.keys.sorted()

        for service in sortedServices {
            guard let perms = byService[service] else { continue }
            let displayName = TCCService(rawValue: service)?.displayName ?? service
            let allowed = perms.filter { $0.authValue == .allowed }.count
            let denied = perms.filter { $0.authValue == .denied }.count

            report += "  \(displayName)\n"
            report += "    Allowed: \(allowed)  |  Denied: \(denied)  |  Total: \(perms.count)\n"

            for p in perms {
                let status = p.authValue == .allowed ? "✓" : (p.authValue == .denied ? "✗" : "?")
                report += "    [\(status)] \(p.client) — \(p.authValue.description) (\(p.authReason?.description ?? "Unknown"))\n"
            }
            report += "\n"
        }

        report += """

        ══════════════════════════════════════════════════════════════

        HIGH-RISK PERMISSIONS
        ──────────────────────────────────────────────────────────────

        """

        let highRisk = permissions.filter {
            $0.authValue == .allowed && ($0.resolvedService?.riskLevel == .high)
        }

        if highRisk.isEmpty {
            report += "  No high-risk permissions currently granted.\n"
        } else {
            for p in highRisk {
                report += "  ⚠ \(p.client) → \(p.serviceDisplayName)\n"
                report += "    Reason: \(p.authReason?.description ?? "Unknown")  |  Since: \(p.lastModifiedFormatted)\n"
            }
        }

        report += """

        ══════════════════════════════════════════════════════════════

        APPS WITH MOST PERMISSIONS
        ──────────────────────────────────────────────────────────────

        """

        let topApps = appSummaries.sorted { $0.allowedCount > $1.allowedCount }.prefix(20)
        for app in topApps {
            report += "  \(app.displayName) (\(app.bundleID))\n"
            report += "    Allowed: \(app.allowedCount)  |  Denied: \(app.deniedCount)  |  Total: \(app.totalCount)\n"
        }

        report += "\n══════════════════════════════════════════════════════════════\n"
        report += "End of Report — Generated by SentryKit\n"

        return report
    }

    // MARK: - Save Dialog

    /// Presents a save panel and returns the selected URL.
    func presentSavePanel(
        title: String = "Export Report",
        allowedTypes: [String] = ["csv", "txt"],
        defaultName: String = "SentryKit_Report"
    ) -> URL? {
        let panel = NSSavePanel()
        panel.title = title
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true

        if #available(macOS 14.0, *) {
            // Use UTType if available
        }

        let response = panel.runModal()
        return response == .OK ? panel.url : nil
    }

    // MARK: - Helpers

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
