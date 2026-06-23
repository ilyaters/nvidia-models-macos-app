import SwiftUI
import SwiftData
import AppKit

/// Quick chat popover for the menu bar.
///
/// Shares the same `ChatViewModel` as the main window so messages stay in sync
/// between the bar popover and the main window.
struct PopoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    /// Shared view model — same instance as the main window.
    @State private var viewModel = ChatViewModel.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("NVIDIA LLM")
                    .font(.headline)
                Spacer()
                Button {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "macwindow")
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .help("Open main window")
            }
            .padding(8)

            Divider()

            // Messages — shows the current conversation's messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if let conversation = viewModel.currentConversation,
                           conversation.messages.isEmpty {
                            Text("Quick chat — type a message below")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 20)
                        } else if viewModel.currentConversation == nil {
                            Text("No conversation — open main window")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 20)
                        }
                        if let conversation = viewModel.currentConversation {
                            let sortedMessages = conversation.messages.sorted { $0.timestamp < $1.timestamp }
                            ForEach(sortedMessages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isStreaming: viewModel.isStreaming && message.id == sortedMessages.last?.id && message.role == .assistant
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.currentConversation?.messages.count) { _, _ in
                    if let conversation = viewModel.currentConversation,
                       let last = conversation.messages.sorted(by: { $0.timestamp < $1.timestamp }).last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .frame(minHeight: 200, maxHeight: 300)

            Divider()

            // Error
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(4)
            }

            // Input
            HStack(alignment: .bottom, spacing: 4) {
                TextField("Message…", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .onSubmit {
                        Task { await viewModel.sendMessage(modelContext: modelContext) }
                    }

                Button {
                    if viewModel.isStreaming {
                        viewModel.stopGeneration()
                    } else {
                        Task { await viewModel.sendMessage(modelContext: modelContext) }
                    }
                } label: {
                    Image(systemName: viewModel.isStreaming ? "stop.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isStreaming)
            }
            .padding(8)

            // Footer
            HStack {
                Button("New Chat") {
                    viewModel.createNewConversation(modelContext: modelContext)
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Spacer()

                Button("Settings") {
                    openSettings()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 360)
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }
}
