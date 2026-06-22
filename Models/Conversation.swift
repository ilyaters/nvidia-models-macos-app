import Foundation
import SwiftData

/// A chat conversation persisted via SwiftData.
@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var modelId: String
    /// Per-conversation system prompt override. When nil, the global default is used.
    var systemPrompt: String?

    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message] = []

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        modelId: String = "",
        systemPrompt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.modelId = modelId
        self.systemPrompt = systemPrompt
    }
}
