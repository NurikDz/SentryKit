// AppListView.swift
// SentryKit
//
// Shows all applications and their permission summaries.

import SwiftUI

struct AppListView: View {

    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedApp: AppPermissionSummary?
    @State private var sortOrder: AppSortOrder = .name

    enum AppSortOrder: String, CaseIterable {
        case name = "Name"
        case permissions = "Most Permissions"
        case risk = "Highest Risk"
        case recent = "Recently Changed"
    }

    private var sortedApps: [AppPermissionSummary] {
        let apps = viewModel.filteredAppSummaries
        switch sortOrder {
        case .name:
            return apps.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        case .permissions:
            return apps.sorted { $0.allowedCount > $1.allowedCount }
        case .risk:
            return apps.sorted { $0.highestRisk > $1.highestRisk }
        case .recent:
            return apps.sorted { $0.lastModified > $1.lastModified }
        }
    }

    var body: some View {
        HSplitView {
            // App List
            VStack(alignment: .leading, spacing: 0) {
                // Sort controls
                HStack {
                    Text("Applications (\(sortedApps.count))")
                        .font(.headline)
                    Spacer()
                    Picker("Sort", selection: $sortOrder) {
                        ForEach(AppSortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
                .padding()

                Divider()

                List(sortedApps, selection: $selectedApp) { app in
                    AppRowView(app: app, trustLevel: viewModel.trustList.trustLevel(for: app.bundleID))
                        .tag(app)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
            .frame(minWidth: 350)

            // Detail
            if let app = selectedApp {
                AppDetailView(app: app, viewModel: viewModel)
            } else {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "Select an App",
                        systemImage: "app",
                        description: Text("Select an application from the list to view its permissions.")
                    )
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "app")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Select an App")
                            .font(.title3.bold())
                        Text("Select an application from the list to view its permissions.")
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
}

// MARK: - App Row

struct AppRowView: View {
    let app: AppPermissionSummary
    let trustLevel: TrustLevel

    var body: some View {
        HStack(spacing: 12) {
            // App icon placeholder
            Image(systemName: "app.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(app.displayName)
                        .font(.headline)
                    if trustLevel != .neutral {
                        Image(systemName: trustLevel.symbolName)
                            .font(.caption)
                            .foregroundColor(trustColor)
                    }
                }
                Text(app.bundleID)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Permission counts
            HStack(spacing: 8) {
                if app.allowedCount > 0 {
                    HStack(spacing: 2) {
                        Circle().fill(.green).frame(width: 8, height: 8)
                        Text("\(app.allowedCount)")
                            .font(.caption.monospacedDigit())
                    }
                }
                if app.deniedCount > 0 {
                    HStack(spacing: 2) {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text("\(app.deniedCount)")
                            .font(.caption.monospacedDigit())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var trustColor: Color {
        switch trustLevel {
        case .trusted:    return .green
        case .neutral:    return .gray
        case .suspicious: return .orange
        case .blocked:    return .red
        }
    }
}

// MARK: - App Detail View

struct AppDetailView: View {

    let app: AppPermissionSummary
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showResetConfirmation = false
    @State private var resetService: TCCService?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // App Header
                HStack(spacing: 16) {
                    Image(systemName: "app.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.displayName)
                            .font(.title.bold())
                        Text(app.bundleID)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                }

                // Stats
                HStack(spacing: 16) {
                    StatCard(title: "Allowed", value: "\(app.allowedCount)", icon: "checkmark.circle.fill", color: .green)
                    StatCard(title: "Denied", value: "\(app.deniedCount)", icon: "xmark.circle.fill", color: .red)
                    StatCard(title: "Total", value: "\(app.totalCount)", icon: "list.bullet", color: .blue)
                }

                Divider()

                // Permissions List
                Text("Permissions")
                    .font(.headline)

                ForEach(app.permissions, id: \.id) { permission in
                    HStack(spacing: 12) {
                        Image(systemName: permission.authValue.symbolName)
                            .foregroundColor(statusColor(permission.authValue))
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(permission.serviceDisplayName)
                                .font(.body.bold())
                            HStack {
                                Text(permission.authValue.description)
                                    .font(.caption)
                                    .foregroundColor(statusColor(permission.authValue))
                                if let reason = permission.authReason {
                                    Text("— \(reason.description)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Text("Modified: \(permission.lastModifiedFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Actions
                        if let service = permission.resolvedService {
                            HStack(spacing: 6) {
                                Button {
                                    viewModel.openSettings(for: service)
                                } label: {
                                    Image(systemName: "gear")
                                }
                                .buttonStyle(.borderless)
                                .help("Open in System Settings")

                                Button(role: .destructive) {
                                    resetService = service
                                    showResetConfirmation = true
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                }
                                .buttonStyle(.borderless)
                                .help("Reset this permission")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
                }

                // Risk explanation
                if let service = app.permissions.first(where: { $0.authValue == .allowed && $0.resolvedService?.riskLevel == .high })?.resolvedService {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("High-Risk Permission Active", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("\(app.displayName) has \(service.displayName) access, which is classified as high-risk. \(service.explanation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
        .alert("Reset Permission?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                if let service = resetService {
                    Task {
                        _ = await viewModel.resetPermission(service: service, bundleID: app.bundleID)
                    }
                }
            }
        } message: {
            if let service = resetService {
                Text("Reset \(service.displayName) for \(app.displayName)? The app will need to re-request this permission.")
            }
        }
    }

    private func statusColor(_ value: AuthValue) -> Color {
        switch value {
        case .allowed: return .green
        case .denied:  return .red
        case .unknown: return .yellow
        case .limited: return .orange
        }
    }
}
