// AuditLogView.swift
// SentryKit
//
// Displays the audit log of permission changes over time.

import SwiftUI

struct AuditLogView: View {

    @ObservedObject var auditLog: AuditLogStore
    @State private var filterEventType: AuditEventType?
    @State private var searchText: String = ""
    @State private var showClearConfirmation = false

    private var filteredEntries: [AuditLogEntry] {
        var entries = auditLog.entries

        if let filter = filterEventType {
            entries = entries.filter { $0.eventType == filter }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            entries = entries.filter {
                $0.client.lowercased().contains(query) ||
                $0.clientDisplayName.lowercased().contains(query) ||
                $0.serviceDisplayName.lowercased().contains(query) ||
                $0.eventType.rawValue.lowercased().contains(query)
            }
        }

        return entries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Audit Log")
                        .font(.title.bold())
                    Text("\(auditLog.entries.count) events recorded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Filter
                Picker("Filter", selection: $filterEventType) {
                    Text("All Events").tag(nil as AuditEventType?)
                    Divider()
                    ForEach(AuditEventType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.symbolName)
                            .tag(type as AuditEventType?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)

                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Clear Log", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search audit log…", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Log entries
            if filteredEntries.isEmpty {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No Audit Entries",
                        systemImage: "clock.arrow.circlepath",
                        description: Text(auditLog.entries.isEmpty ?
                            "Permission changes will be recorded here as they happen." :
                            "No entries match the current filter.")
                    )
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Audit Entries")
                            .font(.title3.bold())
                        Text(auditLog.entries.isEmpty ?
                            "Permission changes will be recorded here as they happen." :
                            "No entries match the current filter.")
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
                        AuditLogRowView(entry: entry)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .alert("Clear Audit Log?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                auditLog.clearLog()
            }
        } message: {
            Text("This will permanently delete all audit log entries. This cannot be undone.")
        }
    }
}

// MARK: - Audit Log Row

struct AuditLogRowView: View {
    let entry: AuditLogEntry

    var body: some View {
        HStack(spacing: 12) {
            // Event icon
            Image(systemName: entry.eventType.symbolName)
                .foregroundColor(eventColor)
                .font(.title3)
                .frame(width: 28)

            // Event details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.eventType.rawValue)
                        .font(.headline)
                    Text("—")
                        .foregroundColor(.secondary)
                    Text(entry.serviceDisplayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Text(entry.clientDisplayName)
                        .font(.subheadline)

                    if let prev = entry.previousAuthValue, let new = entry.newAuthValue {
                        HStack(spacing: 4) {
                            Text(prev.description)
                                .foregroundColor(.red)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                            Text(new.description)
                                .foregroundColor(.green)
                        }
                        .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    Text(entry.timestampFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let details = entry.details {
                        Text(details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Source badge
            Text(entry.source.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
        .padding(.vertical, 4)
    }

    private var eventColor: Color {
        switch entry.eventType {
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
