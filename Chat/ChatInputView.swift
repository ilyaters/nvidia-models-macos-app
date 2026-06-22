import SwiftUI
import SwiftData

/// Input area with text field, model selector, parameter sliders,
/// system prompt editor, and context indicator.
struct ChatInputView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showParameters = false

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

            // System prompt editor (collapsible)
            if viewModel.isSystemPromptExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Label("System Prompt", systemImage: "gearshape")
                        .font(.caption)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $viewModel.systemPromptOverride)
                        .font(.system(size: 12))
                        .frame(height: 60)
                        .padding(4)
                        .glassBackground(cornerRadius: 6)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // Toolbar: model selector, parameters, research toggle
            HStack(spacing: 8) {
                // Model selector
                Picker("Model", selection: $viewModel.selectedModelId) {
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
                    modelId: viewModel.selectedModelId,
                    status: viewModel.healthCheck.status(for: viewModel.selectedModelId)
                ) {
                    Task { await viewModel.checkModelHealth() }
                }

                // System prompt toggle
                Button {
                    viewModel.isSystemPromptExpanded.toggle()
                } label: {
                    Image(systemName: viewModel.isSystemPromptExpanded ? "gearshape.fill" : "gearshape")
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .help("System prompt")

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

            // Parameter sliders
            if showParameters {
                VStack(spacing: 6) {
                    GlassSliderStyle(value: $viewModel.temperature, in: 0...2) {
                        Text("Temperature")
                    }
                    GlassSliderStyle(value: $viewModel.topP, in: 0...1) {
                        Text("Top P")
                    }
                    HStack {
                        Text("Max Tokens")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Stepper(value: $viewModel.maxTokens, in: 1...32768, step: 128) {
                            Text("\(viewModel.maxTokens)")
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
                    Task { await viewModel.sendMessage(modelContext: modelContext) }
                } label: {
                    Image(systemName: viewModel.isStreaming ? "stop.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isStreaming)
                .keyboardShortcut(.return, modifiers: .command)
                .help("Send (Cmd+Enter)")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}
