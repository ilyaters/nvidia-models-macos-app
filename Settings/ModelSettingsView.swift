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
            Section("Default Model") {
                TextField("Model ID", text: $defaultModelId)
                    .textFieldStyle(.roundedBorder)
                Text("This model is selected by default for new conversations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Default System Prompt") {
                TextEditor(text: $defaultSystemPrompt)
                    .font(.system(size: 12))
                    .frame(height: 80)
                Text("Applied to new conversations. Can be overridden per-conversation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Default Parameters") {
                GlassSliderStyle(value: $defaultTemperature, in: 0...2) {
                    Text("Temperature")
                }
                GlassSliderStyle(value: $defaultTopP, in: 0...1) {
                    Text("Top P")
                }
                HStack {
                    Text("Max Tokens")
                    Stepper(value: $defaultMaxTokens, in: 1...32768, step: 128) {
                        Text("\(defaultMaxTokens)")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
