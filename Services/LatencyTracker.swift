import Foundation

/// Measures latency metrics for a single streaming request.
///
/// Call `start()` when the request is sent, `recordFirstToken()` when the
/// first token arrives, and `finish()` when the stream completes.
final class LatencyTracker {
    private(set) var requestStart: Date?
    private(set) var firstTokenTime: Date?
    private(set) var endTime: Date?

    func start() {
        requestStart = .now
        firstTokenTime = nil
        endTime = nil
    }

    func recordFirstToken() {
        guard firstTokenTime == nil else { return }
        firstTokenTime = .now
    }

    func finish() {
        endTime = .now
    }

    /// Time-to-first-token in milliseconds.
    var timeToFirstTokenMs: Double {
        guard let requestStart, let firstTokenTime else { return 0 }
        return firstTokenTime.timeIntervalSince(requestStart) * 1000
    }

    /// Total response time in milliseconds.
    var totalResponseTimeMs: Double {
        guard let requestStart, let endTime else { return 0 }
        return endTime.timeIntervalSince(requestStart) * 1000
    }

    /// Tokens generated per second, based on output token count and generation time.
    func tokensPerSecond(outputTokens: Int) -> Double {
        guard let firstTokenTime, let endTime, outputTokens > 0 else { return 0 }
        let generationSeconds = endTime.timeIntervalSince(firstTokenTime)
        guard generationSeconds > 0 else { return 0 }
        return Double(outputTokens) / generationSeconds
    }
}
