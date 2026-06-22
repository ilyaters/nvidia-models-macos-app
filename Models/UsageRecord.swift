import Foundation
import SwiftData

/// Per-request usage metrics, persisted for aggregation and the metrics dashboard.
@Model
final class UsageRecord {
    var id: UUID
    var timestamp: Date
    var modelId: String
    var conversationId: UUID?

    // Token counts
    var promptTokens: Int
    var completionTokens: Int
    var totalTokens: Int

    // Latency (milliseconds)
    var timeToFirstTokenMs: Double
    var totalResponseTimeMs: Double

    /// Tokens generated per second.
    var tokensPerSecond: Double

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        modelId: String,
        conversationId: UUID? = nil,
        promptTokens: Int = 0,
        completionTokens: Int = 0,
        totalTokens: Int = 0,
        timeToFirstTokenMs: Double = 0,
        totalResponseTimeMs: Double = 0,
        tokensPerSecond: Double = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.modelId = modelId
        self.conversationId = conversationId
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
        self.timeToFirstTokenMs = timeToFirstTokenMs
        self.totalResponseTimeMs = totalResponseTimeMs
        self.tokensPerSecond = tokensPerSecond
    }
}
