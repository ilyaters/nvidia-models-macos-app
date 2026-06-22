import XCTest
import SwiftData
@testable import NvidiaLLM

@MainActor
final class MetricsStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var store: MetricsStore!

    override func setUp() async throws {
        container = try ModelContainer(
            for: UsageRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        store = MetricsStore(modelContext: container.mainContext)
    }

    func testSaveAndFetchUsageRecord() {
        let latency = LatencyTracker()
        latency.start()
        Thread.sleep(forTimeInterval: 0.01)
        latency.recordFirstToken()
        Thread.sleep(forTimeInterval: 0.01)
        latency.finish()

        let usage = Usage(promptTokens: 10, completionTokens: 20, totalTokens: 30)

        store.saveUsageRecord(
            modelId: "nvidia/test-model",
            conversationId: UUID(),
            usage: usage,
            latency: latency,
            outputTokenCount: 20
        )

        let summary = store.summary(since: .daysAgo(1))
        XCTAssertEqual(summary.totalRequests, 1)
        XCTAssertEqual(summary.totalPromptTokens, 10)
        XCTAssertEqual(summary.totalCompletionTokens, 20)
        XCTAssertEqual(summary.totalTokens, 30)
        XCTAssertGreaterThan(summary.averageResponseTimeMs, 0)
    }

    func testModelBreakdown() {
        let latency = LatencyTracker()
        latency.start()
        latency.finish()

        store.saveUsageRecord(
            modelId: "nvidia/model-a",
            conversationId: nil,
            usage: Usage(promptTokens: 10, completionTokens: 20, totalTokens: 30),
            latency: latency,
            outputTokenCount: 20
        )
        store.saveUsageRecord(
            modelId: "nvidia/model-b",
            conversationId: nil,
            usage: Usage(promptTokens: 5, completionTokens: 15, totalTokens: 20),
            latency: latency,
            outputTokenCount: 15
        )
        store.saveUsageRecord(
            modelId: "nvidia/model-a",
            conversationId: nil,
            usage: Usage(promptTokens: 8, completionTokens: 12, totalTokens: 20),
            latency: latency,
            outputTokenCount: 12
        )

        let breakdown = store.modelBreakdown(since: .daysAgo(1))
        XCTAssertEqual(breakdown.count, 2)

        // model-a should be first (50 total tokens vs 20 for model-b).
        XCTAssertEqual(breakdown.first?.modelId, "nvidia/model-a")
        XCTAssertEqual(breakdown.first?.totalTokens, 50)
        XCTAssertEqual(breakdown.first?.requestCount, 2)
    }

    func testEmptySummary() {
        let summary = store.summary(since: .daysAgo(1))
        XCTAssertEqual(summary.totalRequests, 0)
        XCTAssertEqual(summary.totalTokens, 0)
    }

    func testClearAll() {
        let latency = LatencyTracker()
        latency.start()
        latency.finish()

        store.saveUsageRecord(
            modelId: "test",
            conversationId: nil,
            usage: Usage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
            latency: latency,
            outputTokenCount: 1
        )

        store.clearAll()

        let summary = store.summary(since: .distantPast)
        XCTAssertEqual(summary.totalRequests, 0)
    }

    func testExportCSV() {
        let latency = LatencyTracker()
        latency.start()
        latency.finish()

        store.saveUsageRecord(
            modelId: "test-model",
            conversationId: nil,
            usage: Usage(promptTokens: 10, completionTokens: 20, totalTokens: 30),
            latency: latency,
            outputTokenCount: 20
        )

        let csv = store.exportCSV()
        XCTAssertTrue(csv.contains("timestamp,model_id,prompt_tokens,completion_tokens,total_tokens"))
        XCTAssertTrue(csv.contains("test-model"))
        XCTAssertTrue(csv.contains("10,20,30"))
    }
}
