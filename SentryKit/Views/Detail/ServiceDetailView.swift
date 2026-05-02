// ServiceDetailView.swift
// SentryKit
//
// Shows all apps and their permission status for a specific TCC service.

import SwiftUI

struct ServiceDetailView: View {

    let service: TCCService
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showResetAllConfirmation = false
    @State private var resetResult: ResetResult?
    @State private var showResetResult = false

    private var permissions: [TCCPermission] {
        viewModel.filteredPermissions.filter { $0.service == service.rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            serviceHeader
                .padding()

            Divider()

            // Permission List
            if permissions.isEmpty {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No Apps Found",
                        systemImage: service.symbolName,
                        description: Text("No applications have requested \(service.displayName) access.")
                    )
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: service.symbolName)
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Apps Found")
                            .font(.title3.bold())
                        Text("No applications have requested \(service.displayName) access.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                List {
                    ForEach(permissions, id: \.id) { permission in
                        PermissionRowView(
                            permission: permission,
                            trustLevel: viewModel.trustList.trustLevel(for: permission.client),
                            onReset: {
                                Task {
                                    resetResult = await viewModel.resetPermission(
                                        service: service,
                                        bundleID: permission.client
                                    )
                                    showResetResult = true
                                }
                            },
                            onOpenSettings: {
                                viewModel.openSettings(for: service)
                            }
                        )
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .alert("Reset All \(service.displayName)?", isPresented: $showResetAllConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset All", role: .destructive) {
                Task {
                    resetResult = await viewModel.resetServiceForAll(service: service)
                    showResetResult = true
                }
            }
        } message: {
            Text("This will reset \(service.displayName) permissions for ALL apps. Each app will need to re-request access. This cannot be undone.")
        }
        .alert("Reset Result", isPresented: $showResetResult) {
            Button("OK") {}
        } message: {
            if let result = resetResult {
                Text(result.success ? "Successfully reset \(service.displayName) permissions." : "Reset failed: \(result.error)")
            }
        }
    }

    // MARK: - Header

    private var serviceHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: service.symbolName)
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(service.displayName)
                            .font(.title.bold())
                        riskBadge
                    }
                    Text(service.explanation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(spacing: 8) {
                    Button {
                        viewModel.openSettings(for: service)
                    } label: {
                        Label("Open in Settings", systemImage: "gear")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        showResetAllConfirmation = true
                    } label: {
                        Label("Reset All", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Quick stats
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(permissions.filter { $0.authValue == .allowed }.count) Allowed")
                        .font(.subheadline)
                }
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("\(permissions.filter { $0.authValue == .denied }.count) Denied")
                        .font(.subheadline)
                }
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(permissions.filter { $0.authValue == .unknown || $0.authValue == .limited }.count) Other")
                        .font(.subheadline)
                }
            }
        }
    }

    @ViewBuilder
    private var riskBadge: some View {
        let risk = service.riskLevel
        Text(risk.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
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

// MARK: - Permission Row

struct PermissionRowView: View {

    let permission: TCCPermission
    let trustLevel: TrustLevel
    let onReset: () -> Void
    let onOpenSettings: () -> Void

    @State private var showResetConfirmation = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: permission.authValue.symbolName)
                .foregroundColor(statusColor)
                .font(.title2)

            // App info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(permission.clientDisplayName)
                        .font(.headline)
                    trustBadge
                    sourceBadge
                }
                Text(permission.client)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Text(permission.authValue.description)
                        .font(.caption.bold())
                        .foregroundColor(statusColor)
                    if let reason = permission.authReason {
                        Text("(\(reason.description))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Modified: \(permission.lastModifiedFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            if isHovered {
                HStack(spacing: 8) {
                    Button {
                        onOpenSettings()
                    } label: {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(.borderless)
                    .help("Open in System Settings")

                    Button(role: .destructive) {
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
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .alert("Reset Permission?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                onReset()
            }
        } message: {
            Text("Reset \(permission.serviceDisplayName) for \(permission.clientDisplayName)? The app will need to re-request this permission.")
        }
    }

    private var statusColor: Color {
        switch permission.authValue {
        case .allowed: return .green
        case .denied:  return .red
        case .unknown: return .yellow
        case .limited: return .orange
        }
    }

    @ViewBuilder
    private var trustBadge: some View {
        if trustLevel != .neutral {
            Image(systemName: trustLevel.symbolName)
                .font(.caption)
                .foregroundColor(trustColor)
                .help("\(trustLevel.rawValue) app")
        }
    }

    @ViewBuilder
    private var sourceBadge: some View {
        Text(permission.source.rawValue)
            .font(.caption2)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(.quaternary, in: Capsule())
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
