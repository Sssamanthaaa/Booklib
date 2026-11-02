import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var sessions: [ReadingSession]
    @Query private var books: [Book]
    @AppStorage("dailyGoalMinutes") private var goal = 30

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.navy.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.section) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stats").pageTitle()
                            Text("Gentle numbers, no guilt.").font(.system(size: 15)).foregroundStyle(Theme.muted).padding(.horizontal, 4)
                        }
                        VStack(spacing: Space.card) {
                            streakCard
                            hoursCard
                            weekCard
                            goalCard
                        }
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.vertical, Space.gutter)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Streak", systemImage: "bolt.fill").font(.system(size: 15, weight: .semibold))
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(ReadingStats.streak(sessions))").font(.system(size: 88, weight: .medium))
                Text("days").font(.system(size: 18, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            WeekStrip(days: ReadingStats.week(sessions))
        }
        .card(Theme.mint)
    }

    private var hoursCard: some View {
        let hours = (Double(ReadingStats.totalMinutes(sessions)) / 60 * 10).rounded() / 10
        return VStack(spacing: 12) {
            Text("Time read").font(.system(size: 15, weight: .semibold))
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(hours.formatted()).font(.system(size: 88, weight: .medium))
                Text("hrs").font(.system(size: 18, weight: .semibold))
            }
            Divider().overlay(Theme.ink.opacity(0.15))
            HStack {
                tile("Pages", "\(ReadingStats.totalPages(sessions))")
                tile("Sessions", "\(sessions.count)")
                tile("Finished", "\(books.filter { $0.status == .finished }.count)")
            }
        }
        .frame(maxWidth: .infinity)
        .card(Theme.lime)
    }

    private func tile(_ label: String, _ value: String) -> some View {
        VStack(spacing: 0) {
            Text(label).font(.system(size: 13)).opacity(0.7)
            Text(value).font(.system(size: 26, weight: .bold))
        }
        .frame(maxWidth: .infinity)
    }

    private var weekCard: some View {
        let days = ReadingStats.week(sessions)
        let top = max(30, days.map(\.minutes).max() ?? 0)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Last 7 days", systemImage: "waveform.path.ecg").font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("minutes").font(.system(size: 13)).opacity(0.7)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days) { d in
                    VStack(spacing: 4) {
                        Text(d.minutes > 0 ? "\(d.minutes)" : "").font(.system(size: 10, weight: .semibold))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.ink)
                            .frame(height: max(3, 110 * CGFloat(d.minutes) / CGFloat(top)))
                        Text(d.letter).font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150, alignment: .bottom)
        }
        .card(Theme.pink)
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Daily goal", systemImage: "scope").font(.system(size: 15, weight: .semibold))
            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(goal)").font(.system(size: 64, weight: .medium))
                    Text("min").font(.system(size: 18, weight: .semibold))
                }
                Spacer()
                Button { goal = max(5, goal - 5) } label: { Image(systemName: "minus").frame(width: 46, height: 46).background(Theme.ink, in: Circle()).foregroundStyle(Theme.pink) }
                Button { goal = min(180, goal + 5) } label: { Image(systemName: "plus").frame(width: 46, height: 46).background(Theme.ink, in: Circle()).foregroundStyle(Theme.pink) }
            }
            Text("Small goals build real habits.").font(.system(size: 13)).opacity(0.75)
        }
        .card(Theme.blue)
    }
}
