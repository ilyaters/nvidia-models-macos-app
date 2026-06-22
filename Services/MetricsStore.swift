import Foundation
import SwiftData

/// Persists and aggregates usage metrics via SwiftData.
@MainActor
final class MetricsStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Save

    func saveUsageRecord(
        modelId: String,
        conversationId: UUID?,
        usage: Usage?,
        latency: LatencyTracker,
        outputTokenCount: Int
    ) {
        let record = UsageRecord(
            modelId: modelId,
            conversationId: conversationId,
            promptTokens: usage?.promptTokens ?? 0,
            completionTokens: usage?.completionTokens ?? outputTokenCount,
            totalTokens: usage?.totalTokens ?? 0,
            timeToFirstTokenMs: latency.timeToFirstTokenMs,
            totalResponseTimeMs: latency.totalResponseTimeMs,
            tokensPerSecond: latency.tokensPerSecond(outputTokens: usage?.completionTokens ?? outputTokenCount)
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    // MARK: - Aggregation

    /// Summary of usage over a time period.
    struct MetricsSummary {
        let totalRequests: Int
        let totalPromptTokens: Int
        let totalCompletionTokens: Int
        let totalTokens: Int
        let averageTTFTMs: Double
        let averageResponseTimeMs: Double
        let averageTokensPerSecond: Double
    }

    func summary(since: Date) -> MetricsSummary {
        let records = fetchRecords(since: since)
        let count = records.count
        guard count > 0 else {
            return MetricsSummary(
                totalRequests: 0,
                totalPromptTokens: 0,
                totalCompletionTokens: 0,
                totalTokens: 0,
                averageTTFTMs: 0,
                averageResponseTimeMs: 0,
                averageTokensPerSecond: 0
            )
        }

        let prompt = records.reduce(0) { $0 + $1.promptTokens }
        let completion = records.reduce(0) { $0 + $1.completionTokens }
        let total = records.reduce(0) { $0 + $1.totalTokens }
        let ttft = records.reduce(0.0) { $0 + $1.timeToFirstTokenMs } / Double(count)
        let responseTime = records.reduce(0.0) { $0 + $1.totalResponseTimeMs } / Double(count)
        let tps = records.reduce(0.0) { $0 + $1.tokensPerSecond } / Double(count)

        return MetricsSummary(
            totalRequests: count,
            totalPromptTokens: prompt,
            totalCompletionTokens: completion,
            totalTokens: total,
            averageTTFTMs: ttft,
            averageResponseTimeMs: responseTime,
            averageTokensPerSecond: tps
        )
    }

    /// Per-model breakdown of usage.
    struct ModelBreakdown: Identifiable {
        var id: String { modelId }
        let modelId: String
        let requestCount: Int
        let totalTokens: Int
        let averageResponseTimeMs: Double
    }

    func modelBreakdown(since: Date) -> [ModelBreakdown] {
        let records = fetchRecords(since: since)
        let grouped = Dictionary(grouping: records, by: { $0.modelId })

        return grouped.map { modelId, recs in
            ModelBreakdown(
                modelId: modelId,
                requestCount: recs.count,
                totalTokens: recs.reduce(0) { $0 + $1.totalTokens },
                averageResponseTimeMs: recs.reduce(0.0) { $0 + $1.totalResponseTimeMs } / Double(recs.count)
            )
        }
        .sorted { $0.totalTokens > $1.totalTokens }
    }

    /// Daily token usage for charting.
    struct DailyUsage: Identifiable {
        var id: Date { date }
        let date: Date
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
    }

    func dailyUsage(since: Date) -> [DailyUsage] {
        let records = fetchRecords(since: since)
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.timestamp)
        }

        return grouped.map { day, recs in
            DailyUsage(
                date: day,
                promptTokens: recs.reduce(0) { $0 + $1.promptTokens },
                completionTokens: recs.reduce(0) { $0 + $1.completionTokens },
                totalTokens: recs.reduce(0) { $0 + $1.totalTokens }
            )
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Retention

    /// Deletes usage records older than the retention period.
    func applyRetention(days: Int) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let descriptor = FetchDescriptor<UsageRecord>(
            predicate: #Predicate { $0.timestamp < cutoff }
        )
        if let oldRecords = try? modelContext.fetch(descriptor) {
            for record in oldRecords {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }

    /// Clears all usage records.
    func clearAll() {
        let descriptor = FetchDescriptor<UsageRecord>()
        if let records = try? modelContext.fetch(descriptor) {
            for record in records {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }

    // MARK: - Export

    /// Exports all usage records as CSV.
    func exportCSV() -> String {
        let records = fetchRecords(since: .distantPast)
        var csv = "timestamp,model_id,prompt_tokens,completion_tokens,total_tokens,ttft_ms,response_ms,tokens_per_sec\n"
        for r in records {
            let row = [
                ISO8601DateFormatter().string(from: r.timestamp),
                r.modelId,
                String(r.promptTokens),
                String(r.completionTokens),
                String(r.totalTokens),
                String(format: "%.1f", r.timeToFirstTokenMs),
                String(format: "%.1f", r.totalResponseTimeMs),
                String(format: "%.1f", r.tokensPerSecond)
            ].joined(separator: ",")
            csv += row + "\n"
        }
        return csv
    }

    // MARK: - Private

    private func fetchRecords(since: Date) -> [UsageRecord] {
        let descriptor = FetchDescriptor<UsageRecord>(
            predicate: #Predicate { $0.timestamp >= since },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
