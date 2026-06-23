import SwiftUI
import SwiftData
import AppKit

/// Quick chat popover for the menu bar.
struct PopoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @State private var viewModel = PopoverViewModel()

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

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if viewModel.messages.isEmpty {
                            Text("Quick chat — type a message below")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 20)
                        }
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                isStreaming: viewModel.isStreaming && message.id == viewModel.messages.last?.id && message.role == .assistant
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
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
                        Task { await viewModel.send(modelContext: modelContext) }
                    }

                Button {
                    Task { await viewModel.send(modelContext: modelContext) }
                } label: {
                    Image(systemName: viewModel.isStreaming ? "stop.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(8)

            // Footer
            HStack {
                if !viewModel.messages.isEmpty {
                    Button("Clear", role: .destructive) {
                        viewModel.clear()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
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
        .onAppear { viewModel.configure() }
    }
}
