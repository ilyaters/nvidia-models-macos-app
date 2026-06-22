import Foundation

extension Date {
    /// Formats the date as a short relative time (e.g. "2m ago", "Yesterday").
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    /// Formats the date as a short date+time string.
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Returns the start of today.
    static var startOfToday: Date {
        Calendar.current.startOfDay(for: .now)
    }

    /// Returns the date N days ago.
    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }
}
