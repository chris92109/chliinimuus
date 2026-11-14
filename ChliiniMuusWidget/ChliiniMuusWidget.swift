import SwiftUI
import WidgetKit

// MARK: - Timeline

struct AgeEntry: TimelineEntry {
    let date: Date
    let profile: ProfileStore.Profile?
    var background: UIImage? = nil

    var age: Age? {
        profile.flatMap { Age(birthDate: $0.birthDate, now: date) }
    }
}

struct AgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> AgeEntry {
        AgeEntry(date: .now, profile: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (AgeEntry) -> Void) {
        let profile = ProfileStore.load() ?? (context.isPreview ? .sample : nil)
        completion(AgeEntry(date: .now, profile: profile, background: BackgroundImageStore.load()))
    }

    /// One entry now, then one at every midnight for the next 14 days,
    /// so the day count rolls over exactly at the start of each day.
    func getTimeline(in context: Context, completion: @escaping (Timeline<AgeEntry>) -> Void) {
        let profile = ProfileStore.load()
        let background = BackgroundImageStore.load()
        let calendar = Calendar.current
        let now = Date.now
        var entries = [AgeEntry(date: now, profile: profile, background: background)]

        var midnight = calendar.startOfDay(for: now)
        for _ in 0..<14 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: midnight) else { break }
            midnight = next
            entries.append(AgeEntry(date: midnight, profile: profile, background: background))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

extension ProfileStore.Profile {
    static let sample = ProfileStore.Profile(
        name: "Mia",
        birthDate: Calendar.current.date(byAdding: .day, value: -4321, to: .now)!
    )
}

// MARK: - Views

struct ChliiniMuusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AgeEntry

    var body: some View {
        WidgetContentView(family: family, profile: entry.profile, date: entry.date)
    }
}


// MARK: - Widget

struct ChliiniMuusWidget: Widget {
    let kind = "ChliiniMuusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AgeProvider()) { entry in
            ChliiniMuusWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground(image: entry.background)
                }
        }
        .configurationDisplayName("Alter in Tagen")
        .description("Zeigt, wie viele Tage alt jemand ist.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

#Preview(as: .systemSmall) {
    ChliiniMuusWidget()
} timeline: {
    AgeEntry(date: .now, profile: .sample)
}

#Preview(as: .systemMedium) {
    ChliiniMuusWidget()
} timeline: {
    AgeEntry(date: .now, profile: .sample)
}
