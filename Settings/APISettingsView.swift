import SwiftUI

/// API key and endpoint settings.
struct APISettingsView: View {
    @State private var apiKey: String = ""
    @State private var showKey: Bool = false
    @State private var saved: Bool = false
    @AppStorage("apiEndpoint") private var apiEndpoint: String = "https://integrate.api.nvidia.com/v1"

    var body: some View {
        Form {
            Section {
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
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.borderless)
                    .help(showKey ? "Hide key" : "Show key")
                }

                HStack {
                    Button {
                        KeychainManager.save(apiKey, for: "nvidia_api_key")
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                    } label: {
                        Label("Save to Keychain", systemImage: "lock.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)

                    if saved {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }

                    Spacer()

                    Button {
                        apiKey = KeychainManager.load("nvidia_api_key") ?? ""
                    } label: {
                        Label("Load", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        KeychainManager.delete("nvidia_api_key")
                        apiKey = ""
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Label("NVIDIA API Key", systemImage: "key.fill")
            }

            Section {
                TextField("API Endpoint", text: $apiEndpoint)
                    .textFieldStyle(.roundedBorder)
                Text("Default: https://integrate.api.nvidia.com/v1")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Endpoint", systemImage: "network")
            }

            Section {
                Link(destination: URL(string: "https://build.nvidia.com")!) {
                    Label("Get API Key →", systemImage: "arrow.up.right.square")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            apiKey = KeychainManager.load("nvidia_api_key") ?? ""
        }
    }
}
