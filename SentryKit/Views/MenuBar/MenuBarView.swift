// MenuBarView.swift
// SentryKit
//
// Menu bar extra view showing quick status and actions.

import SwiftUI

struct MenuBarView: View {

    @EnvironmentObject var auditLog: AuditLogStore
    @EnvironmentObject var trustList: TrustListStore
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var settings: AppSettings

    @StateObject private var viewModel = DashboardViewModel(
        auditLog: AuditLogStore(),
        trustList: TrustListStore(),
        notificationService: NotificationService()
    )

    @State private var isLoaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.accentColor)
                Text("SentryKit")
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Quick Stats
            if isLoaded {
                quickStats
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()

                // Recent Activity
                recentActivity
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()
            }

            // Quick Actions
            quickActions
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            // Footer
            HStack {
                Button("Open SentryKit") {
                    openMainWindow()
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
        .task {
            await viewModel.loadPermissions()
            isLoaded = true
        }
    }

    // MARK: - Quick Stats

    private var quickStats: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Permission Overview")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                miniStat(value: viewModel.totalApps, label: "Apps", color: .blue)
                miniStat(value: viewModel.totalAllowed, label: "Allowed", color: .green)
                miniStat(value: viewModel.totalDenied, label: "Denied", color: .red)
                miniStat(value: viewModel.highRiskCount, label: "High Risk", color: .orange)
            }

            if !viewModel.hasFullDiskAccess {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Full Disk Access required")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    private func miniStat(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(.body, design: .rounded).bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent Activity")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            if auditLog.entries.isEmpty {
                Text("No recent activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(auditLog.recentEntries(count: 3)) { entry in
                    HStack(spacing: 6) {
                        Image(systemName: entry.eventType.symbolName)
                            .font(.caption)
                            .foregroundColor(eventColor(entry.eventType))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(entry.clientDisplayName) — \(entry.serviceDisplayName)")
                                .font(.caption)
                                .lineLimit(1)
                            Text(entry.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Quick Actions")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            Button {
                Task { await viewModel.loadPermissions() }
            } label: {
                Label("Refresh Permissions", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)

            Button {
                SystemSettingsService().openPrivacySecurity()
            } label: {
                Label("Open Privacy Settings", systemImage: "gear")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)

            Button {
                SystemSettingsService().openFullDiskAccess()
            } label: {
                Label("Full Disk Access", systemImage: "internaldrive")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Helpers

    private func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        for window in NSApplication.shared.windows {
            if window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }

    private func eventColor(_ type: AuditEventType) -> Color {
        switch type {
        case .permissionGranted:  return .green
        case .permissionDenied:   return .red
        case .permissionChanged:  return .orange
        case .permissionRemoved:  return .red
        case .permissionAdded:    return .blue
        case .resetPerformed:     return .purple
        case .scanCompleted:      return .gray
        case .appDetected:        return .blue
        }
    }
}
