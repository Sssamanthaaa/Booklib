import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \Book.addedAt) private var books: [Book]
    @Query private var sessions: [ReadingSession]
    @AppStorage("dailyGoalMinutes") private var goal = 30

    @State private var pickedID: PersistentIdentifier?
    @State private var sessionBook: Book?
    @State private var path: [Book] = []
    @State private var showGoalPicker = false

    private var reading: [Book] { books.filter { $0.status == .reading } }
    private var selected: Book? { reading.first { $0.persistentModelID == pickedID } ?? reading.first }
    private var todayMinutes: Int { ReadingStats.minutes(on: .now, sessions) }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case ..<12: "Good morning"
        case ..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.navy.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.section) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting).pageTitle()
                            Text(todayMinutes >= goal ? "Goal met. Anything more is a bonus." : "A few quiet pages today?")
                                .font(.system(size: 15)).foregroundStyle(Theme.muted).padding(.horizontal, 4)
                        }
                        streakCard
                        readingShelf
                        if let book = selected { selectedBookCards(book) }
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.vertical, Space.gutter)
                }
            }
            .navigationDestination(for: Book.self) { BookDetailView(book: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(item: $sessionBook) { SessionView(book: $0, goalMinutes: goal) }
        .confirmationDialog("Daily reading goal", isPresented: $showGoalPicker) {
            ForEach([10, 15, 20, 30, 45, 60, 90], id: \.self) { m in
                Button("\(m) min") { goal = m }
            }
        }
    }

    // MARK: Cards

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill").foregroundStyle(Theme.pink)
                    .frame(width: 34, height: 34).background(Theme.ink, in: Circle())
                Text("\(ReadingStats.streak(sessions))-day streak").font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("rest days OK").font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.5))
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(todayMinutes)").font(.system(size: 88, weight: .medium)).monospacedDigit()
                Text("/ \(goal) min today").font(.system(size: 18, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            ProgressBar(value: Double(todayMinutes) / Double(max(goal, 1)))
            WeekStrip(days: ReadingStats.week(sessions))
        }
        .card(Theme.mint)
    }

    private var readingShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Currently reading").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.text).padding(.horizontal, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(reading) { book in
                        BookCover(book: book, selected: book.persistentModelID == selected?.persistentModelID)
                            .onTapGesture {
                                // tapping the selected cover opens its page; tapping another selects it
                                if book.persistentModelID == selected?.persistentModelID { path.append(book) }
                                else { pickedID = book.persistentModelID }
                            }
                    }
                    if reading.isEmpty {
                        Text("Nothing in progress. Pick a book from your library.")
                            .font(.system(size: 14)).foregroundStyle(Theme.muted)
                    }
                }
                .padding(.horizontal, 4).padding(.vertical, 10)
            }
        }
    }

    @ViewBuilder
    private func selectedBookCards(_ book: Book) -> some View {
        VStack(spacing: Space.card) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title).font(.system(size: 22, weight: .heavy))
                        Text("\(book.author) · page \(book.page) of \(book.pages)").font(.system(size: 13)).opacity(0.75)
                    }
                    Spacer()
                    Button("open →") { path.append(book) }.buttonStyle(OutlinePill())
                }
                ProgressBar(value: book.progress)
                Button { sessionBook = book } label: {
                    Label("Start reading · \(goal) min", systemImage: "play.fill")
                }
                .buttonStyle(SolidPill())
                Button("Change daily goal") { showGoalPicker = true }
                    .buttonStyle(OutlinePill()).frame(maxWidth: .infinity)
            }
            .card(Theme.lime)

            RecapView(book: book).card(Theme.pink)
        }
    }
}

/// Seven circles: check = read, dashed = rest day that kept the streak alive.
struct WeekStrip: View {
    let days: [ReadingStats.Day]
    var body: some View {
        HStack {
            ForEach(days) { d in
                VStack(spacing: 4) {
                    ZStack {
                        Circle().fill(d.didRead ? Theme.ink : Theme.ink.opacity(0.14))
                        if d.isRest { Circle().strokeBorder(Theme.ink, style: StrokeStyle(lineWidth: 2, dash: [3])) }
                        if d.didRead { Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.mint) }
                    }
                    .frame(width: 34, height: 34)
                    Text(d.letter).font(.system(size: 11, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
