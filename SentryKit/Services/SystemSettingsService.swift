// SystemSettingsService.swift
// SentryKit
//
// Opens System Settings to specific Privacy & Security panes.

import Foundation
import AppKit

/// Service for deep-linking into macOS System Settings.
final class SystemSettingsService {

    /// Base URL scheme for System Settings (works on macOS 13+).
    private static let baseScheme = "x-apple.systempreferences"
    private static let securityPaneID = "com.apple.preference.security"

    /// Opens System Settings to the Privacy & Security overview.
    func openPrivacySecurity() {
        let urlString = "\(Self.baseScheme):\(Self.securityPaneID)"
        openURL(urlString)
    }

    /// Opens System Settings to a specific privacy category.
    /// - Parameter service: The TCC service to open the settings pane for.
    func openPrivacyPane(for service: TCCService) {
        guard let anchor = service.settingsURLAnchor else {
            openPrivacySecurity()
            return
        }
        let urlString = "\(Self.baseScheme):\(Self.securityPaneID)?\(anchor)"
        openURL(urlString)
    }

    /// Opens the Full Disk Access pane (commonly needed for SentryKit itself).
    func openFullDiskAccess() {
        let urlString = "\(Self.baseScheme):\(Self.securityPaneID)?Privacy_AllFiles"
        openURL(urlString)
    }

    /// Opens the Login Items & Extensions pane.
    func openLoginItems() {
        let urlString = "\(Self.baseScheme):com.apple.LoginItems-Settings.extension"
        openURL(urlString)
    }

    /// Opens the Notifications settings.
    func openNotifications() {
        let urlString = "\(Self.baseScheme):com.apple.preference.notifications"
        openURL(urlString)
    }

    // MARK: - Private

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("[SystemSettingsService] Invalid URL: \(urlString)")
            return
        }
        NSWorkspace.shared.open(url)
    }
}
