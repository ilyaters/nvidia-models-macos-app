import SwiftUI

/// Error state view displayed when a request fails.
///
/// Shows the error message with a retry button and a "Dismiss" option.
/// Uses Liquid Glass styling and hierarchical SF Symbols.
struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.red)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)

                Spacer()

                Button {
                    onRetry()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .help("Dismiss")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassBackground(cornerRadius: 10)
        }
    }
}
