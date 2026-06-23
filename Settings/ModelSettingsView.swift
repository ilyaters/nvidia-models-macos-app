import SwiftUI

/// Default model and sampling parameter settings.
struct ModelSettingsView: View {
    @AppStorage("defaultModelId") private var defaultModelId: String = "nvidia/llama-3.1-nemotron-70b-instruct"
    @AppStorage("defaultSystemPrompt") private var defaultSystemPrompt: String = ""
    @AppStorage("defaultTemperature") private var defaultTemperature: Double = 0.7
    @AppStorage("defaultTopP") private var defaultTopP: Double = 0.95
    @AppStorage("defaultMaxTokens") private var defaultMaxTokens: Int = 1024

    var body: some View {
        Form {
            Section {
                TextField("Model ID", text: $defaultModelId)
                    .textFieldStyle(.roundedBorder)
                Text("Selected by default for new conversations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Default Model", systemImage: "cpu")
            }

            Section {
                TextEditor(text: $defaultSystemPrompt)
                    .font(.system(size: 12))
                    .frame(height: 80)
                Text("Applied to new conversations. Can be overridden per-chat.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("System Prompt", systemImage: "text.bubble")
            }

            Section {
                GlassSliderStyle(value: $defaultTemperature, in: 0...2) {
                    Text("Temperature")
                }
                GlassSliderStyle(value: $defaultTopP, in: 0...1) {
                    Text("Top P")
                }
                HStack {
                    Text("Max Tokens")
                    Spacer()
                    Stepper(value: $defaultMaxTokens, in: 1...32768, step: 128) {
                        Text("\(defaultMaxTokens)")
                            .font(.system(.body, design: .monospaced))
                    }
                }
            } header: {
                Label("Sampling Parameters", systemImage: "slider.horizontal.3")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
