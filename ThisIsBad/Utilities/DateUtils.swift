import Foundation

// MARK: - Date Utilities
// Helper functions and extensions for working with dates.
// These make common date operations easier throughout the app.

extension Date {
    // MARK: - Convenience Initializers

    /// Create a date that is a certain number of days from today
    /// - Parameter days: Number of days from today (negative for past dates)
    /// - Returns: The calculated date, or current date if calculation fails
    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    // MARK: - Computed Properties

    /// Check if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if this date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Check if this date is in the past (before today)
    var isPast: Bool {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return self < startOfToday
    }

    /// Get the start of the day (midnight) for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    // MARK: - Formatting

    /// Format the date as a short string (e.g., "Jan 15")
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// Format the date as a medium string (e.g., "January 15, 2024")
    var mediumFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    /// Format the date relative to today (e.g., "Today", "Tomorrow", "In 3 days")
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Calendar Extensions

extension Calendar {
    /// Calculate the number of days between two dates
    /// - Parameters:
    ///   - from: The start date
    ///   - to: The end date
    /// - Returns: Number of days between the dates (can be negative)
    func daysBetween(from: Date, to: Date) -> Int {
        let fromStart = startOfDay(for: from)
        let toStart = startOfDay(for: to)
        let components = dateComponents([.day], from: fromStart, to: toStart)
        return components.day ?? 0
    }
}
