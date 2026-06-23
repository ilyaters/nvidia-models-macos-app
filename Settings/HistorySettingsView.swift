import SwiftUI
import SwiftData
import AppKit

/// History management: auto-save, retention, export, clear.
struct HistorySettingsView: View {
    @AppStorage("autoSaveHistory") private var autoSave: Bool = true
    @AppStorage("maxHistoryDays") private var maxDays: Int = 90
    @Environment(\.modelContext) private var modelContext

    @State private var exportMessage: String?

    var body: some View {
        Form {
            Section {
                Toggle("Automatically save conversations", isOn: $autoSave)
            } header: {
                Label("Auto-save", systemImage: "tray.full")
            }

            Section {
                Stepper("Keep history for \(maxDays) days", value: $maxDays, in: 7...365, step: 7)
            } header: {
                Label("Retention", systemImage: "calendar")
            }

            Section {
                Button {
                    exportMarkdown()
                } label: {
                    Label("Export as Markdown", systemImage: "doc.richtext")
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
                    clearHistory()
                } label: {
                    Label("Clear all history", systemImage: "trash")
                }
            } header: {
                Label("Danger Zone", systemImage: "exclamationmark.triangle")
            }

            if let message = exportMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func exportMarkdown() {
        let descriptor = FetchDescriptor<Conversation>(sortBy: [SortDescriptor(\.updatedAt)])
        guard let conversations = try? modelContext.fetch(descriptor) else { return }

        var markdown = ""
        for conv in conversations {
            markdown += "# \(conv.title)\n\n"
            markdown += "Created: \(conv.createdAt.shortFormatted)\n\n"
            for msg in conv.messages {
                markdown += "**\(msg.role.rawValue.capitalized):** \(msg.content)\n\n"
            }
            markdown += "---\n\n"
        }

        saveToFile(markdown, filename: "conversations.md")
        exportMessage = "Exported \(conversations.count) conversations to Markdown"
    }

    private func exportJSON() {
        let descriptor = FetchDescriptor<Conversation>(sortBy: [SortDescriptor(\.updatedAt)])
        guard let conversations = try? modelContext.fetch(descriptor) else { return }

        var data: [[String: Any]] = []
        for conv in conversations {
            var convDict: [String: Any] = [
                "title": conv.title,
                "created": ISO8601DateFormatter().string(from: conv.createdAt),
                "model": conv.modelId
            ]
            if let sp = conv.systemPrompt { convDict["systemPrompt"] = sp }
            data.append(convDict)
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            saveToFile(jsonString, filename: "conversations.json")
            exportMessage = "Exported \(conversations.count) conversations to JSON"
        }
    }

    private func clearHistory() {
        let descriptor = FetchDescriptor<Conversation>()
        if let conversations = try? modelContext.fetch(descriptor) {
            for conv in conversations {
                modelContext.delete(conv)
            }
            try? modelContext.save()
            exportMessage = "All history cleared"
        }
    }

    private func saveToFile(_ content: String, filename: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = filename
        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
