import SwiftUI
import AppKit

/// Error state view displayed when a request fails.
///
/// Shows the error message with a retry button, a "Dismiss" option, and a
/// context menu to copy the full error details. Uses Liquid Glass styling.
struct ErrorStateView: View {
    let message: String
    let detailedMessage: String?
    let onRetry: () -> Void
    let onDismiss: () -> Void

    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.red)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(showDetails ? nil : 3)
                    .textSelection(.enabled)

                Spacer()

                // Copy full error button
                Button {
                    let fullText = detailedMessage ?? message
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(fullText, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .help("Copy full error details")

                // Toggle details
                if detailedMessage != nil {
                    Button {
                        showDetails.toggle()
                    } label: {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.borderless)
                    .help(showDetails ? "Hide details" : "Show details")
                }

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

            // Detailed error text (collapsible)
            if showDetails, let detailedMessage {
                ScrollView {
                    Text(detailedMessage)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 150)
                .padding(8)
                .background(Color.red.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassBackground(cornerRadius: 10)
        // Context menu for right-click copy
        .contextMenu {
            Button {
                let fullText = detailedMessage ?? message
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(fullText, forType: .string)
            } label: {
                Label("Copy Full Error", systemImage: "doc.on.doc")
            }

            if detailedMessage != nil {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message, forType: .string)
                } label: {
                    Label("Copy Short Message", systemImage: "doc")
                }
            }
        }
    }
}
