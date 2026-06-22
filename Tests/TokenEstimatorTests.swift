import XCTest
@testable import NvidiaLLM

final class TokenEstimatorTests: XCTestCase {
    private let estimator = TokenEstimator()

    func testEmptyString() {
        XCTAssertEqual(estimator.estimate(text: ""), 0)
    }

    func testEnglishText() {
        // ~4 chars per token for English.
        let text = "Hello world, this is a test message."
        let estimate = estimator.estimate(text: text)
        // 35 chars / 4 ≈ 9 tokens.
        XCTAssertGreaterThan(estimate, 5)
        XCTAssertLessThan(estimate, 15)
    }

    func testCyrillicText() {
        // Cyrillic uses more tokens per character.
        let text = "Привет мир, это тестовое сообщение."
        let estimate = estimator.estimate(text: text)
        XCTAssertGreaterThan(estimate, 5)
    }

    func testContextEstimation() {
        let messages = [
            Message(role: .user, content: "Hello"),
            Message(role: .assistant, content: "Hi there, how can I help you today?")
        ]
        let total = estimator.estimateContext(systemPrompt: "You are a helpful assistant.", messages: messages)
        XCTAssertGreaterThan(total, 10)
    }

    func testContextUsagePercentage() {
        let usage = estimator.contextUsage(estimatedTokens: 500, contextLength: 1000)
        XCTAssertEqual(usage, 50.0, accuracy: 0.1)
    }

    func testContextUsageNoLimit() {
        let usage = estimator.contextUsage(estimatedTokens: 500, contextLength: nil)
        XCTAssertEqual(usage, 0)
    }

    func testIsApproachingLimit() {
        XCTAssertTrue(estimator.isApproachingLimit(estimatedTokens: 8500, contextLength: 10000))
        XCTAssertFalse(estimator.isApproachingLimit(estimatedTokens: 5000, contextLength: 10000))
    }

    func testIsApproachingLimitNoLimit() {
        XCTAssertFalse(estimator.isApproachingLimit(estimatedTokens: 999999, contextLength: nil))
    }
}
