import SwiftUI

/// About tab with version info and links.
/// Uses hierarchical SF Symbols and NVIDIA brand color.
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cpu")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.nvidiaGreen)

            Text("NVIDIA LLM Client")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Native macOS client for NVIDIA LLM models")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .frame(width: 200)

            VStack(spacing: 8) {
                Link(destination: URL(string: "https://build.nvidia.com")!) {
                    Label("NVIDIA Build Portal", systemImage: "globe")
                        .symbolRenderingMode(.hierarchical)
                }
                Link(destination: URL(string: "https://docs.api.nvidia.com")!) {
                    Label("API Documentation", systemImage: "book")
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
