import SwiftUI
import WidgetKit

/// The widget's layout. Lives in Shared so the app can show the exact same
/// view as a live preview in the settings screen.
struct WidgetContentView: View {
    let family: WidgetFamily
    let profile: ProfileStore.Profile?
    let date: Date

    private var age: Age? {
        profile.flatMap { Age(birthDate: $0.birthDate, now: date) }
    }

    var body: some View {
        if let age {
            switch family {
            case .accessoryCircular: circular(age)
            case .accessoryRectangular: rectangular(age)
            case .accessoryInline: Text(verbatim: "\(displayName) · \(counted(age.totalDays, "Tag", "Tage"))")
            case .systemMedium: medium(age)
            default: small(age)
            }
        } else {
            notConfigured
        }
    }

    private var displayName: String {
        guard let name = profile?.name, !name.isEmpty else { return "Alter" }
        return name
    }

    private func small(_ age: Age) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(displayName)
                .font(.headline)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(age.totalDays.grouped)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text(verbatim: age.totalDays == 1 ? "Tag alt" : (age.isBirthdayToday ? "Tage · Geburtstag! 🎉" : "Tage alt"))
                .font(.subheadline)
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func medium(_ age: Age) -> some View {
        HStack(alignment: .center, spacing: 16) {
            small(age)
            VStack(alignment: .leading, spacing: 6) {
                row(age.decimalYearsText, "Jahre")
                row(age.totalMonths.grouped, age.totalMonths == 1 ? "Monat" : "Monate")
                row(age.totalWeeks.grouped, age.totalWeeks == 1 ? "Woche" : "Wochen")
                Divider().overlay(.white.opacity(0.4))
                // HStack rather than Label, so a Form (settings preview) doesn't restyle it.
                HStack(spacing: 6) {
                    Image(systemName: "birthday.cake.fill")
                    Text(verbatim: age.isBirthdayToday ? "Heute!" : "in \(counted(age.daysUntilNextBirthday, "Tag", "Tagen"))")
                }
                .font(.caption.weight(.medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func row(_ value: String, _ unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value).font(.headline.monospacedDigit())
            Text(verbatim: unit).font(.caption).opacity(0.85)
        }
    }

    private func circular(_ age: Age) -> some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: -2) {
                Text(age.totalDays.grouped)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(verbatim: age.totalDays == 1 ? "Tag" : "Tage").font(.caption2)
            }
            .padding(4)
        }
    }

    private func rectangular(_ age: Age) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(displayName).font(.headline).lineLimit(1)
            Text(verbatim: counted(age.totalDays, "Tag", "Tage"))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(verbatim: "\(age.decimalYearsText) Jahre")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notConfigured: some View {
        VStack(spacing: 6) {
            Image(systemName: "birthday.cake")
                .font(.title2)
            Text("Öffne die App, um einen Geburtstag zu erfassen")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(family.isAccessory ? Color.primary : Color.white)
    }
}

private extension WidgetFamily {
    var isAccessory: Bool {
        switch self {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: true
        default: false
        }
    }
}
