// NotificationService.swift
// SentryKit
//
// Monitors TCC database changes and sends user notifications.

import Foundation
import UserNotifications

/// Service for monitoring TCC changes and delivering notifications.
final class NotificationService: ObservableObject {

    @Published var isMonitoring: Bool = false

    private var monitorTimer: Timer?
    private var previousSnapshot: [String: Int] = [:] // "service|client" -> authValue
    private let databaseService = TCCDatabaseService()
    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    /// Requests notification permission from the user.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("[NotificationService] Authorization error: \(error)")
            return false
        }
    }

    // MARK: - Monitoring

    /// Starts periodic monitoring of the TCC database for changes.
    func startMonitoring(interval: TimeInterval = 60) {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Take initial snapshot
        takeSnapshot()

        monitorTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    /// Stops monitoring.
    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        isMonitoring = false
    }

    // MARK: - Private

    private func takeSnapshot() {
        guard let permissions = try? databaseService.readAllPermissions() else { return }
        previousSnapshot = [:]
        for p in permissions {
            let key = "\(p.service)|\(p.client)"
            previousSnapshot[key] = p.authValue.rawValue
        }
    }

    private func checkForChanges() {
        guard let permissions = try? databaseService.readAllPermissions() else { return }

        var currentSnapshot: [String: Int] = [:]
        for p in permissions {
            let key = "\(p.service)|\(p.client)"
            currentSnapshot[key] = p.authValue.rawValue
        }

        // Detect new entries
        for (key, value) in currentSnapshot {
            if let previousValue = previousSnapshot[key] {
                if previousValue != value {
                    // Permission changed
                    let parts = key.components(separatedBy: "|")
                    let service = parts.first ?? "Unknown"
                    let client = parts.last ?? "Unknown"
                    let serviceName = TCCService(rawValue: service)?.displayName ?? service
                    let appName = client.components(separatedBy: ".").last?.capitalized ?? client
                    let newStatus = AuthValue(rawValue: value)?.description ?? "Unknown"

                    sendNotification(
                        title: "Permission Changed",
                        body: "\(appName) — \(serviceName) is now \(newStatus)"
                    )
                }
            } else {
                // New permission entry
                let parts = key.components(separatedBy: "|")
                let service = parts.first ?? "Unknown"
                let client = parts.last ?? "Unknown"
                let serviceName = TCCService(rawValue: service)?.displayName ?? service
                let appName = client.components(separatedBy: ".").last?.capitalized ?? client

                sendNotification(
                    title: "New Permission Request",
                    body: "\(appName) requested \(serviceName) access"
                )
            }
        }

        // Detect removed entries
        for key in previousSnapshot.keys where currentSnapshot[key] == nil {
            let parts = key.components(separatedBy: "|")
            let service = parts.first ?? "Unknown"
            let client = parts.last ?? "Unknown"
            let serviceName = TCCService(rawValue: service)?.displayName ?? service
            let appName = client.components(separatedBy: ".").last?.capitalized ?? client

            sendNotification(
                title: "Permission Removed",
                body: "\(appName) — \(serviceName) entry was removed"
            )
        }

        previousSnapshot = currentSnapshot
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "TCC_CHANGE"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to deliver notification: \(error)")
            }
        }
    }
}
