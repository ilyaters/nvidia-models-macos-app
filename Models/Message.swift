import Foundation
import SwiftData

/// Role of a chat message, mirroring the OpenAI-compatible API.
enum MessageRole: String, Codable, CaseIterable {
    case system
    case user
    case assistant
}

/// A single message within a conversation, persisted via SwiftData.
@Model
final class Message {
    var id: UUID
    var roleRaw: String
    var content: String
    var timestamp: Date
    var modelId: String?

    // MARK: Token counts (populated from API `usage` after a response)
    var inputTokens: Int
    var outputTokens: Int
    var totalTokens: Int

    // MARK: Latency (milliseconds)
    var responseTimeMs: Double

    var conversation: Conversation?

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = .now,
        modelId: String? = nil,
        inputTokens: Int = 0,
        outputTokens: Int = 0,
        totalTokens: Int = 0,
        responseTimeMs: Double = 0
    ) {
        self.id = id
        self.roleRaw = role.rawValue
        self.content = content
        self.timestamp = timestamp
        self.modelId = modelId
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
        self.responseTimeMs = responseTimeMs
    }

    var role: MessageRole {
        get { MessageRole(rawValue: roleRaw) ?? .user }
        set { roleRaw = newValue.rawValue }
    }
}
