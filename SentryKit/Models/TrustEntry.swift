// TrustEntry.swift
// SentryKit
//
// Trust list entries for known safe/unsafe applications.

import Foundation

/// Trust level assigned to an application or developer.
enum TrustLevel: String, Codable, CaseIterable {
    case trusted    = "Trusted"
    case neutral    = "Neutral"
    case suspicious = "Suspicious"
    case blocked    = "Blocked"

    var symbolName: String {
        switch self {
        case .trusted:    return "checkmark.shield.fill"
        case .neutral:    return "shield"
        case .suspicious: return "exclamationmark.shield.fill"
        case .blocked:    return "xmark.shield.fill"
        }
    }

    var colorName: String {
        switch self {
        case .trusted:    return "green"
        case .neutral:    return "gray"
        case .suspicious: return "orange"
        case .blocked:    return "red"
        }
    }
}

/// A trust list entry for an application or developer signing identity.
struct TrustEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var bundleID: String
    var developerName: String?
    var teamID: String?
    var trustLevel: TrustLevel
    var notes: String?
    var dateAdded: Date
    var dateModified: Date
    var isUserDefined: Bool  // vs. community/built-in

    static func create(
        bundleID: String,
        developerName: String? = nil,
        teamID: String? = nil,
        trustLevel: TrustLevel = .neutral,
        notes: String? = nil,
        isUserDefined: Bool = true
    ) -> TrustEntry {
        let now = Date()
        return TrustEntry(
            id: UUID(),
            bundleID: bundleID,
            developerName: developerName,
            teamID: teamID,
            trustLevel: trustLevel,
            notes: notes,
            dateAdded: now,
            dateModified: now,
            isUserDefined: isUserDefined
        )
    }
}

/// Persistent trust list storage.
final class TrustListStore: ObservableObject {
    @Published var entries: [TrustEntry] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("SentryKit", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.fileURL = appDir.appendingPathComponent("trust_list.json")
        load()
        loadBuiltInTrustList()
    }

    // MARK: - Public API

    func trustLevel(for bundleID: String) -> TrustLevel {
        entries.first(where: { $0.bundleID == bundleID })?.trustLevel ?? .neutral
    }

    func entry(for bundleID: String) -> TrustEntry? {
        entries.first(where: { $0.bundleID == bundleID })
    }

    func addOrUpdate(_ entry: TrustEntry) {
        if let index = entries.firstIndex(where: { $0.bundleID == entry.bundleID }) {
            var updated = entry
            updated.dateModified = Date()
            entries[index] = updated
        } else {
            entries.append(entry)
        }
        save()
    }

    func remove(bundleID: String) {
        entries.removeAll(where: { $0.bundleID == bundleID })
        save()
    }

    func setTrustLevel(_ level: TrustLevel, for bundleID: String) {
        if let index = entries.firstIndex(where: { $0.bundleID == bundleID }) {
            entries[index].trustLevel = level
            entries[index].dateModified = Date()
        } else {
            let entry = TrustEntry.create(bundleID: bundleID, trustLevel: level)
            entries.append(entry)
        }
        save()
    }

    // MARK: - Built-in Trust List

    private func loadBuiltInTrustList() {
        let builtIn: [(String, String, TrustLevel)] = [
            // Well-known trusted macOS utilities
            ("com.apple.finder", "Apple", .trusted),
            ("com.apple.Safari", "Apple", .trusted),
            ("com.apple.Terminal", "Apple", .trusted),
            ("com.apple.dt.Xcode", "Apple", .trusted),
            ("com.googlecode.iterm2", "George Nachman", .trusted),
            ("com.hegenberg.BetterTouchTool", "folivora.AI GmbH", .trusted),
            ("com.knollsoft.Rectangle", "Ryan Hanson", .trusted),
            ("org.mozilla.firefox", "Mozilla", .trusted),
            ("com.google.Chrome", "Google", .trusted),
            ("com.microsoft.VSCode", "Microsoft", .trusted),
            ("com.1password.1password", "AgileBits", .trusted),
            ("com.bjango.istatmenus", "Bjango", .trusted),
            ("com.macpaw.CleanMyMac4", "MacPaw", .trusted),
            ("com.cleanshot.CleanShotX", "CleanShot", .trusted),
            ("com.surteesstudios.Bartender", "Surtees Studios", .trusted),
            ("com.stairways.keyboardmaestro", "Stairways Software", .trusted),
            ("com.lwouis.alt-tab-macos", "Lwouis", .trusted),
            ("com.raycast.macos", "Raycast", .trusted),
            ("com.alfredapp.Alfred", "Running with Crayons", .trusted),
            ("com.flexibits.fantastical2.mac", "Flexibits", .trusted),
        ]

        for (bundleID, dev, level) in builtIn {
            if !entries.contains(where: { $0.bundleID == bundleID }) {
                let entry = TrustEntry.create(
                    bundleID: bundleID,
                    developerName: dev,
                    trustLevel: level,
                    isUserDefined: false
                )
                entries.append(entry)
            }
        }
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            entries = try JSONDecoder().decode([TrustEntry].self, from: data)
        } catch {
            print("[TrustListStore] Failed to load trust list: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries.filter(\.isUserDefined))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[TrustListStore] Failed to save trust list: \(error)")
        }
    }
}
