// AuditLogEntry.swift
// SentryKit
//
// Audit log entry for tracking permission changes over time.

import Foundation

/// Represents a single audit log event.
struct AuditLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let eventType: AuditEventType
    let service: String
    let client: String
    let previousValue: Int?
    let newValue: Int?
    let source: DatabaseSource
    let details: String?

    var serviceDisplayName: String {
        TCCService(rawValue: service)?.displayName ?? service
    }

    var clientDisplayName: String {
        client.components(separatedBy: ".").last?.capitalized ?? client
    }

    var timestampFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }

    var previousAuthValue: AuthValue? {
        guard let v = previousValue else { return nil }
        return AuthValue(rawValue: v)
    }

    var newAuthValue: AuthValue? {
        guard let v = newValue else { return nil }
        return AuthValue(rawValue: v)
    }
}

/// Types of audit events.
enum AuditEventType: String, Codable, CaseIterable {
    case permissionGranted  = "Permission Granted"
    case permissionDenied   = "Permission Denied"
    case permissionChanged  = "Permission Changed"
    case permissionRemoved  = "Permission Removed"
    case permissionAdded    = "New Permission Entry"
    case resetPerformed     = "Reset Performed"
    case scanCompleted      = "Scan Completed"
    case appDetected        = "New App Detected"

    var symbolName: String {
        switch self {
        case .permissionGranted:  return "checkmark.circle.fill"
        case .permissionDenied:   return "xmark.circle.fill"
        case .permissionChanged:  return "arrow.triangle.2.circlepath"
        case .permissionRemoved:  return "trash.fill"
        case .permissionAdded:    return "plus.circle.fill"
        case .resetPerformed:     return "arrow.counterclockwise"
        case .scanCompleted:      return "magnifyingglass"
        case .appDetected:        return "app.badge"
        }
    }

    var colorName: String {
        switch self {
        case .permissionGranted:  return "green"
        case .permissionDenied:   return "red"
        case .permissionChanged:  return "orange"
        case .permissionRemoved:  return "red"
        case .permissionAdded:    return "blue"
        case .resetPerformed:     return "purple"
        case .scanCompleted:      return "gray"
        case .appDetected:        return "blue"
        }
    }
}

/// Persistent audit log storage using JSON file.
final class AuditLogStore: ObservableObject {
    @Published var entries: [AuditLogEntry] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("SentryKit", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.fileURL = appDir.appendingPathComponent("audit_log.json")
        load()
    }

    // MARK: - Public API

    func addEntry(
        eventType: AuditEventType,
        service: String,
        client: String,
        previousValue: Int? = nil,
        newValue: Int? = nil,
        source: DatabaseSource = .user,
        details: String? = nil
    ) {
        let entry = AuditLogEntry(
            id: UUID(),
            timestamp: Date(),
            eventType: eventType,
            service: service,
            client: client,
            previousValue: previousValue,
            newValue: newValue,
            source: source,
            details: details
        )
        entries.insert(entry, at: 0) // Most recent first
        save()
    }

    func clearLog() {
        entries.removeAll()
        save()
    }

    func entries(forClient client: String) -> [AuditLogEntry] {
        entries.filter { $0.client == client }
    }

    func entries(forService service: String) -> [AuditLogEntry] {
        entries.filter { $0.service == service }
    }

    func recentEntries(count: Int = 50) -> [AuditLogEntry] {
        Array(entries.prefix(count))
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            entries = try JSONDecoder().decode([AuditLogEntry].self, from: data)
        } catch {
            print("[AuditLogStore] Failed to load audit log: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[AuditLogStore] Failed to save audit log: \(error)")
        }
    }
}
