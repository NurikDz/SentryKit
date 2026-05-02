// DashboardOverviewView.swift
// SentryKit
//
// Main dashboard overview showing statistics and service grid.

import SwiftUI

struct DashboardOverviewView: View {

    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                // Error Banner
                if let error = viewModel.errorMessage {
                    ErrorBannerView(message: error) {
                        viewModel.openFullDiskAccessSettings()
                    }
                }

                // Statistics Cards
                statisticsSection

                // Service Grid
                serviceGridSection

                // Recent Changes
                recentChangesSection
            }
            .padding()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Scanning TCC databases…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Permission Dashboard")
                    .font(.title.bold())
                if let date = viewModel.lastScanDate {
                    Text("Last scanned: \(date, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button {
                Task { await viewModel.loadPermissions() }
            } label: {
                Label("Scan Now", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total Apps",
                value: "\(viewModel.totalApps)",
                icon: "app.badge",
                color: .blue
            )
            StatCard(
                title: "Allowed",
                value: "\(viewModel.totalAllowed)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            StatCard(
                title: "Denied",
                value: "\(viewModel.totalDenied)",
                icon: "xmark.circle.fill",
                color: .red
            )
            StatCard(
                title: "High Risk",
                value: "\(viewModel.highRiskCount)",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            )
            StatCard(
                title: "Total Entries",
                value: "\(viewModel.totalPermissions)",
                icon: "list.bullet.rectangle",
                color: .purple
            )
        }
    }

    // MARK: - Service Grid

    private var serviceGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services Overview")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 12)
            ], spacing: 12) {
                ForEach(viewModel.serviceSummaries) { summary in
                    ServiceCardView(summary: summary) {
                        viewModel.openSettings(for: summary.service)
                    }
                }
            }

            if viewModel.serviceSummaries.isEmpty && !viewModel.isLoading {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No Permissions Found",
                        systemImage: "lock.open",
                        description: Text("No TCC permission entries were found. This may indicate Full Disk Access has not been granted.")
                    )
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "lock.open")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Permissions Found")
                            .font(.title3.bold())
                        Text("No TCC permission entries were found. This may indicate Full Disk Access has not been granted.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Recent Changes

    private var recentChangesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            if viewModel.auditLog.entries.isEmpty {
                Text("No recent activity recorded yet.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.auditLog.recentEntries(count: 5)) { entry in
                    AuditLogRowView(entry: entry)
                }
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Service Card

struct ServiceCardView: View {
    let summary: ServicePermissionSummary
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: summary.service.symbolName)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                Text(summary.service.displayName)
                    .font(.headline)
                Spacer()
                riskBadge
            }

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("\(summary.allowedApps.count)")
                        .font(.caption)
                }
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("\(summary.deniedApps.count)")
                        .font(.caption)
                }
                HStack(spacing: 4) {
                    Circle().fill(.yellow).frame(width: 8, height: 8)
                    Text("\(summary.unknownApps.count)")
                        .font(.caption)
                }
                Spacer()
            }

            // Top allowed apps
            ForEach(summary.allowedApps.prefix(3), id: \.id) { perm in
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(perm.clientDisplayName)
                        .font(.caption)
                        .lineLimit(1)
                }
            }

            HStack {
                Spacer()
                Button("Open Settings") {
                    onOpenSettings()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var riskBadge: some View {
        let risk = summary.service.riskLevel
        Text(risk.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(riskColor(risk).opacity(0.2), in: Capsule())
            .foregroundColor(riskColor(risk))
    }

    private func riskColor(_ risk: RiskLevel) -> Color {
        switch risk {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }
}

// MARK: - Error Banner

struct ErrorBannerView: View {
    let message: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Access Required")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Grant Access") {
                action()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}
