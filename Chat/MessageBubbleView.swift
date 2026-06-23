import SwiftUI
import MarkdownUI

/// Renders a single chat message bubble with Liquid Glass styling.
///
/// Includes a context menu (right-click) with actions: copy message, copy
/// request/response, resend, edit, and copy entire chat.
struct MessageBubbleView: View {
    let message: Message
    let isStreaming: Bool

    var onResend: ((Message) -> Void)?
    var onEdit: ((Message, String) -> Void)?
    var onCopyChat: (() -> Void)?

    @State private var showEditSheet = false
    @State private var editText = ""

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                // Role label with hierarchical SF Symbol
                HStack(spacing: 4) {
                    Image(systemName: message.role == .user ? "person.fill" : "cpu")
                        .font(.system(size: 10))
                        .symbolRenderingMode(.hierarchical)
                    Text(message.role == .user ? "You" : "Assistant")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)

                // Message content
                if message.role == .assistant && isStreaming && message.content.isEmpty {
                    StreamingTextView(text: "", isStreaming: true)
                        .padding(12)
                        .glassBackground(cornerRadius: 14)
                } else if message.role == .assistant {
                    StreamingTextView(text: message.content, isStreaming: isStreaming)
                        .padding(12)
                        .glassBackground(cornerRadius: 14)
                        .textSelection(.enabled)
                } else {
                    // User messages — render markdown too.
                    Markdown(message.content)
                        .markdownTheme(.basic)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.userBubble)
                        )
                        .textSelection(.enabled)
                }

                // Usage badge for assistant messages with metrics
                if message.role == .assistant && (message.totalTokens > 0 || message.responseTimeMs > 0) {
                    UsageBadgeView(message: message)
                }

                // Timestamp
                Text(message.timestamp.shortFormatted)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal)
        .contextMenu {
            // Copy message content
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.content, forType: .string)
            } label: {
                Label("Copy Message", systemImage: "doc.on.doc")
            }

            // Copy as request (user) or response (assistant)
            if message.role == .user {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message.content, forType: .string)
                } label: {
                    Label("Copy Request", systemImage: "arrow.up.doc")
                }
            } else {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message.content, forType: .string)
                } label: {
                    Label("Copy Response", systemImage: "arrow.down.doc")
                }
            }

            Divider()

            // Resend (only for user messages)
            if message.role == .user {
                Button {
                    onResend?(message)
                } label: {
                    Label("Resend", systemImage: "arrow.clockwise")
                }
                .disabled(isStreaming)

                Button {
                    editText = message.content
                    showEditSheet = true
                } label: {
                    Label("Edit & Resend", systemImage: "pencil")
                }
                .disabled(isStreaming)
            }

            // Copy entire chat
            Button {
                onCopyChat?()
            } label: {
                Label("Copy Chat", systemImage: "doc.on.doc.fill")
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditMessageSheet(
                text: $editText,
                onSave: {
                    showEditSheet = false
                    onEdit?(message, editText)
                },
                onCancel: {
                    showEditSheet = false
                }
            )
        }
    }
}

/// Sheet for editing a user message before resending.
private struct EditMessageSheet: View {
    @Binding var text: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Message")
                .font(.headline)

            TextEditor(text: $text)
                .font(.body)
                .frame(minHeight: 100, maxHeight: 200)
                .padding(4)
                .glassBackground(cornerRadius: 8)

            HStack {
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Send", action: onSave)
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
