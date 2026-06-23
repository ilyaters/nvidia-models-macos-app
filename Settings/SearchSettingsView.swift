import SwiftUI

/// Google Custom Search configuration.
struct SearchSettingsView: View {
    @State private var searchApiKey: String = ""
    @State private var searchEngineId: String = ""
    @AppStorage("googleSearchEnabled") private var searchEnabled: Bool = false
    @AppStorage("googleSearchMaxResults") private var maxResults: Int = 5

    var body: some View {
        Form {
            Section {
                Toggle("Enable web search (research mode)", isOn: $searchEnabled)

                SecureField("API Key", text: $searchApiKey)
                    .textFieldStyle(.roundedBorder)

                TextField("Search Engine ID (CX)", text: $searchEngineId)
                    .textFieldStyle(.roundedBorder)

                Button {
                    KeychainManager.save(searchApiKey, for: "google_search_api_key")
                    KeychainManager.save(searchEngineId, for: "google_search_cx")
                } label: {
                    Label("Save Credentials", systemImage: "lock.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(searchApiKey.isEmpty || searchEngineId.isEmpty)
            } header: {
                Label("Google Custom Search", systemImage: "magnifyingglass")
            }

            Section {
                Stepper("Max results: \(maxResults)", value: $maxResults, in: 1...10)
            } header: {
                Label("Results", systemImage: "list.number")
            }

            Section {
                Link(destination: URL(string: "https://console.cloud.google.com/apis/credentials")!) {
                    Label("Get API Key →", systemImage: "arrow.up.right.square")
                }
                Link(destination: URL(string: "https://programmablesearchengine.google.com")!) {
                    Label("Create Search Engine →", systemImage: "arrow.up.right.square")
                }
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
