// TCCDatabaseService.swift
// SentryKit
//
// Reads and parses the macOS TCC SQLite databases.
// Requires Full Disk Access to read the user and system TCC databases.

import Foundation
import SQLite3

/// Errors that can occur when accessing the TCC database.
enum TCCDatabaseError: LocalizedError {
    case databaseNotFound(path: String)
    case cannotOpen(path: String, message: String)
    case queryFailed(message: String)
    case noFullDiskAccess

    var errorDescription: String? {
        switch self {
        case .databaseNotFound(let path):
            return "TCC database not found at: \(path)"
        case .cannotOpen(let path, let message):
            return "Cannot open TCC database at \(path): \(message)"
        case .queryFailed(let message):
            return "Database query failed: \(message)"
        case .noFullDiskAccess:
            return "SentryKit requires Full Disk Access to read the TCC database. Please grant access in System Settings → Privacy & Security → Full Disk Access."
        }
    }
}

/// Service responsible for reading the TCC SQLite databases.
final class TCCDatabaseService {

    // MARK: - Database Paths

    /// Path to the current user's TCC database.
    static var userDatabasePath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/com.apple.TCC/TCC.db"
    }

    /// Path to the system-wide TCC database.
    static let systemDatabasePath = "/Library/Application Support/com.apple.TCC/TCC.db"

    // MARK: - Public API

    /// Reads all permission entries from the user TCC database.
    func readUserDatabase() throws -> [TCCPermission] {
        return try readDatabase(at: Self.userDatabasePath, source: .user)
    }

    /// Reads all permission entries from the system TCC database.
    func readSystemDatabase() throws -> [TCCPermission] {
        return try readDatabase(at: Self.systemDatabasePath, source: .system)
    }

    /// Reads all permissions from both user and system databases.
    func readAllPermissions(includeSystem: Bool = true) throws -> [TCCPermission] {
        var permissions: [TCCPermission] = []

        do {
            permissions.append(contentsOf: try readUserDatabase())
        } catch {
            print("[TCCDatabaseService] Warning: Could not read user database: \(error)")
        }

        if includeSystem {
            do {
                permissions.append(contentsOf: try readSystemDatabase())
            } catch {
                print("[TCCDatabaseService] Warning: Could not read system database: \(error)")
            }
        }

        if permissions.isEmpty {
            throw TCCDatabaseError.noFullDiskAccess
        }

        return permissions
    }

    /// Checks if Full Disk Access is likely available by testing database readability.
    func checkFullDiskAccess() -> Bool {
        let path = Self.userDatabasePath
        return FileManager.default.isReadableFile(atPath: path)
    }

    // MARK: - Private Implementation

    private func readDatabase(at path: String, source: DatabaseSource) throws -> [TCCPermission] {
        guard FileManager.default.fileExists(atPath: path) else {
            throw TCCDatabaseError.databaseNotFound(path: path)
        }

        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX

        let result = sqlite3_open_v2(path, &db, flags, nil)
        guard result == SQLITE_OK, let database = db else {
            let message = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            sqlite3_close(db)
            throw TCCDatabaseError.cannotOpen(path: path, message: message)
        }

        defer { sqlite3_close(database) }

        return try queryAccessTable(database: database, source: source)
    }

    private func queryAccessTable(database: OpaquePointer, source: DatabaseSource) throws -> [TCCPermission] {
        let query = """
            SELECT service, client, client_type, auth_value, auth_reason, auth_version,
                   indirect_object_identifier, flags, last_modified
            FROM access
            ORDER BY last_modified DESC
            """

        var statement: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(database, query, -1, &statement, nil)

        guard prepareResult == SQLITE_OK, let stmt = statement else {
            let message = String(cString: sqlite3_errmsg(database))
            throw TCCDatabaseError.queryFailed(message: message)
        }

        defer { sqlite3_finalize(stmt) }

        var permissions: [TCCPermission] = []

        while sqlite3_step(stmt) == SQLITE_ROW {
            let service = columnText(stmt, index: 0) ?? ""
            let client = columnText(stmt, index: 1) ?? ""
            let clientType = Int(sqlite3_column_int(stmt, 2))
            let authValue = Int(sqlite3_column_int(stmt, 3))
            let authReason = Int(sqlite3_column_int(stmt, 4))
            let authVersion = Int(sqlite3_column_int(stmt, 5))
            let indirectObject = columnText(stmt, index: 6)
            let flags = Int(sqlite3_column_int(stmt, 7))
            let lastModified = Int(sqlite3_column_int64(stmt, 8))

            let permission = TCCPermission.from(
                service: service,
                client: client,
                clientType: clientType,
                authValue: authValue,
                authReason: authReason,
                authVersion: authVersion,
                indirectObjectIdentifier: indirectObject,
                flags: flags,
                lastModified: lastModified,
                source: source
            )

            permissions.append(permission)
        }

        return permissions
    }

    private func columnText(_ statement: OpaquePointer, index: Int32) -> String? {
        guard let cString = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: cString)
    }
}
