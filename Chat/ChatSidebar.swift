import SwiftUI
import SwiftData

/// Sidebar listing all conversations with search, rename, and delete.
struct ChatSidebar: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var renamingId: UUID?
    @State private var renameText = ""

    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return viewModel.conversations
        }
        return viewModel.conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // New conversation button
            Button {
                viewModel.createNewConversation(modelContext: modelContext)
            } label: {
                Label("New Conversation", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(8)

            // Search
            TextField("Search…", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

            // Conversation list
            List(selection: Binding(
                get: { viewModel.currentConversation?.id },
                set: { id in
                    viewModel.currentConversation = viewModel.conversations.first { $0.id == id }
                    viewModel.syncSettingsFromCurrentConversation()
                }
            )) {
                ForEach(filteredConversations) { conversation in
                    ConversationRow(
                        conversation: conversation,
                        isRenaming: renamingId == conversation.id,
                        renameText: $renameText,
                        onSelect: {
                            viewModel.currentConversation = conversation
                            viewModel.syncSettingsFromCurrentConversation()
                        },
                        onStartRename: {
                            renamingId = conversation.id
                            renameText = conversation.title
                        },
                        onCommitRename: {
                            viewModel.renameConversation(conversation, to: renameText, modelContext: modelContext)
                            renamingId = nil
                        },
                        onDelete: {
                            viewModel.deleteConversation(conversation, modelContext: modelContext)
                        }
                    )
                    .tag(conversation.id)
                }
            }
        }
        .navigationTitle("Conversations")
    }
}

private struct ConversationRow: View {
    let conversation: Conversation
    let isRenaming: Bool
    @Binding var renameText: String
    let onSelect: () -> Void
    let onStartRename: () -> Void
    let onCommitRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isRenaming {
                TextField("Title", text: $renameText, onCommit: onCommitRename)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text(conversation.title)
                    .font(.body)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                Text(conversation.updatedAt.relativeTime)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if !conversation.messages.isEmpty {
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text("\(conversation.messages.count) msgs")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .contextMenu {
            Button("Rename", action: onStartRename)
            Button("Delete", role: .destructive, action: onDelete)
        }
        .onTapGesture(perform: onSelect)
    }
}
