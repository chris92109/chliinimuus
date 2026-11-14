import Foundation

/// The age of a person at a given moment, both as an exact breakdown
/// (e.g. 34 years, 2 months, 5 days) and as totals in each unit.
struct Age: Equatable {
    // Exact breakdown
    let years: Int
    let months: Int
    let days: Int

    // Totals
    let totalMonths: Int
    let totalWeeks: Int
    let totalDays: Int

    /// Days left over after counting full weeks (totalDays = totalWeeks * 7 + remainingDaysAfterWeeks).
    let remainingDaysAfterWeeks: Int

    /// Days until the next birthday (0 means today is the birthday).
    let daysUntilNextBirthday: Int

    /// Age in years including the fraction of the current year, e.g. 36.4.
    let decimalYears: Double

    /// Decimal years with one digit, rounded down so it never shows the
    /// next full year before the birthday (e.g. 0.99 → "0.9").
    var decimalYearsText: String {
        (floor(decimalYears * 10) / 10).formatted(.number.precision(.fractionLength(1)))
    }

    var isBirthdayToday: Bool { daysUntilNextBirthday == 0 && totalDays > 0 }

    /// Returns nil if the birth date lies in the future.
    init?(birthDate: Date, now: Date = .now, calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: birthDate)
        let end = calendar.startOfDay(for: now)
        guard start <= end else { return nil }

        let breakdown = calendar.dateComponents([.year, .month, .day], from: start, to: end)
        years = breakdown.year ?? 0
        months = breakdown.month ?? 0
        days = breakdown.day ?? 0

        totalMonths = calendar.dateComponents([.month], from: start, to: end).month ?? 0
        totalDays = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        totalWeeks = totalDays / 7
        remainingDaysAfterWeeks = totalDays % 7

        // Next birthday: birth date shifted by (years + 1) years, or today if it matches.
        let lastBirthday = calendar.date(byAdding: .year, value: years, to: start) ?? end
        let nextBirthday = calendar.date(byAdding: .year, value: years + 1, to: start) ?? end
        if calendar.isDate(lastBirthday, inSameDayAs: end) {
            daysUntilNextBirthday = 0
        } else {
            daysUntilNextBirthday = calendar.dateComponents([.day], from: end, to: nextBirthday).day ?? 0
        }

        // Fraction of the current year: days since last birthday / days in this birthday-year.
        let daysSinceBirthday = calendar.dateComponents([.day], from: lastBirthday, to: end).day ?? 0
        let daysInYear = max(1, calendar.dateComponents([.day], from: lastBirthday, to: nextBirthday).day ?? 365)
        decimalYears = Double(years) + Double(daysSinceBirthday) / Double(daysInYear)
    }
}

extension Int {
    /// Number formatted with grouping separators for the current locale, e.g. 12'345.
    var grouped: String { formatted(.number.grouping(.automatic)) }
}

/// German singular/plural: `counted(3, "Tag", "Tage")` -> "3 Tage".
func counted(_ n: Int, _ one: String, _ other: String) -> String {
    "\(n.grouped) \(n == 1 ? one : other)"
}
