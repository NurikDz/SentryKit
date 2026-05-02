// TCCPermission.swift
// SentryKit
//
// Represents a single permission entry from the TCC database.

import Foundation

/// Authorization status for a TCC permission entry.
enum AuthValue: Int, Codable, CustomStringConvertible {
    case denied   = 0
    case unknown  = 1
    case allowed  = 2
    case limited  = 3

    var description: String {
        switch self {
        case .denied:   return "Denied"
        case .unknown:  return "Unknown"
        case .allowed:  return "Allowed"
        case .limited:  return "Limited"
        }
    }

    var symbolName: String {
        switch self {
        case .denied:   return "xmark.circle.fill"
        case .unknown:  return "questionmark.circle.fill"
        case .allowed:  return "checkmark.circle.fill"
        case .limited:  return "minus.circle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .denied:   return "red"
        case .unknown:  return "yellow"
        case .allowed:  return "green"
        case .limited:  return "orange"
        }
    }
}

/// Reason why the authorization was set.
enum AuthReason: Int, Codable, CustomStringConvertible {
    case error              = 1
    case userConsent        = 2
    case userSet            = 3
    case systemSet          = 4
    case servicePolicy      = 5
    case mdmPolicy          = 6
    case overridePolicy     = 7
    case missingUsageString = 8
    case promptTimeout      = 9
    case preflightUnknown   = 10
    case entitled           = 11
    case appTypePolicy      = 12

    var description: String {
        switch self {
        case .error:              return "Error"
        case .userConsent:        return "User Consent"
        case .userSet:            return "User Set"
        case .systemSet:          return "System Set"
        case .servicePolicy:      return "Service Policy"
        case .mdmPolicy:          return "MDM Policy"
        case .overridePolicy:     return "Override Policy"
        case .missingUsageString: return "Missing Usage String"
        case .promptTimeout:      return "Prompt Timeout"
        case .preflightUnknown:   return "Preflight Unknown"
        case .entitled:           return "Entitled"
        case .appTypePolicy:      return "App Type Policy"
        }
    }
}

/// Whether the client is identified by bundle ID or absolute path.
enum ClientType: Int, Codable {
    case bundleID     = 0
    case absolutePath = 1
}

/// Source database (user-level or system-level).
enum DatabaseSource: String, Codable {
    case user   = "User"
    case system = "System"
}

/// A single permission entry parsed from the TCC.db `access` table.
struct TCCPermission: Identifiable, Codable, Hashable {
    let id: UUID
    let service: String
    let client: String
    let clientType: ClientType
    let authValue: AuthValue
    let authReason: AuthReason?
    let authVersion: Int
    let indirectObjectIdentifier: String?
    let flags: Int
    let lastModified: Date
    let source: DatabaseSource

    /// Resolved TCC service enum, if recognized.
    var resolvedService: TCCService? {
        TCCService(rawValue: service)
    }

    /// Display name for the service.
    var serviceDisplayName: String {
        resolvedService?.displayName ?? service
            .replacingOccurrences(of: "kTCCService", with: "")
            .replacingOccurrences(of: "SystemPolicy", with: "System Policy ")
    }

    /// Display name for the client application.
    var clientDisplayName: String {
        if clientType == .bundleID {
            // Extract the last component of the bundle ID as a readable name
            return client.components(separatedBy: ".").last?.capitalized ?? client
        } else {
            // Extract the filename from the path
            return (client as NSString).lastPathComponent
        }
    }

    /// Formatted last modified date string.
    var lastModifiedFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastModified)
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TCCPermission, rhs: TCCPermission) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Factory

    /// Creates a TCCPermission from raw SQLite row values.
    static func from(
        service: String,
        client: String,
        clientType: Int,
        authValue: Int,
        authReason: Int,
        authVersion: Int,
        indirectObjectIdentifier: String?,
        flags: Int,
        lastModified: Int,
        source: DatabaseSource
    ) -> TCCPermission {
        TCCPermission(
            id: UUID(),
            service: service,
            client: client,
            clientType: ClientType(rawValue: clientType) ?? .bundleID,
            authValue: AuthValue(rawValue: authValue) ?? .unknown,
            authReason: AuthReason(rawValue: authReason),
            authVersion: authVersion,
            indirectObjectIdentifier: indirectObjectIdentifier == "UNUSED" ? nil : indirectObjectIdentifier,
            flags: flags,
            lastModified: Date(timeIntervalSince1970: TimeInterval(lastModified)),
            source: source
        )
    }
}

/// Aggregated permission info for a single application across all services.
struct AppPermissionSummary: Identifiable, Hashable {
    static func == (lhs: AppPermissionSummary, rhs: AppPermissionSummary) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String // bundle ID or path
    let clientType: ClientType
    let permissions: [TCCPermission]

    var displayName: String {
        permissions.first?.clientDisplayName ?? id
    }

    var bundleID: String {
        id
    }

    var allowedCount: Int {
        permissions.filter { $0.authValue == .allowed }.count
    }

    var deniedCount: Int {
        permissions.filter { $0.authValue == .denied }.count
    }

    var unknownCount: Int {
        permissions.filter { $0.authValue == .unknown || $0.authValue == .limited }.count
    }

    var totalCount: Int {
        permissions.count
    }

    var highestRisk: RiskLevel {
        permissions
            .filter { $0.authValue == .allowed }
            .compactMap { $0.resolvedService?.riskLevel }
            .max() ?? .low
    }

    var lastModified: Date {
        permissions.map(\.lastModified).max() ?? .distantPast
    }
}

/// Aggregated permission info for a single service across all apps.
struct ServicePermissionSummary: Identifiable {
    let service: TCCService
    let permissions: [TCCPermission]

    var id: String { service.id }

    var allowedApps: [TCCPermission] {
        permissions.filter { $0.authValue == .allowed }
    }

    var deniedApps: [TCCPermission] {
        permissions.filter { $0.authValue == .denied }
    }

    var unknownApps: [TCCPermission] {
        permissions.filter { $0.authValue == .unknown || $0.authValue == .limited }
    }

    var totalApps: Int {
        permissions.count
    }
}
