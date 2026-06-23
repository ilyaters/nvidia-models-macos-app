import Foundation
import SwiftUI
import SwiftData
import Observation

/// View model driving the chat interface.
///
/// Manages conversation state, message sending, streaming responses,
/// and usage metrics recording. Each conversation streams independently so
/// multiple chats can run in parallel with different models and endpoints.
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
    private let settings = AppSettings.shared
    private var metricsStore: MetricsStore?
    let healthCheck = HealthCheckService()

    // MARK: - State
    var conversations: [Conversation] = []
    var currentConversation: Conversation?
    var availableModels: [NvidiaModel] = []
    var inputText: String = ""
    var systemPromptOverride: String = ""

    /// Input text drafts per conversation, so switching chats preserves drafts.
    private var inputTexts: [UUID: String] = [:]
    var isSystemPromptExpanded: Bool = false
    var errorMessage: String?
    var researchMode: Bool = false
    var searchResults: [GoogleSearchService.SearchResult] = []

    // Context estimation
    var estimatedContextTokens: Int = 0
    var contextLimit: Int?
    var isApproachingLimit: Bool = false

    // API key (loaded from Keychain — global fallback)
    var apiKey: String = ""

    /// Streaming tasks keyed by conversation ID, so multiple chats can stream
    /// in parallel and be stopped independently.
    private var streamingTasks: [UUID: Task<Void, Never>] = [:]

    /// Latency trackers keyed by conversation ID.
    private var latencyTrackers: [UUID: LatencyTracker] = [:]

    /// Last user message text per conversation, stored for retry.
    private var lastSentTexts: [UUID: String] = [:]

    /// Health check auto-refresh timer.
    private var healthCheckTimer: Timer?

    /// Debounce timer for context estimation.
    private var contextEstimationWorkItem: Task<Void, Never>?

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
        startHealthCheckTimer()
    }

    func loadAPIKey() {
        apiKey = KeychainManager.load("nvidia_api_key") ?? ""
    }

    func saveAPIKey(_ key: String) {
        apiKey = key
        KeychainManager.save(key, for: "nvidia_api_key")
    }

    // MARK: - Streaming State

    /// Returns whether a specific conversation is currently streaming.
    func isStreaming(for conversationId: UUID) -> Bool {
        streamingTasks[conversationId] != nil
    }

    /// Returns whether the current conversation is streaming.
    var isStreaming: Bool {
        guard let id = currentConversation?.id else { return false }
        return isStreaming(for: id)
    }

    // MARK: - Models

    func loadModels() async {
        guard !apiKey.isEmpty else { return }
        do {
            availableModels = try await modelsFetcher.fetchModels(
                endpoint: settings.apiEndpoint,
                apiKey: apiKey
            )
            // Auto-check the selected model's health after loading.
            await checkModelHealth()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Health Check

    /// Sends a lightweight health-check request for the currently selected model.
    /// Shows the "checking" spinner.
    func checkModelHealth() async {
        guard let conversation = currentConversation else { return }
        let modelId = conversation.modelId.isEmpty ? settings.defaultModelId : conversation.modelId
        guard !modelId.isEmpty else { return }

        let effectiveKey = conversation.apiKey?.isEmpty == false ? conversation.apiKey! : apiKey
        let effectiveEndpoint = conversation.apiEndpoint?.isEmpty == false ? conversation.apiEndpoint! : settings.apiEndpoint

        await healthCheck.check(
            model: modelId,
            endpoint: effectiveEndpoint,
            apiKey: effectiveKey
        )
    }

    /// Silent health check — does NOT show the "checking" spinner.
    /// Used by the auto-refresh timer.
    func silentCheckModelHealth() async {
        guard let conversation = currentConversation else { return }
        let modelId = conversation.modelId.isEmpty ? settings.defaultModelId : conversation.modelId
        guard !modelId.isEmpty else { return }

        let effectiveKey = conversation.apiKey?.isEmpty == false ? conversation.apiKey! : apiKey
        let effectiveEndpoint = conversation.apiEndpoint?.isEmpty == false ? conversation.apiEndpoint! : settings.apiEndpoint

        await healthCheck.silentCheck(
            model: modelId,
            endpoint: effectiveEndpoint,
            apiKey: effectiveKey
        )
    }

    /// Starts a timer that silently refreshes the health check every 5 seconds.
    private func startHealthCheckTimer() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.silentCheckModelHealth()
            }
        }
    }

    // MARK: - Conversations

    func loadConversations(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        conversations = (try? modelContext.fetch(descriptor)) ?? []

        if currentConversation == nil {
            currentConversation = conversations.first
            syncSettingsFromCurrentConversation()
        }
    }

    func createNewConversation(modelContext: ModelContext) {
        let conversation = Conversation(
            modelId: settings.defaultModelId,
            apiEndpoint: settings.apiEndpoint,
            apiKey: nil,
            systemPrompt: settings.defaultSystemPrompt.isEmpty ? nil : settings.defaultSystemPrompt,
            temperature: settings.defaultTemperature,
            topP: settings.defaultTopP,
            maxTokens: settings.defaultMaxTokens
        )
        modelContext.insert(conversation)
        try? modelContext.save()
        conversations.insert(conversation, at: 0)
        currentConversation = conversation
        syncSettingsFromCurrentConversation()
    }

    func deleteConversation(_ conversation: Conversation, modelContext: ModelContext) {
        stopGeneration(for: conversation.id)
        modelContext.delete(conversation)
        try? modelContext.save()
        conversations.removeAll { $0.id == conversation.id }
        if currentConversation?.id == conversation.id {
            currentConversation = conversations.first
            syncSettingsFromCurrentConversation()
        }
    }

    func renameConversation(_ conversation: Conversation, to title: String, modelContext: ModelContext) {
        conversation.title = title
        conversation.updatedAt = .now
        try? modelContext.save()
    }

    /// Syncs the UI-editable settings from the current conversation.
    /// Also saves the current input text draft and restores the new
    /// conversation's draft.
    func syncSettingsFromCurrentConversation() {
        guard let conversation = currentConversation else { return }
        systemPromptOverride = conversation.systemPrompt ?? settings.defaultSystemPrompt
        contextLimit = availableModels.first { $0.id == conversation.modelId }?.contextLength
        // Restore the input text draft for this conversation (or clear it).
        inputText = inputTexts[conversation.id] ?? ""
        updateContextEstimation()
        Task { await checkModelHealth() }
    }

    // MARK: - Context Estimation

    func updateContextEstimation() {
        guard let conversation = currentConversation else {
            estimatedContextTokens = 0
            isApproachingLimit = false
            return
        }

        let prompt = conversation.systemPrompt ?? (systemPromptOverride.isEmpty ? nil : systemPromptOverride)
        estimatedContextTokens = tokenEstimator.estimateContext(
            systemPrompt: prompt,
            messages: conversation.messages
        )
        isApproachingLimit = tokenEstimator.isApproachingLimit(
            estimatedTokens: estimatedContextTokens,
            contextLength: contextLimit
        )
    }

    /// Debounced context estimation — avoids recalculating on every keystroke.
    func scheduleContextEstimation() {
        contextEstimationWorkItem?.cancel()
        contextEstimationWorkItem = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s debounce
            if !Task.isCancelled {
                updateContextEstimation()
            }
        }
    }

    // MARK: - Send Message

    func sendMessage(modelContext: ModelContext) async {
        guard let conversation = currentConversation else { return }
        guard !isStreaming(for: conversation.id) else { return }
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }

        // Use per-conversation API key if set, otherwise fall back to global.
        let effectiveAPIKey = conversation.apiKey?.isEmpty == false ? conversation.apiKey! : apiKey
        guard !effectiveAPIKey.isEmpty else {
            errorMessage = "Please set your NVIDIA API key in Settings or per-chat."
            return
        }

        // Use per-conversation endpoint if set, otherwise global.
        let effectiveEndpoint = conversation.apiEndpoint?.isEmpty == false ? conversation.apiEndpoint! : settings.apiEndpoint

        // Use per-conversation model.
        let effectiveModelId = conversation.modelId.isEmpty ? settings.defaultModelId : conversation.modelId

        // Clear input and error.
        inputText = ""
        errorMessage = nil
        lastSentTexts[conversation.id] = userText

        // Save user message.
        let userMessage = Message(role: .user, content: userText)
        userMessage.conversation = conversation
        modelContext.insert(userMessage)
        conversation.updatedAt = .now
        try? modelContext.save()

        // Build messages array for the API.
        var apiMessages: [APIRequestMessage] = []

        let systemPrompt = conversation.systemPrompt ?? (systemPromptOverride.isEmpty ? settings.defaultSystemPrompt : systemPromptOverride)
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

        // Create placeholder assistant message for streaming.
        let assistantMessage = Message(role: .assistant, content: "", modelId: effectiveModelId)
        assistantMessage.conversation = conversation
        modelContext.insert(assistantMessage)
        try? modelContext.save()

        // Build sampling params from per-conversation settings.
        let params = SamplingParams(
            temperature: conversation.temperature,
            topP: conversation.topP,
            maxTokens: conversation.maxTokens,
            presencePenalty: nil,
            frequencyPenalty: nil,
            stop: nil,
            seed: nil,
            thinkingMode: false
        )

        // Start latency tracking.
        let tracker = LatencyTracker()
        tracker.start()
        latencyTrackers[conversation.id] = tracker

        // Stream the response. Wrapped in a stored Task so it can be cancelled.
        let convId = conversation.id
        streamingTasks[convId] = Task {
            var outputTokenCount = 0

            for await event in apiService.streamChat(
                endpoint: effectiveEndpoint,
                apiKey: effectiveAPIKey,
                model: effectiveModelId,
                messages: apiMessages,
                params: params
            ) {
                if Task.isCancelled { break }

                switch event {
                case .delta(let text):
                    if tracker.timeToFirstTokenMs == 0 {
                        tracker.recordFirstToken()
                    }
                    assistantMessage.content += text
                    outputTokenCount += 1

                case .complete(let usage):
                    tracker.finish()

                    assistantMessage.inputTokens = usage?.promptTokens ?? 0
                    assistantMessage.outputTokens = usage?.completionTokens ?? outputTokenCount
                    assistantMessage.totalTokens = usage?.totalTokens ?? 0
                    assistantMessage.responseTimeMs = tracker.totalResponseTimeMs

                    metricsStore?.saveUsageRecord(
                        modelId: effectiveModelId,
                        conversationId: convId,
                        usage: usage,
                        latency: tracker,
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
            streamingTasks[convId] = nil
            latencyTrackers[convId] = nil
            updateContextEstimation()
        }
    }

    /// Stops generation for a specific conversation.
    func stopGeneration(for conversationId: UUID) {
        streamingTasks[conversationId]?.cancel()
        streamingTasks[conversationId] = nil
        latencyTrackers[conversationId] = nil
    }

    /// Stops generation for the current conversation.
    func stopGeneration() {
        guard let id = currentConversation?.id else { return }
        stopGeneration(for: id)
    }

    // MARK: - Message Actions

    /// Resends a specific user message — removes all messages after it and
    /// regenerates the response.
    func resend(from message: Message, modelContext: ModelContext) async {
        guard let conversation = currentConversation else { return }
        guard message.role == .user else { return }

        let messagesToRemove = conversation.messages.filter { $0.timestamp > message.timestamp }
        for msg in messagesToRemove {
            modelContext.delete(msg)
        }

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

        let messagesToRemove = conversation.messages.filter { $0.timestamp > message.timestamp }
        for msg in messagesToRemove {
            modelContext.delete(msg)
        }

        message.content = newContent
        try? modelContext.save()

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

        guard let lastUserMessage = conversation.messages.last(where: { $0.role == .user }) else { return }

        let messagesToRemove = conversation.messages.filter { $0.timestamp > lastUserMessage.timestamp }
        for msg in messagesToRemove {
            modelContext.delete(msg)
        }
        try? modelContext.save()

        inputText = lastUserMessage.content
        modelContext.delete(lastUserMessage)
        try? modelContext.save()
        await sendMessage(modelContext: modelContext)
    }

    // MARK: - Retry

    func retryLastRequest(modelContext: ModelContext) async {
        guard let conversation = currentConversation,
              let lastSent = lastSentTexts[conversation.id], !lastSent.isEmpty else { return }
        errorMessage = nil

        if let lastUser = conversation.messages.last(where: { $0.role == .user }),
           lastUser.content == lastSent {
            modelContext.delete(lastUser)
            try? modelContext.save()
        }

        inputText = lastSent
        await sendMessage(modelContext: modelContext)
    }

    func dismissError() {
        errorMessage = nil
    }
}
