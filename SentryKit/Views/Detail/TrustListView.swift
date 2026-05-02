// TrustListView.swift
// SentryKit
//
// Manages the trust list for known safe/suspicious applications.

import SwiftUI

struct TrustListView: View {

    @ObservedObject var trustList: TrustListStore
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var filterLevel: TrustLevel?

    private var filteredEntries: [TrustEntry] {
        var entries = trustList.entries

        if let level = filterLevel {
            entries = entries.filter { $0.trustLevel == level }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            entries = entries.filter {
                $0.bundleID.lowercased().contains(query) ||
                ($0.developerName?.lowercased().contains(query) ?? false)
            }
        }

        return entries.sorted { $0.bundleID < $1.bundleID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Trust List")
                        .font(.title.bold())
                    Text("Manage trusted and suspicious applications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Picker("Filter", selection: $filterLevel) {
                    Text("All Levels").tag(nil as TrustLevel?)
                    Divider()
                    ForEach(TrustLevel.allCases, id: \.self) { level in
                        Label(level.rawValue, systemImage: level.symbolName)
                            .tag(level as TrustLevel?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)

                Button {
                    showAddSheet = true
                } label: {
                    Label("Add App", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search trust list…", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // List
            if filteredEntries.isEmpty {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No Trust Entries",
                        systemImage: "checkmark.shield",
                        description: Text("Add applications to your trust list to get visual indicators in the dashboard.")
                    )
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Trust Entries")
                            .font(.title3.bold())
                        Text("Add applications to your trust list to get visual indicators in the dashboard.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        TrustEntryRowView(entry: entry) { newLevel in
                            trustList.setTrustLevel(newLevel, for: entry.bundleID)
                        } onDelete: {
                            trustList.remove(bundleID: entry.bundleID)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTrustEntrySheet(trustList: trustList, viewModel: viewModel, isPresented: $showAddSheet)
        }
    }
}

// MARK: - Trust Entry Row

struct TrustEntryRowView: View {
    let entry: TrustEntry
    let onChangeTrust: (TrustLevel) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.trustLevel.symbolName)
                .foregroundColor(trustColor)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.bundleID.components(separatedBy: ".").last?.capitalized ?? entry.bundleID)
                        .font(.headline)
                    if !entry.isUserDefined {
                        Text("Built-in")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.2), in: Capsule())
                            .foregroundColor(.blue)
                    }
                }
                Text(entry.bundleID)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let dev = entry.developerName {
                    Text("Developer: \(dev)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Trust level picker
            Picker("Trust", selection: Binding(
                get: { entry.trustLevel },
                set: { onChangeTrust($0) }
            )) {
                ForEach(TrustLevel.allCases, id: \.self) { level in
                    Label(level.rawValue, systemImage: level.symbolName)
                        .tag(level)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 130)

            if entry.isUserDefined {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    private var trustColor: Color {
        switch entry.trustLevel {
        case .trusted:    return .green
        case .neutral:    return .gray
        case .suspicious: return .orange
        case .blocked:    return .red
        }
    }
}

// MARK: - Add Trust Entry Sheet

struct AddTrustEntrySheet: View {
    @ObservedObject var trustList: TrustListStore
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var isPresented: Bool

    @State private var bundleID: String = ""
    @State private var developerName: String = ""
    @State private var trustLevel: TrustLevel = .trusted
    @State private var notes: String = ""
    @State private var selectedExistingApp: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Add to Trust List")
                .font(.title2.bold())

            Form {
                // Quick select from known apps
                Section("Select from installed apps") {
                    Picker("App", selection: $selectedExistingApp) {
                        Text("— Select —").tag(nil as String?)
                        ForEach(viewModel.appSummaries, id: \.id) { app in
                            Text("\(app.displayName) (\(app.bundleID))")
                                .tag(app.id as String?)
                        }
                    }
                    .onChange(of: selectedExistingApp) { newValue in
                        if let id = newValue {
                            bundleID = id
                        }
                    }
                }

                Section("Or enter manually") {
                    TextField("Bundle ID", text: $bundleID)
                        .textFieldStyle(.roundedBorder)
                    TextField("Developer Name (optional)", text: $developerName)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Trust Level") {
                    Picker("Level", selection: $trustLevel) {
                        ForEach(TrustLevel.allCases, id: \.self) { level in
                            Label(level.rawValue, systemImage: level.symbolName)
                                .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 60)
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Add") {
                    let entry = TrustEntry.create(
                        bundleID: bundleID,
                        developerName: developerName.isEmpty ? nil : developerName,
                        trustLevel: trustLevel,
                        notes: notes.isEmpty ? nil : notes
                    )
                    trustList.addOrUpdate(entry)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(bundleID.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 500)
    }
}
