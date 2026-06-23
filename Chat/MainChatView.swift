import SwiftUI
import SwiftData
import AppKit

/// Main chat window with sidebar + message thread + input.
struct MainChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ChatViewModel.shared

    var body: some View {
        NavigationSplitView {
            ChatSidebar(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
                .glassBackground(cornerRadius: 0)
        } detail: {
            VStack(spacing: 0) {
                if let conversation = viewModel.currentConversation {
                    // Header
                    HStack {
                        Text(conversation.title)
                            .font(.headline)
                            .lineLimit(1)
                        Spacer()
                        if !conversation.messages.isEmpty {
                            Button {
                                Task { await viewModel.regenerateLastMessage(modelContext: modelContext) }
                            } label: {
                                Label("Regenerate", systemImage: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .disabled(viewModel.isStreaming)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .glassBackground(cornerRadius: 0)

                    // Message thread (sorted by timestamp for correct order)
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
        .onChange(of: viewModel.inputText) {
            viewModel.updateContextEstimation()
        }
    }
}
