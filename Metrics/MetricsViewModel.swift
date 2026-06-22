import Foundation
import SwiftUI
import SwiftData
import Observation

/// View model for the metrics dashboard.
@MainActor
@Observable
final class MetricsViewModel {
    private var metricsStore: MetricsStore?

    var selectedPeriod: Period = .week
    var summary: MetricsStore.MetricsSummary?
    var modelBreakdown: [MetricsStore.ModelBreakdown] = []
    var dailyUsage: [MetricsStore.DailyUsage] = []

    enum Period: String, CaseIterable, Identifiable {
        case today = "Today"
        case week = "Week"
        case month = "Month"
        case all = "All Time"

        var id: String { rawValue }

        var since: Date {
            switch self {
            case .today: .startOfToday
            case .week: .daysAgo(7)
            case .month: .daysAgo(30)
            case .all: .distantPast
            }
        }
    }

    func configure(modelContext: ModelContext) {
        metricsStore = MetricsStore(modelContext: modelContext)
        refresh()
    }

    func refresh() {
        guard let store = metricsStore else { return }
        let since = selectedPeriod.since
        summary = store.summary(since: since)
        modelBreakdown = store.modelBreakdown(since: since)
        dailyUsage = store.dailyUsage(since: since)
    }
}
