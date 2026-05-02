// Formatters.swift
// SentryKit
//
// Shared formatters and utility extensions.

import Foundation
import SwiftUI

// MARK: - Date Formatting

extension Date {
    /// Returns a relative time string like "2 hours ago".
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns a full date-time string.
    var fullString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: self)
    }

    /// Returns a short date string.
    var shortString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions

extension String {
    /// Extracts the app name from a bundle identifier.
    var appNameFromBundleID: String {
        components(separatedBy: ".").last?.capitalized ?? self
    }

    /// Extracts the domain from a bundle identifier (e.g., "com.apple" -> "apple").
    var domainFromBundleID: String {
        let parts = components(separatedBy: ".")
        guard parts.count >= 2 else { return self }
        return parts[1]
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates a Color from a named color string.
    static func fromName(_ name: String) -> Color {
        switch name.lowercased() {
        case "red":    return .red
        case "green":  return .green
        case "blue":   return .blue
        case "orange": return .orange
        case "yellow": return .yellow
        case "purple": return .purple
        case "gray", "grey": return .gray
        default:       return .primary
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a conditional modifier.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Number Formatting

extension Int {
    /// Returns a formatted string with thousands separators.
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
