import SwiftUI
import SwiftData
import AppKit

/// Main chat window with sidebar + message thread + input.
///
/// Optimized for smooth performance: debounced context estimation,
/// cached sorted messages, and minimal re-renders.
struct MainChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ChatViewModel.shared

    var body: some View {
        NavigationSplitView {
            ChatSidebar(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            VStack(spacing: 0) {
                if let conversation = viewModel.currentConversation {
                    // Header
                    ChatHeaderBar(
                        title: conversation.title,
                        hasMessages: !conversation.messages.isEmpty,
                        isStreaming: viewModel.isStreaming
                    ) {
                        Task { await viewModel.regenerateLastMessage(modelContext: modelContext) }
                    }

                    // Message thread — uses @Query for efficient fetching
                    MessageThreadView(
                        messages: conversation.messages.sorted { $0.timestamp < $1.timestamp },
                        isStreaming: viewModel.isStreaming,
                        onResend: { message in
                            Task { await viewModel.resend(from: message, modelContext: modelContext) }
                        },
                        onEdit: { message, newContent in
                            Task { await viewModel.editMessage(message, newContent: newContent, modelContext: modelContext) }
                        },
                        onCopyChat: {
                            let chatText = viewModel.copyConversation()
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(chatText, forType: .string)
                        }
                    )

                    Divider()

                    // Input
                    ChatInputView(viewModel: viewModel)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.tertiary)
                        Text("No conversation selected")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Button("New Conversation") {
                            viewModel.createNewConversation(modelContext: modelContext)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
        // Debounce context estimation — only update after user stops typing
        .onChange(of: viewModel.inputText) {
            viewModel.scheduleContextEstimation()
        }
        // Handle Cmd+N new chat request
        .onReceive(NotificationCenter.default.publisher(for: .newChatRequested)) { _ in
            viewModel.createNewConversation(modelContext: modelContext)
        }
    }
}

/// Header bar with title and regenerate button.
/// Extracted to minimize re-renders of the main view body.
private struct ChatHeaderBar: View {
    let title: String
    let hasMessages: Bool
    let isStreaming: Bool
    let onRegenerate: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            if hasMessages {
                Button(action: onRegenerate) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(isStreaming)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
