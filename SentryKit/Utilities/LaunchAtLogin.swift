// LaunchAtLogin.swift
// SentryKit
//
// Manages Launch at Login using the ServiceManagement framework.

import Foundation
import ServiceManagement

/// Utility for managing launch-at-login behavior.
enum LaunchAtLogin {

    /// Registers the app to launch at login.
    @available(macOS 13.0, *)
    static func enable() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("[LaunchAtLogin] Failed to enable: \(error)")
        }
    }

    /// Unregisters the app from launching at login.
    @available(macOS 13.0, *)
    static func disable() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("[LaunchAtLogin] Failed to disable: \(error)")
        }
    }

    /// Checks if the app is registered to launch at login.
    @available(macOS 13.0, *)
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
