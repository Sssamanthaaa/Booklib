import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Bindable var book: Book
    @AppStorage("dailyGoalMinutes") private var goal = 30

    private enum Tab: String, CaseIterable, Identifiable {
        case notes = "Notes", timeline = "Timeline", characters = "Characters", sessions = "Sessions"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .notes
    @State private var sessionBook: Book?
    @State private var composer: NoteType?
    @State private var showCharacter = false

    var body: some View {
        ZStack {
            Theme.navy.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Space.card) {
                    header
                    progress
                    recap
                    tabsCard
                }
                .padding(.horizontal, Space.gutter)
                .padding(.vertical, Space.gutter)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $sessionBook) { SessionView(book: $0, goalMinutes: goal) }
        .sheet(item: $composer) { NoteComposer(book: book, page: book.page, chapter: max(1, book.chapter), type: $0) }
        .sheet(isPresented: $showCharacter) { CharacterComposer(book: book, chapter: book.chapter) }
    }

    // MARK: Cards

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            BookCover(book: book, width: 68, height: 98)
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title).font(.system(size: 22, weight: .heavy))
                Text(book.author).font(.system(size: 13)).opacity(0.75)
                Picker("Status", selection: $book.status) {
                    ForEach(BookStatus.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .tint(Theme.ink)
                .padding(.leading, -12)
                if !book.why.isEmpty {
                    Text("“\(book.why)”").font(.system(size: 13)).italic().opacity(0.8)
                }
            }
        }
        .card(Theme.mint)
    }

    private var progress: some View {
        VStack(spacing: 8) {
            Text("Progress").font(.system(size: 15, weight: .semibold))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(book.percent)").font(.system(size: 88, weight: .medium))
                Text("%").font(.system(size: 18, weight: .semibold))
            }
            ProgressBar(value: book.progress)
            Text("\(book.chapter > 0 ? "Chapter \(book.chapter) · " : "")Page \(book.page) of \(book.pages)")
                .font(.system(size: 13)).opacity(0.75)
            if book.status != .finished {
                Button { sessionBook = book } label: { Label("Start reading · \(goal) min", systemImage: "play.fill") }
                    .buttonStyle(SolidPill()).padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .card(Theme.lime)
    }

    private var recap: some View { RecapView(book: book).card(Theme.pink) }

    private var tabsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Tab.allCases) { t in
                        Button(count(for: t)) { tab = t }
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 13).padding(.vertical, 7)
                            .background(tab == t ? Theme.ink : .clear, in: Capsule())
                            .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.5))
                            .foregroundStyle(tab == t ? Theme.mint : Theme.ink)
                    }
                }
            }
            switch tab {
            case .notes: notesList
            case .timeline: TimelineList(book: book); Button("+ Add event") { composer = .event }.buttonStyle(OutlinePill())
            case .characters: charactersList
            case .sessions: sessionsList
            }
        }
        .card(Theme.mint)
    }

    private func count(for t: Tab) -> String {
        switch t {
        case .notes: "Notes (\(book.notes.filter { $0.type != .event }.count))"
        case .timeline: "Timeline (\(book.notes.filter { $0.type == .event }.count))"
        case .characters: "Characters (\(book.characters.count))"
        case .sessions: "Sessions"
        }
    }

    // MARK: Tab content

    private var notesList: some View {
        let plain = book.notes.filter { $0.type != .event }.sorted { $0.date > $1.date }
        let groups = Dictionary(grouping: plain, by: \.chapter)
        return VStack(alignment: .leading, spacing: 4) {
            if plain.isEmpty { Text("No notes yet. Capture them mid-session with one tap.").font(.footnote).opacity(0.6) }
            ForEach(Self.ordered(Array(groups.keys), descending: true), id: \.self) { ch in
                HStack {
                    Text(ch > 0 ? "CHAPTER \(ch)" : "UNSORTED").font(.system(size: 12, weight: .heavy)).tracking(1)
                    Spacer()
                    Text("\(groups[ch]?.count ?? 0)").font(.system(size: 12, weight: .bold)).opacity(0.55)
                }
                .padding(.top, 10).padding(.bottom, 2)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.ink).frame(height: 2) }
                ForEach(groups[ch] ?? []) { n in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(n.type.label) · p.\(n.page) · \(n.date.formatted(.dateTime.month(.abbreviated).day()))")
                            .font(.system(size: 12)).opacity(0.6)
                        Text(n.text).italic(n.type == .quote)
                    }
                    .padding(.vertical, 8)
                }
            }
            HStack {
                Button("+ Note") { composer = .note }.buttonStyle(OutlinePill())
                Button("+ Quote") { composer = .quote }.buttonStyle(OutlinePill())
            }
            .padding(.top, 8)
        }
    }

    private var charactersList: some View {
        VStack(alignment: .leading, spacing: 10) {
            if book.characters.isEmpty { Text("Keep track of who's who.").font(.footnote).opacity(0.6) }
            ForEach(book.characters) { c in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(c.name)\(c.chapter > 0 ? " · from ch. \(c.chapter)" : "")").bold()
                    Text(c.detail).font(.footnote).opacity(0.75)
                }
            }
            Button("+ Add character") { showCharacter = true }.buttonStyle(OutlinePill())
        }
    }

    private var sessionsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if book.sessions.isEmpty { Text("No sessions logged.").font(.footnote).opacity(0.6) }
            ForEach(book.sessions.sorted { $0.date > $1.date }) { s in
                Text("**\(s.minutes) min** · pp.\(s.fromPage)–\(s.toPage) · \(s.date.formatted(.dateTime.month(.abbreviated).day()))")
            }
        }
    }

    /// Chapters in order, with "unsorted" (0) always last.
    static func ordered(_ keys: [Int], descending: Bool) -> [Int] {
        let nonZero = keys.filter { $0 != 0 }.sorted(by: descending ? (>) : (<))
        return nonZero + (keys.contains(0) ? [0] : [])
    }
}

// MARK: - Recap ("Previously on…")

struct RecapView: View {
    let book: Book

    var body: some View {
        let events = book.notes.filter { $0.type == .event }.sorted { $0.date < $1.date }.suffix(3)
        let notes = book.notes.filter { $0.type == .note }.sorted { $0.date < $1.date }.suffix(2)
        let people = book.characters.suffix(4)

        VStack(alignment: .leading, spacing: 6) {
            Text("PREVIOUSLY ON…").font(.system(size: 11, weight: .bold)).tracking(1.5)
            if book.page > 0 {
                Text("You're on \(book.chapter > 0 ? "chapter \(book.chapter), " : "")page \(book.page) of \(book.pages) (\(book.percent)%).")
                    .font(.footnote).opacity(0.7)
            }
            if !book.leftOff.isEmpty, !events.contains(where: { $0.text == book.leftOff }) { Text(book.leftOff) }
            if !events.isEmpty {
                Text("The story so far").font(.footnote.bold())
                ForEach(Array(events)) { e in
                    Text("– \(e.chapter > 0 ? "Ch. \(e.chapter): " : "")\(e.text)").font(.footnote)
                }
            }
            if !notes.isEmpty {
                Text("Your recent notes").font(.footnote.bold())
                ForEach(Array(notes)) { n in Text("– \(n.text)").font(.footnote) }
            }
            if !people.isEmpty {
                Text(people.map(\.name).joined(separator: " · ")).font(.footnote.weight(.semibold)).padding(.top, 4)
            }
            if book.page == 0 && book.leftOff.isEmpty && events.isEmpty && notes.isEmpty && people.isEmpty {
                Text("Nothing yet. Add notes, plot events and characters while you read and your recap builds itself.")
                    .font(.footnote).opacity(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Timeline

struct TimelineList: View {
    let book: Book

    var body: some View {
        let events = book.notes.filter { $0.type == .event }.sorted { $0.date < $1.date }
        let chapters = BookDetailView.ordered(Array(Set(events.map(\.chapter) + book.characters.map(\.chapter))), descending: false)

        VStack(alignment: .leading, spacing: 0) {
            if chapters.isEmpty {
                Text("Your story timeline builds as you read. Log a plot event during a session.").font(.footnote).opacity(0.6)
            }
            ForEach(chapters, id: \.self) { ch in
                node(title: ch > 0 ? "CHAPTER \(ch)" : "UNSORTED") {
                    ForEach(events.filter { $0.chapter == ch }) { e in
                        Text("\(e.text) ").font(.system(size: 15, weight: .medium)) + Text("p.\(e.page)").font(.caption).foregroundColor(Theme.ink.opacity(0.55))
                    }
                    let people = book.characters.filter { $0.chapter == ch }
                    if !people.isEmpty { Text("New: " + people.map(\.name).joined(separator: ", ")).font(.caption.weight(.semibold)) }
                }
            }
            if book.page > 0 {
                node(title: "YOU ARE HERE", highlight: true) {
                    Text("\(book.chapter > 0 ? "Chapter \(book.chapter), " : "")page \(book.page)").font(.system(size: 15, weight: .medium))
                }
            }
        }
    }

    private func node<Content: View>(title: String, highlight: Bool = false, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Circle().fill(highlight ? Theme.lime : Theme.ink).frame(width: 12, height: 12)
                .overlay(Circle().stroke(Theme.ink, lineWidth: highlight ? 3 : 0)).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 12, weight: .heavy)).tracking(1)
                content()
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 18)
        .overlay(alignment: .topLeading) {
            Rectangle().fill(Theme.ink.opacity(0.28)).frame(width: 2).padding(.leading, 5).padding(.top, 14)
        }
    }
}

// MARK: - Composers

extension NoteType: Identifiable { var id: String { rawValue } }

struct NoteComposer: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let page: Int
    @State private var chapter: Int
    @State private var type: NoteType
    @State private var text = ""

    init(book: Book, page: Int, chapter: Int, type: NoteType) {
        self.book = book
        self.page = page
        _chapter = State(initialValue: chapter)
        _type = State(initialValue: type)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $type) {
                    ForEach(NoteType.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                TextField(placeholder, text: $text, axis: .vertical).lineLimit(3...6)
                Stepper("Chapter \(chapter)", value: $chapter, in: 1...200)
            }
            .navigationTitle(type.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var placeholder: String {
        switch type {
        case .note: "What are you thinking?"
        case .quote: "The line that stuck with you"
        case .event: "What happened? One plot point."
        }
    }

    private func save() {
        let n = Note(type: type, text: text.trimmingCharacters(in: .whitespacesAndNewlines), chapter: chapter, page: page)
        context.insert(n)
        n.book = book
        try? context.save()
        dismiss()
    }
}

struct CharacterComposer: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let chapter: Int
    @State private var name = ""
    @State private var detail = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Who are they? One line.", text: $detail)
            }
            .navigationTitle("Add character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let c = StoryCharacter(name: name, detail: detail.isEmpty ? "No description yet" : detail, chapter: chapter)
                        context.insert(c)
                        c.book = book
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
