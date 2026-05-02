// AppInfoService.swift
// SentryKit
//
// Resolves bundle identifiers to application metadata (name, icon, path).

import Foundation
import AppKit

/// Cached application metadata.
struct AppInfo {
    let bundleID: String
    let name: String
    let path: String?
    let icon: NSImage?
    let version: String?
    let isSigned: Bool
    let isAppleApp: Bool
    let teamID: String?
}

/// Service for resolving application information from bundle identifiers.
final class AppInfoService {

    /// Shared singleton instance with caching.
    static let shared = AppInfoService()

    private var cache: [String: AppInfo] = [:]
    private let queue = DispatchQueue(label: "com.tccvault.appinfo", attributes: .concurrent)

    private init() {}

    // MARK: - Public API

    /// Resolves an AppInfo from a bundle identifier or path.
    func resolve(client: String, clientType: ClientType) -> AppInfo {
        let cacheKey = client

        // Check cache first
        if let cached = queue.sync(execute: { cache[cacheKey] }) {
            return cached
        }

        let info: AppInfo
        if clientType == .bundleID {
            info = resolveFromBundleID(client)
        } else {
            info = resolveFromPath(client)
        }

        queue.async(flags: .barrier) {
            self.cache[cacheKey] = info
        }

        return info
    }

    /// Clears the cache.
    func clearCache() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }

    // MARK: - Private Resolution

    private func resolveFromBundleID(_ bundleID: String) -> AppInfo {
        // Try to find the app using NSWorkspace
        let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?.path

        var name = bundleID.components(separatedBy: ".").last?.capitalized ?? bundleID
        var icon: NSImage? = nil
        var version: String? = nil
        var isSigned = false
        var isAppleApp = bundleID.hasPrefix("com.apple.")
        var teamID: String? = nil

        if let appPath = path {
            let bundle = Bundle(path: appPath)
            name = bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? (appPath as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
            version = bundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            icon = NSWorkspace.shared.icon(forFile: appPath)
            icon?.size = NSSize(width: 32, height: 32)

            // Check code signing
            let sigInfo = checkCodeSigning(at: appPath)
            isSigned = sigInfo.isSigned
            teamID = sigInfo.teamID
            if teamID == "apple" || bundleID.hasPrefix("com.apple.") {
                isAppleApp = true
            }
        } else {
            // App not installed — use generic icon
            icon = NSImage(systemSymbolName: "app", accessibilityDescription: name)
        }

        return AppInfo(
            bundleID: bundleID,
            name: name,
            path: path,
            icon: icon,
            version: version,
            isSigned: isSigned,
            isAppleApp: isAppleApp,
            teamID: teamID
        )
    }

    private func resolveFromPath(_ path: String) -> AppInfo {
        let name = (path as NSString).lastPathComponent
        let exists = FileManager.default.fileExists(atPath: path)
        var icon: NSImage? = nil

        if exists {
            icon = NSWorkspace.shared.icon(forFile: path)
            icon?.size = NSSize(width: 32, height: 32)
        }

        return AppInfo(
            bundleID: path,
            name: name,
            path: exists ? path : nil,
            icon: icon,
            version: nil,
            isSigned: false,
            isAppleApp: path.hasPrefix("/System/") || path.hasPrefix("/usr/"),
            teamID: nil
        )
    }

    private func checkCodeSigning(at path: String) -> (isSigned: Bool, teamID: String?) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["-dvv", path]

        let pipe = Pipe()
        process.standardError = pipe // codesign outputs to stderr
        process.standardOutput = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            let isSigned = process.terminationStatus == 0

            // Extract TeamIdentifier
            var teamID: String? = nil
            if let range = output.range(of: "TeamIdentifier=") {
                let start = range.upperBound
                let end = output[start...].firstIndex(of: "\n") ?? output.endIndex
                let value = String(output[start..<end]).trimmingCharacters(in: .whitespaces)
                if value != "not set" {
                    teamID = value
                }
            }

            return (isSigned, teamID)
        } catch {
            return (false, nil)
        }
    }
}
