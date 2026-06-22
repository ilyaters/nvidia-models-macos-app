import SwiftUI

/// Google Custom Search configuration.
struct SearchSettingsView: View {
    @State private var searchApiKey: String = ""
    @State private var searchEngineId: String = ""
    @AppStorage("googleSearchEnabled") private var searchEnabled: Bool = false
    @AppStorage("googleSearchMaxResults") private var maxResults: Int = 5

    var body: some View {
        Form {
            Section("Google Custom Search") {
                Toggle("Enable web search (research mode)", isOn: $searchEnabled)

                SecureField("API Key", text: $searchApiKey)
                    .textFieldStyle(.roundedBorder)

                TextField("Search Engine ID (CX)", text: $searchEngineId)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save Credentials") {
                        KeychainManager.save(searchApiKey, for: "google_search_api_key")
                        KeychainManager.save(searchEngineId, for: "google_search_cx")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searchApiKey.isEmpty || searchEngineId.isEmpty)
                }
            }

            Section("Results") {
                Stepper("Max results: \(maxResults)", value: $maxResults, in: 1...10)
            }

            Section {
                Link("Get API Key", destination: URL(string: "https://console.cloud.google.com/apis/credentials")!)
                Link("Create Search Engine", destination: URL(string: "https://programmablesearchengine.google.com")!)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            searchApiKey = KeychainManager.load("google_search_api_key") ?? ""
            searchEngineId = KeychainManager.load("google_search_cx") ?? ""
        }
    }
}
