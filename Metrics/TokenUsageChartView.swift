import SwiftUI
import Charts

/// Daily token usage bar chart.
struct TokenUsageChartView: View {
    let data: [MetricsStore.DailyUsage]

    var body: some View {
        if data.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tertiary)
                Text("No usage data for this period")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(height: 200)
        } else {
            Chart(data) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Tokens", item.totalTokens)
                )
                .foregroundStyle(.nvidiaGreen)
                .opacity(0.8)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.day().month())
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
        }
    }
}
