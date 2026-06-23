import SwiftUI
import SwiftData
import AppKit

/// Metrics retention, export, and clear settings.
struct MetricsSettingsView: View {
    @AppStorage("metricsRetentionDays") private var retentionDays: Int = 365
    @Environment(\.modelContext) private var modelContext
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section {
                Stepper("Keep metrics for \(retentionDays) days", value: $retentionDays, in: 30...3650, step: 30)
                Text("Usage records older than this are automatically deleted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Retention", systemImage: "calendar")
            }

            Section {
                Button {
                    exportCSV()
                } label: {
                    Label("Export as CSV", systemImage: "tablecells")
                }
                Button {
                    exportJSON()
                } label: {
                    Label("Export as JSON", systemImage: "curlybraces")
                }
            } header: {
                Label("Export", systemImage: "square.and.arrow.up")
            }

            Section {
                Button(role: .destructive) {
                    clearMetrics()
                } label: {
                    Label("Clear all metrics", systemImage: "trash")
                }
            } header: {
                Label("Danger Zone", systemImage: "exclamationmark.triangle")
            }

            if let message = statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func exportCSV() {
        let store = MetricsStore(modelContext: modelContext)
        let csv = store.exportCSV()
        saveToFile(csv, filename: "metrics.csv")
        statusMessage = "Metrics exported to CSV"
    }

    private func exportJSON() {
        let store = MetricsStore(modelContext: modelContext)
        let daily = store.dailyUsage(since: .distantPast)
        let breakdown = store.modelBreakdown(since: .distantPast)

        let data: [String: Any] = [
            "daily": daily.map { d in
                [
                    "date": ISO8601DateFormatter().string(from: d.date),
                    "promptTokens": d.promptTokens,
                    "completionTokens": d.completionTokens,
                    "totalTokens": d.totalTokens
                ]
            },
            "byModel": breakdown.map { b in
                [
                    "modelId": b.modelId,
                    "requests": b.requestCount,
                    "totalTokens": b.totalTokens,
                    "avgResponseMs": b.averageResponseTimeMs
                ]
            }
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            saveToFile(jsonString, filename: "metrics.json")
            statusMessage = "Metrics exported to JSON"
        }
    }

    private func clearMetrics() {
        let store = MetricsStore(modelContext: modelContext)
        store.clearAll()
        statusMessage = "All metrics cleared"
    }

    private func saveToFile(_ content: String, filename: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = filename
        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
