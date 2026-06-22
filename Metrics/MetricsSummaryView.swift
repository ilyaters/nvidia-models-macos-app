import SwiftUI

/// Summary cards for the selected time period.
/// Uses Liquid Glass backgrounds and hierarchical SF Symbols.
struct MetricsSummaryView: View {
    let summary: MetricsStore.MetricsSummary

    var body: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Requests",
                value: "\(summary.totalRequests)",
                icon: "arrow.triangle.2.circlepath",
                color: .blue
            )
            MetricCard(
                title: "Total Tokens",
                value: formatNumber(summary.totalTokens),
                icon: "text.alignleft",
                color: .green
            )
            MetricCard(
                title: "Prompt",
                value: formatNumber(summary.totalPromptTokens),
                icon: "arrow.up",
                color: .orange
            )
            MetricCard(
                title: "Completion",
                value: formatNumber(summary.totalCompletionTokens),
                icon: "arrow.down",
                color: .purple
            )
            MetricCard(
                title: "Avg TTFT",
                value: formatMs(summary.averageTTFTMs),
                icon: "timer",
                color: .teal
            )
            MetricCard(
                title: "Avg Response",
                value: formatMs(summary.averageResponseTimeMs),
                icon: "clock",
                color: .indigo
            )
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 {
            return String(format: "%.1fM", Double(n) / 1_000_000)
        } else if n >= 1_000 {
            return String(format: "%.1fK", Double(n) / 1_000)
        }
        return "\(n)"
    }

    private func formatMs(_ ms: Double) -> String {
        if ms < 1000 {
            return String(format: "%.0fms", ms)
        } else {
            return String(format: "%.1fs", ms / 1000)
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassBackground(cornerRadius: 10)
    }
}
