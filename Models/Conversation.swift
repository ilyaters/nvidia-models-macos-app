import Foundation
import SwiftData

/// A chat conversation persisted via SwiftData.
///
/// Each conversation has its own model, endpoint, API key, and sampling
/// parameters so multiple chats can run independently and in parallel with
/// different LLM configurations.
@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Per-conversation LLM settings
    var modelId: String
    /// Per-conversation API endpoint. When nil/empty, the global default is used.
    var apiEndpoint: String?
    /// Per-conversation API key. When nil/empty, the global Keychain key is used.
    var apiKey: String?
    /// Per-conversation system prompt. When nil, the global default is used.
    var systemPrompt: String?

    // MARK: - Per-conversation sampling parameters
    var temperature: Double
    var topP: Double
    var maxTokens: Int

    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message] = []

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        modelId: String = "",
        apiEndpoint: String? = nil,
        apiKey: String? = nil,
        systemPrompt: String? = nil,
        temperature: Double = 0.7,
        topP: Double = 0.95,
        maxTokens: Int = 1024
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.modelId = modelId
        self.apiEndpoint = apiEndpoint
        self.apiKey = apiKey
        self.systemPrompt = systemPrompt
        self.temperature = temperature
        self.topP = topP
        self.maxTokens = maxTokens
    }
}
