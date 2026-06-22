import Foundation
import SwiftUI
import SwiftData
import Observation

/// View model for the menu bar popover quick chat.
@MainActor
@Observable
final class PopoverViewModel {
    private let apiService: NVIDIAAPIService
    private let latencyTracker = LatencyTracker()
    private let settings = AppSettings.shared

    var inputText: String = ""
    var messages: [Message] = []
    var isStreaming: Bool = false
    var errorMessage: String?
    var selectedModelId: String = ""
    var apiKey: String = ""

    init(apiService: NVIDIAAPIService = NVIDIAAPIService()) {
        self.apiService = apiService
    }

    func configure() {
        apiKey = KeychainManager.load("nvidia_api_key") ?? ""
        selectedModelId = settings.defaultModelId
    }

    func send(modelContext: ModelContext) async {
        guard !isStreaming else { return }
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty, !apiKey.isEmpty else {
            errorMessage = apiKey.isEmpty ? "Set API key in Settings" : nil
            return
        }

        inputText = ""
        errorMessage = nil
        isStreaming = true

        // Create user message and add to display.
        let userMessage = Message(role: .user, content: userText)
        messages.append(userMessage)

        // Build API messages BEFORE adding the empty assistant placeholder.
        var apiMessages: [APIRequestMessage] = []
        if !settings.defaultSystemPrompt.isEmpty {
            apiMessages.append(APIRequestMessage(role: "system", content: settings.defaultSystemPrompt))
        }
        for msg in messages where msg.role != .system {
            apiMessages.append(APIRequestMessage(role: msg.role.rawValue, content: msg.content))
        }

        // Create placeholder assistant message for streaming display.
        let assistantMessage = Message(role: .assistant, content: "", modelId: selectedModelId)
        messages.append(assistantMessage)

        let params = SamplingParams(
            temperature: settings.defaultTemperature,
            topP: settings.defaultTopP,
            maxTokens: settings.defaultMaxTokens
        )

        latencyTracker.start()
        var outputTokenCount = 0

        for await event in apiService.streamChat(
            endpoint: settings.apiEndpoint,
            apiKey: apiKey,
            model: selectedModelId,
            messages: apiMessages,
            params: params
        ) {
            switch event {
            case .delta(let text):
                if latencyTracker.timeToFirstTokenMs == 0 {
                    latencyTracker.recordFirstToken()
                }
                assistantMessage.content += text
                outputTokenCount += 1

            case .complete(let usage):
                latencyTracker.finish()
                assistantMessage.inputTokens = usage?.promptTokens ?? 0
                assistantMessage.outputTokens = usage?.completionTokens ?? outputTokenCount
                assistantMessage.totalTokens = usage?.totalTokens ?? 0
                assistantMessage.responseTimeMs = latencyTracker.totalResponseTimeMs

            case .error(let error):
                errorMessage = error.localizedDescription
            }
        }

        isStreaming = false
    }

    func clear() {
        messages.removeAll()
        errorMessage = nil
    }
}
