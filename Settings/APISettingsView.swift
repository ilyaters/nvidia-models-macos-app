import SwiftUI

/// API key and endpoint settings.
struct APISettingsView: View {
    @State private var apiKey: String = ""
    @State private var showKey: Bool = false
    @State private var saved: Bool = false
    @AppStorage("apiEndpoint") private var apiEndpoint: String = "https://integrate.api.nvidia.com/v1"

    var body: some View {
        Form {
            Section("NVIDIA API") {
                HStack {
                    if showKey {
                        TextField("API Key", text: $apiKey)
                    } else {
                        SecureField("API Key", text: $apiKey)
                    }
                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                HStack {
                    Button("Save to Keychain") {
                        KeychainManager.save(apiKey, for: "nvidia_api_key")
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)

                    if saved {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                Button("Load from Keychain") {
                    apiKey = KeychainManager.load("nvidia_api_key") ?? ""
                }
                .buttonStyle(.bordered)

                Button("Delete from Keychain", role: .destructive) {
                    KeychainManager.delete("nvidia_api_key")
                    apiKey = ""
                }
            }

            Section("Endpoint") {
                TextField("API Endpoint", text: $apiEndpoint)
                    .textFieldStyle(.roundedBorder)
                Text("Default: https://integrate.api.nvidia.com/v1")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Link("Get API Key", destination: URL(string: "https://build.nvidia.com")!)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            apiKey = KeychainManager.load("nvidia_api_key") ?? ""
        }
    }
}
