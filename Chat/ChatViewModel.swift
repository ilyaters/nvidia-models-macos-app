import Foundation
import SwiftUI
import SwiftData
import Observation

/// View model driving the chat interface.
///
/// Manages conversation state, message sending, streaming responses,
/// and usage metrics recording.
@MainActor
@Observable
final class ChatViewModel {

    /// Shared singleton so the menu bar popover and main window stay in sync.
    static let shared = ChatViewModel()

    // MARK: - Dependencies
    private let apiService: NVIDIAAPIService
    private let modelsFetcher: ModelsFetcher
    private let searchService: GoogleSearchService
    private let tokenEstimator = TokenEstimator()
    private let latencyTracker = LatencyTracker()
    private let settings = AppSettings.shared
    private var metricsStore: MetricsStore?
    let healthCheck = HealthCheckService()

    // MARK: - State
    var conversations: [Conversation] = []
    var currentConversation: Conversation?
    var availableModels: [NvidiaModel] = []
    var inputText: String = ""
    var systemPromptOverride: String = ""
    var isSystemPromptExpanded: Bool = false
    var isStreaming: Bool = false
    var errorMessage: String?
    var researchMode: Bool = false
    var searchResults: [GoogleSearchService.SearchResult] = []

    // Sampling parameters (editable in UI)
    var temperature: Double = 0.7
    var topP: Double = 0.95
    var maxTokens: Int = 1024
    var selectedModelId: String = ""

    // Context estimation
    var estimatedContextTokens: Int = 0
    var contextLimit: Int?
    var isApproachingLimit: Bool = false

    // API key (loaded from Keychain)
    var apiKey: String = ""

    /// Last user message text, stored for retry.
    private var lastSentText: String = ""

    /// Currently running streaming task. Stored so it can be cancelled to
    /// stop generation.
    private var streamingTask: Task<Void, Never>?

    init(
        apiService: NVIDIAAPIService = NVIDIAAPIService(),
        modelsFetcher: ModelsFetcher = ModelsFetcher(),
        searchService: GoogleSearchService = GoogleSearchService()
    ) {
        self.apiService = apiService
        self.modelsFetcher = modelsFetcher
        self.searchService = searchService
    }

    // MARK: - Setup

    func configure(modelContext: ModelContext) {
        self.metricsStore = MetricsStore(modelContext: modelContext)
        loadAPIKey()
        loadConversations(modelContext: modelContext)
        Task { await loadModels() }
    }

    func loadAPIKey() {
        apiKey = KeychainManager.load("nvidia_api_key") ?? ""
    }

    func saveAPIKey(_ key: String) {
        apiKey = key
        KeychainManager.save(key, for: "nvidia_api_key")
    }

    // MARK: - Models

    func loadModels() async {
        guard !apiKey.isEmpty else { return }
        do {
            availableModels = try await modelsFetcher.fetchModels(
                endpoint: settings.apiEndpoint,
                apiKey: apiKey
            )
            if selectedModelId.isEmpty {
                selectedModelId = settings.defaultModelId
            }
            // Update context limit from model metadata.
            contextLimit = availableModels.first { $0.id == selectedModelId }?.contextLength
            // Auto-check the selected model's health after loading.
            await checkModelHealth()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Health Check

    /// Sends a lightweight health-check request for the currently selected model.
    func checkModelHealth() async {
        guard !selectedModelId.isEmpty else { return }
        await healthCheck.check(
            model: selectedModelId,
            endpoint: settings.apiEndpoint,
            apiKey: apiKey
        )
    }

    // MARK: - Conversations

    func loadConversations(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        conversations = (try? modelContext.fetch(descriptor)) ?? []

        if currentConversation == nil {
            currentConversation = conversations.first
        }
    }

    func createNewConversation(modelContext: ModelContext) {
        let conversation = Conversation(
            modelId: selectedModelId.isEmpty ? settings.defaultModelId : selectedModelId,
            systemPrompt: settings.defaultSystemPrompt.isEmpty ? nil : settings.defaultSystemPrompt
        )
        modelContext.insert(conversation)
        try? modelContext.save()
        conversations.insert(conversation, at: 0)
        currentConversation = conversation
        systemPromptOverride = conversation.systemPrompt ?? settings.defaultSystemPrompt
    }

    func deleteConversation(_ conversation: Conversation, modelContext: ModelContext) {
        modelContext.delete(conversation)
        try? modelContext.save()
        conversations.removeAll { $0.id == conversation.id }
        if currentConversation?.id == conversation.id {
            currentConversation = conversations.first
        }
    }

    func renameConversation(_ conversation: Conversation, to title: String, modelContext: ModelContext) {
        conversation.title = title
        conversation.updatedAt = .now
        try? modelContext.save()
    }

    // MARK: - Context Estimation

    func updateContextEstimation() {
        guard let conversation = currentConversation else {
            estimatedContextTokens = 0
            isApproachingLimit = false
            return
        }

        let prompt = systemPromptOverride.isEmpty ? nil : systemPromptOverride
        estimatedContextTokens = tokenEstimator.estimateContext(
            systemPrompt: prompt,
            messages: conversation.messages
        )
        isApproachingLimit = tokenEstimator.isApproachingLimit(
            estimatedTokens: estimatedContextTokens,
            contextLength: contextLimit
        )
    }

    // MARK: - Send Message

    func sendMessage(modelContext: ModelContext) async {
        guard let conversation = currentConversation else { return }
        guard !isStreaming else { return }
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }

        // Use per-conversation API key if set, otherwise fall back to the
        // global key from Keychain.
        let effectiveAPIKey = conversation.apiKey?.isEmpty == false ? conversation.apiKey! : apiKey
        guard !effectiveAPIKey.isEmpty else {
            errorMessage = "Please set your NVIDIA API key in Settings."
            return
        }

        // Clear input and error.
        inputText = ""
        errorMessage = nil
        isStreaming = true
        lastSentText = userText

        // Save user message.
        let userMessage = Message(role: .user, content: userText)
        userMessage.conversation = conversation
        modelContext.insert(userMessage)
        conversation.updatedAt = .now
        try? modelContext.save()

        // Build messages array for the API.
        var apiMessages: [APIRequestMessage] = []

        let systemPrompt = systemPromptOverride.isEmpty ? settings.defaultSystemPrompt : systemPromptOverride
        if !systemPrompt.isEmpty {
            apiMessages.append(APIRequestMessage(role: "system", content: systemPrompt))
        }

        // Optionally fetch web search results.
        if researchMode {
            await fetchSearchResults(for: userText)
            if !searchResults.isEmpty {
                let context = searchService.formatContext(results: searchResults)
                apiMessages.append(APIRequestMessage(role: "system", content: context))
            }
        }

        // Add conversation history (sorted by timestamp for correct order).
        let sortedMessages = conversation.messages
            .filter { $0.role != .system }
            .sorted { $0.timestamp < $1.timestamp }
        for msg in sortedMessages {
            apiMessages.append(APIRequestMessage(role: msg.role.rawValue, content: msg.content))
        }

        // Use per-conversation model if set, otherwise the selected model.
        let effectiveModelId = conversation.modelId.isEmpty ? selectedModelId : conversation.modelId

        // Create placeholder assistant message for streaming.
        let assistantMessage = Message(role: .assistant, content: "", modelId: effectiveModelId)
        assistantMessage.conversation = conversation
        modelContext.insert(assistantMessage)

        // Build sampling params.
        let params = SamplingParams(
            temperature: temperature,
            topP: topP,
            maxTokens: maxTokens,
            presencePenalty: nil,
            frequencyPenalty: nil,
            stop: nil,
            seed: nil,
            thinkingMode: false
        )

        // Start latency tracking.
        latencyTracker.start()

        // Stream the response. Wrapped in a stored Task so it can be cancelled.
        var outputTokenCount = 0

        streamingTask = Task {
            for await event in apiService.streamChat(
                endpoint: settings.apiEndpoint,
                apiKey: effectiveAPIKey,
                model: effectiveModelId,
                messages: apiMessages,
                params: params
            ) {
                if Task.isCancelled { break }

                switch event {
                case .delta(let text):
                    if latencyTracker.timeToFirstTokenMs == 0 {
                        latencyTracker.recordFirstToken()
                    }
                    assistantMessage.content += text
                    outputTokenCount += 1

                case .complete(let usage):
                    latencyTracker.finish()

                    // Update message with token counts.
                    assistantMessage.inputTokens = usage?.promptTokens ?? 0
                    assistantMessage.outputTokens = usage?.completionTokens ?? outputTokenCount
                    assistantMessage.totalTokens = usage?.totalTokens ?? 0
                    assistantMessage.responseTimeMs = latencyTracker.totalResponseTimeMs

                    // Save usage record for metrics.
                    metricsStore?.saveUsageRecord(
                        modelId: effectiveModelId,
                        conversationId: conversation.id,
                        usage: usage,
                        latency: latencyTracker,
                        outputTokenCount: outputTokenCount
                    )

                case .error(let error):
                    errorMessage = error.localizedDescription
                    if assistantMessage.content.isEmpty {
                        modelContext.delete(assistantMessage)
                    }
                }
            }

            conversation.updatedAt = .now
            try? modelContext.save()
            isStreaming = false
            updateContextEstimation()
        }

        await streamingTask?.value
    }

    /// Stops the currently running streaming generation.
    func stopGeneration() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
    }

    // MARK: - Message Actions

    /// Resends a specific user message — removes all messages after it and
    /// regenerates the response.
    func resend(from message: Message, modelContext: ModelContext) async {
        guard let conversation = currentConversation else { return }
        guard message.role == .user else { return }

        // Remove all messages after the specified user message.
        let messagesToRemove = conversation.messages.filter { $0.timestamp > message.timestamp }
        for msg in messagesToRemove {
            modelContext.delete(msg)
        }

        // Remove the user message itself (sendMessage will re-add it).
        let userText = message.content
        modelContext.delete(message)
        try? modelContext.save()

        inputText = userText
        await sendMessage(modelContext: modelContext)
    }

    /// Edits a user message's content and regenerates the response.
    func editMessage(_ message: Message, newContent: String, modelContext: ModelContext) async {
        guard message.role == .user else { return }
        guard let conversation = currentConversation else { return }

        // Remove all messages after the edited message.
        let messagesToRemove = conversation.messages.filter { $0.timestamp > message.timestamp }
        for msg in messagesToRemove {
            modelContext.delete(msg)
        }

        // Update the message content.
        message.content = newContent
        try? modelContext.save()

        // Resend from this message.
        let userText = newContent
        modelContext.delete(message)
        try? modelContext.save()

        inputText = userText
        await sendMessage(modelContext: modelContext)
    }

    /// Copies the entire conversation as formatted text.
    func copyConversation() -> String {
        guard let conversation = currentConversation else { return "" }

        var result = "# \(conversation.title)\n\n"
        if let prompt = conversation.systemPrompt, !prompt.isEmpty {
            result += "**System:** \(prompt)\n\n"
        }

        let sortedMessages = conversation.messages.sorted { $0.timestamp < $1.timestamp }
        for msg in sortedMessages {
            let role = msg.role.rawValue.capitalized
            result += "**\(role):** \(msg.content)\n\n"
        }

        return result
    }

    // MARK: - Web Search

    private func fetchSearchResults(for query: String) async {
        guard let googleKey = KeychainManager.load("google_search_api_key"),
              let cx = KeychainManager.load("google_search_cx") else {
            return
        }

        do {
            searchResults = try await searchService.search(
                query: query,
                apiKey: googleKey,
                searchEngineId: cx,
                maxResults: settings.googleSearchMaxResults
            )
        } catch {
            searchResults = []
        }
    }

    // MARK: - Regenerate

    func regenerateLastMessage(modelContext: ModelContext) async {
        guard let conversation = currentConversation else { return }

        // Find the last user message.
        guard let lastUserMessage = conversation.messages.last(where: { $0.role == .user }) else { return }

        // Remove messages after the last user message.
        let messagesToRemove = conversation.messages.filter { $0.timestamp > lastUserMessage.timestamp }
        for msg in messagesToRemove {
            modelContext.delete(msg)
        }
        try? modelContext.save()

        // Re-send with the last user message content.
        inputText = lastUserMessage.content
        modelContext.delete(lastUserMessage)
        try? modelContext.save()
        await sendMessage(modelContext: modelContext)
    }

    // MARK: - Retry

    /// Retries the last failed request by re-sending the last user message.
    func retryLastRequest(modelContext: ModelContext) async {
        guard !lastSentText.isEmpty else { return }
        errorMessage = nil

        // Remove the last user message if it exists (it was already saved).
        if let conversation = currentConversation,
           let lastUser = conversation.messages.last(where: { $0.role == .user }),
           lastUser.content == lastSentText {
            modelContext.delete(lastUser)
            try? modelContext.save()
        }

        inputText = lastSentText
        await sendMessage(modelContext: modelContext)
    }

    /// Dismisses the current error message.
    func dismissError() {
        errorMessage = nil
    }
}
