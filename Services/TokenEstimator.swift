import Foundation

/// Estimates token counts for pre-send context warnings.
///
/// This is a heuristic approximation — the actual count comes from the API's
/// `usage` object after the request completes. The estimate is used only to
/// warn the user before they exceed the model's context window.
struct TokenEstimator {
    /// Rough characters-per-token ratio for English text.
    private static let englishCharsPerToken: Double = 4.0

    /// Cyrillic text tends to use more tokens per character.
    private static let cyrillicCharsPerToken: Double = 2.5

    /// Estimate the token count for a given string.
    func estimate(text: String) -> Int {
        guard !text.isEmpty else { return 0 }

        // Count Cyrillic characters to adjust the ratio.
        let cyrillicCount = text.unicodeScalars.filter { scalar in
            (0x0400...0x04FF).contains(scalar.value) // Cyrillic block
        }.count

        let totalChars = text.count
        let cyrillicRatio = Double(cyrillicCount) / Double(totalChars)

        // Blend the ratios based on the proportion of Cyrillic characters.
        let effectiveCharsPerToken = Self.englishCharsPerToken * (1 - cyrillicRatio)
            + Self.cyrillicCharsPerToken * cyrillicRatio

        return max(1, Int(ceil(Double(totalChars) / effectiveCharsPerToken)))
    }

    /// Estimate total tokens for a conversation context (system prompt + messages).
    func estimateContext(systemPrompt: String?, messages: [Message]) -> Int {
        var total = 0

        if let systemPrompt, !systemPrompt.isEmpty {
            total += estimate(text: systemPrompt)
        }

        for message in messages {
            // Each message has a small overhead (~4 tokens for role/format).
            total += 4
            total += estimate(text: message.content)
        }

        return total
    }

    /// Percentage of the context window used (0–100).
    func contextUsage(estimatedTokens: Int, contextLength: Int?) -> Double {
        guard let contextLength, contextLength > 0 else { return 0 }
        return min(100, Double(estimatedTokens) / Double(contextLength) * 100)
    }

    /// Whether the estimated tokens are approaching the context limit.
    func isApproachingLimit(estimatedTokens: Int, contextLength: Int?, threshold: Double = 0.8) -> Bool {
        guard let contextLength, contextLength > 0 else { return false }
        return Double(estimatedTokens) >= Double(contextLength) * threshold
    }
}
