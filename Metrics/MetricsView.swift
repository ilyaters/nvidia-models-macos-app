import SwiftUI
import SwiftData

/// Main metrics dashboard view.
struct MetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MetricsViewModel()

    var body: some View {
        VStack(spacing: 16) {
            // Header with period selector
            HStack {
                Text("Usage Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Picker("Period", selection: $viewModel.selectedPeriod) {
                    ForEach(MetricsViewModel.Period.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                .onChange(of: viewModel.selectedPeriod) { _, _ in
                    viewModel.refresh()
                }
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)

            // Summary cards
            if let summary = viewModel.summary {
                MetricsSummaryView(summary: summary)
                    .padding(.horizontal)
            }

            Divider()

            // Charts
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Token Usage")
                            .font(.headline)
                        TokenUsageChartView(data: viewModel.dailyUsage)
                    }
                    .padding(.horizontal)

                    ModelBreakdownView(data: viewModel.modelBreakdown)
                        .padding(.horizontal)

                    // Latency stats
                    if let summary = viewModel.summary, summary.totalRequests > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Latency")
                                .font(.headline)
                            HStack(spacing: 24) {
                                LatencyStat(label: "Avg TTFT", value: summary.averageTTFTMs, unit: "ms")
                                LatencyStat(label: "Avg Response", value: summary.averageResponseTimeMs, unit: "ms")
                                LatencyStat(label: "Avg Tokens/sec", value: summary.averageTokensPerSecond, unit: "tok/s")
                            }
                            .padding()
                            .glassBackground(cornerRadius: 10)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }
}

private struct LatencyStat: View {
    let label: String
    let value: Double
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", value))
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
