// MainContentView.swift
// SentryKit
//
// Root content view with sidebar navigation and main dashboard.

import SwiftUI

struct MainContentView: View {

    @EnvironmentObject var auditLog: AuditLogStore
    @EnvironmentObject var trustList: TrustListStore
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var settings: AppSettings

    @StateObject private var viewModel: DashboardViewModel = {
        // Temporary init — will be replaced in onAppear
        DashboardViewModel(
            auditLog: AuditLogStore(),
            trustList: TrustListStore(),
            notificationService: NotificationService()
        )
    }()

    @State private var selectedSidebarItem: SidebarItem? = .dashboard
    @State private var showOnboarding = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSidebarItem, viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .searchable(text: $viewModel.searchText, prompt: "Search apps or services…")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarItems
            }
        }
        .onAppear {
            // Re-inject the real environment objects
            let vm = DashboardViewModel(
                auditLog: auditLog,
                trustList: trustList,
                notificationService: notificationService
            )
            // We can't reassign @StateObject, so we use a workaround
            // by loading data into the existing viewModel
            Task {
                await viewModel.loadPermissions()
            }

            if !settings.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .frame(width: 600, height: 500)
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshPermissions)) { _ in
            Task { await viewModel.loadPermissions() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportCSV)) { _ in
            viewModel.exportCSV()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportAuditLog)) { _ in
            viewModel.exportAuditLog()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportReport)) { _ in
            viewModel.exportTextReport()
        }
    }

    // MARK: - Detail View Router

    @ViewBuilder
    private var detailView: some View {
        switch selectedSidebarItem {
        case .dashboard:
            DashboardOverviewView(viewModel: viewModel)
        case .service(let service):
            ServiceDetailView(service: service, viewModel: viewModel)
        case .apps:
            AppListView(viewModel: viewModel)
        case .auditLog:
            AuditLogView(auditLog: auditLog)
        case .trustList:
            TrustListView(trustList: trustList, viewModel: viewModel)
        case .none:
            DashboardOverviewView(viewModel: viewModel)
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarItems: some View {
        Button {
            Task { await viewModel.loadPermissions() }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        .help("Refresh all permissions (⌘R)")

        if !viewModel.hasFullDiskAccess {
            Button {
                viewModel.openFullDiskAccessSettings()
            } label: {
                Label("Grant Access", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
            .help("Full Disk Access required")
        }

        Menu {
            Button("Export Permissions (CSV)…") {
                viewModel.exportCSV()
            }
            Button("Export Audit Log (CSV)…") {
                viewModel.exportAuditLog()
            }
            Button("Export Security Report (TXT)…") {
                viewModel.exportTextReport()
            }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .help("Export data")
    }
}

// MARK: - Sidebar Item

enum SidebarItem: Hashable {
    case dashboard
    case service(TCCService)
    case apps
    case auditLog
    case trustList
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        List(selection: $selection) {
            // Overview
            Section {
                Label("Dashboard", systemImage: "square.grid.2x2")
                    .tag(SidebarItem.dashboard)

                Label("All Apps", systemImage: "app.badge")
                    .tag(SidebarItem.apps)
            }

            // Service Categories
            ForEach(ServiceCategory.allCases) { category in
                Section(category.rawValue) {
                    ForEach(category.services) { service in
                        HStack {
                            Label(service.displayName, systemImage: service.symbolName)
                            Spacer()
                            if let summary = viewModel.serviceSummaries.first(where: { $0.service == service }) {
                                Text("\(summary.allowedApps.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(.quaternary))
                            }
                        }
                        .tag(SidebarItem.service(service))
                    }
                }
            }

            // Tools
            Section("Tools") {
                Label("Audit Log", systemImage: "clock.arrow.circlepath")
                    .tag(SidebarItem.auditLog)

                Label("Trust List", systemImage: "checkmark.shield")
                    .tag(SidebarItem.trustList)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("SentryKit")
    }
}
