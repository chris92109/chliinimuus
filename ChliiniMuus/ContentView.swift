import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var profile: ProfileStore.Profile? = ProfileStore.load()
    @State private var showingSettings = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    // Re-render once a minute so the numbers roll over at midnight.
                    TimelineView(.everyMinute) { context in
                        AgeDetailView(profile: profile, now: context.date)
                    }
                } else {
                    ContentUnavailableView {
                        Label("Kein Geburtstag erfasst", systemImage: "birthday.cake")
                    } description: {
                        Text("Gib einen Namen und ein Geburtsdatum ein, um das Alter zu sehen.")
                    } actions: {
                        Button("Geburtstag erfassen") { showingSettings = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(initial: profile) { newProfile in
                ProfileStore.save(newProfile)
                profile = newProfile
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { profile = ProfileStore.load() }
        }
    }

    private var title: String {
        guard let name = profile?.name, !name.isEmpty else { return "Alter" }
        return name
    }
}

struct AgeDetailView: View {
    let profile: ProfileStore.Profile
    let now: Date

    var body: some View {
        ScrollView {
            if let age = Age(birthDate: profile.birthDate, now: now) {
                VStack(spacing: 16) {
                    header(age)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(value: age.decimalYearsText, unit: "Jahre", icon: "calendar")
                        StatCard(value: age.totalMonths.grouped, unit: "Monate", icon: "calendar.badge.clock")
                        StatCard(value: age.totalWeeks.grouped, unit: "Wochen", icon: "7.square")
                        StatCard(value: age.totalDays.grouped, unit: "Tage", icon: "sun.max", highlighted: true)
                    }

                    birthdayInfo(age)
                }
                .padding()
            } else {
                ContentUnavailableView("Geburtsdatum liegt in der Zukunft",
                                       systemImage: "exclamationmark.triangle",
                                       description: Text("Wähle ein Geburtsdatum in der Vergangenheit."))
                    .padding(.top, 60)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func header(_ age: Age) -> some View {
        VStack(spacing: 6) {
            Text("Genaues Alter")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(verbatim: "\(counted(age.years, "Jahr", "Jahre")), \(counted(age.months, "Monat", "Monate")), \(counted(age.days, "Tag", "Tage"))")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(verbatim: "oder \(counted(age.totalWeeks, "Woche", "Wochen")) und \(counted(age.remainingDaysAfterWeeks, "Tag", "Tage"))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func birthdayInfo(_ age: Age) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "birthday.cake.fill")
                .font(.title2)
                .foregroundStyle(.pink)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "Geboren am \(profile.birthDate.formatted(date: .long, time: .omitted))")
                    .font(.subheadline.weight(.medium))
                Text(verbatim: age.isBirthdayToday
                     ? "Alles Gute zum Geburtstag! 🎉"
                     : "Nächster Geburtstag in \(counted(age.daysUntilNextBirthday, "Tag", "Tagen"))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StatCard: View {
    let value: String
    let unit: LocalizedStringKey
    let icon: String
    var highlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(highlighted ? Color.white : Color.accentColor)
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text(unit)
                .font(.subheadline)
                .foregroundStyle(highlighted ? Color.white.opacity(0.85) : Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .foregroundStyle(highlighted ? Color.white : Color.primary)
        .background(
            highlighted ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(.background),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

#Preview {
    AgeDetailView(profile: .init(name: "Mia",
                                 birthDate: Calendar.current.date(byAdding: .day, value: -4321, to: .now)!),
                  now: .now)
}
