import SwiftUI
import Charts

/// Per-model usage breakdown.
struct ModelBreakdownView: View {
    let data: [MetricsStore.ModelBreakdown]

    var body: some View {
        if data.isEmpty {
            Text("No model usage data")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Top Models by Token Usage")
                    .font(.headline)

                Chart(data.prefix(10)) { item in
                    BarMark(
                        x: .value("Tokens", item.totalTokens),
                        y: .value("Model", item.modelId.replacingOccurrences(of: "nvidia/", with: ""))
                    )
                    .foregroundStyle(.nvidiaGreen)
                    .opacity(0.8)
                    .annotation(position: .trailing) {
                        Text("\(item.requestCount) req")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: CGFloat(min(data.count, 10)) * 28 + 20)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
            }
        }
    }
}
