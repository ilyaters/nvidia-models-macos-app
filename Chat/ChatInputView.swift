import SwiftUI
import SwiftData

/// Input area with text field, model selector, parameter sliders,
/// system prompt editor, per-chat settings, and context indicator.
///
/// All settings (model, endpoint, API key, temperature, etc.) are bound
/// directly to the current conversation, so each chat is fully independent.
struct ChatInputView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showParameters = false

    /// Convenience accessor for the current conversation.
    private var conversation: Conversation? {
        viewModel.currentConversation
    }

    var body: some View {
        VStack(spacing: 0) {
            // Error banner with retry
            if let error = viewModel.errorMessage {
                ErrorStateView(
                    message: error,
                    onRetry: {
                        Task { await viewModel.retryLastRequest(modelContext: modelContext) }
                    },
                    onDismiss: {
                        viewModel.dismissError()
                    }
                )
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }

            // Per-conversation settings (collapsible)
            if viewModel.isSystemPromptExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Per-chat model selector
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Model for this chat", systemImage: "cpu")
                            .font(.caption)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                        Picker("Model", selection: Binding(
                            get: { conversation?.modelId ?? "" },
                            set: { newModelId in
                                conversation?.modelId = newModelId
                                try? modelContext.save()
                                Task { await viewModel.checkModelHealth() }
                            }
                        )) {
                            if viewModel.availableModels.isEmpty {
                                Text("No models loaded").tag("")
                            }
                            ForEach(viewModel.availableModels) { model in
                                Text(model.displayName).tag(model.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Divider()

                    // Per-chat endpoint
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Endpoint for this chat (optional)", systemImage: "network")
                            .font(.caption)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                        TextField("Use global endpoint", text: Binding(
                            get: { conversation?.apiEndpoint ?? "" },
                            set: { newEndpoint in
                                conversation?.apiEndpoint = newEndpoint.isEmpty ? nil : newEndpoint
                                try? modelContext.save()
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        Text("Leave empty to use the global endpoint from Settings.")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }

                    Divider()

                    // Per-chat API key
                    VStack(alignment: .leading, spacing: 4) {
                        Label("API key for this chat (optional)", systemImage: "key.fill")
                            .font(.caption)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                        SecureField("Use global key", text: Binding(
                            get: { conversation?.apiKey ?? "" },
                            set: { newKey in
                                conversation?.apiKey = newKey.isEmpty ? nil : newKey
                                try? modelContext.save()
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        Text("Leave empty to use the global API key from Settings.")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }

                    Divider()

                    // System prompt
                    VStack(alignment: .leading, spacing: 4) {
                        Label("System Prompt", systemImage: "gearshape")
                            .font(.caption)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                        TextEditor(text: Binding(
                            get: { conversation?.systemPrompt ?? viewModel.systemPromptOverride },
                            set: { newPrompt in
                                conversation?.systemPrompt = newPrompt
                                try? modelContext.save()
                            }
                        ))
                        .font(.system(size: 12))
                        .frame(height: 60)
                        .padding(4)
                        .glassBackground(cornerRadius: 6)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // Toolbar: model selector, parameters, research toggle
            HStack(spacing: 8) {
                // Model selector — bound to conversation
                Picker("Model", selection: Binding(
                    get: { conversation?.modelId ?? "" },
                    set: { newModelId in
                        conversation?.modelId = newModelId
                        try? modelContext.save()
                        Task { await viewModel.checkModelHealth() }
                    }
                )) {
                    if viewModel.availableModels.isEmpty {
                        Text("No models loaded").tag("")
                    }
                    ForEach(viewModel.availableModels) { model in
                        Text(model.displayName).tag(model.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 240)

                // Model health status indicator
                ModelStatusIndicatorView(
                    modelId: conversation?.modelId ?? "",
                    status: viewModel.healthCheck.status(for: conversation?.modelId ?? "")
                ) {
                    Task { await viewModel.checkModelHealth() }
                }

                // Settings toggle
                Button {
                    viewModel.isSystemPromptExpanded.toggle()
                } label: {
                    Image(systemName: viewModel.isSystemPromptExpanded ? "gearshape.fill" : "gearshape")
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .help("Per-chat settings")

                // Parameters toggle
                Button {
                    showParameters.toggle()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .help("Sampling parameters")

                // Research mode toggle
                Button {
                    viewModel.researchMode.toggle()
                } label: {
                    Image(systemName: viewModel.researchMode ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(viewModel.researchMode ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.borderless)
                .help("Web search (research mode)")

                Spacer()

                // Context indicator
                ContextIndicatorView(
                    estimatedTokens: viewModel.estimatedContextTokens,
                    contextLimit: viewModel.contextLimit,
                    isApproachingLimit: viewModel.isApproachingLimit
                )
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Parameter sliders — bound to conversation
            if showParameters {
                VStack(spacing: 6) {
                    GlassSliderStyle(value: Binding(
                        get: { conversation?.temperature ?? 0.7 },
                        set: { conversation?.temperature = $0 }
                    ), in: 0...2) {
                        Text("Temperature")
                    }
                    GlassSliderStyle(value: Binding(
                        get: { conversation?.topP ?? 0.95 },
                        set: { conversation?.topP = $0 }
                    ), in: 0...1) {
                        Text("Top P")
                    }
                    HStack {
                        Text("Max Tokens")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Stepper(value: Binding(
                            get: { conversation?.maxTokens ?? 1024 },
                            set: { conversation?.maxTokens = $0 }
                        ), in: 1...32768, step: 128) {
                            Text("\(conversation?.maxTokens ?? 1024)")
                                .font(.system(size: 12, design: .monospaced))
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .glassBackground(cornerRadius: 8)
            }

            // Text input + send button
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type a message… (Cmd+Enter to send)", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...6)
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
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isStreaming)
                .keyboardShortcut(.return, modifiers: .command)
                .help(viewModel.isStreaming ? "Stop generation" : "Send (Cmd+Enter)")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}
