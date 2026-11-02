import SwiftUI
import SwiftData

/// The reading session: countdown from the daily goal, then bonus time counting up.
/// Timer maths is timestamp based (accumulated + now - resumedAt) so it never drifts.
struct SessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let book: Book
    let goalMinutes: Int

    @State private var accumulated: TimeInterval = 0
    @State private var resumedAt: Date? = .now          // nil = paused
    @State private var page: Int
    @State private var chapter: Int
    @State private var goalReached = false
    @State private var sheet: SessionSheet?
    private let startPage: Int

    private enum SessionSheet: Identifiable {
        case note(NoteType), character, finish, recap
        var id: String {
            switch self {
            case .note(let t): "note-\(t.rawValue)"
            case .character: "character"
            case .finish: "finish"
            case .recap: "recap"
            }
        }
    }

    init(book: Book, goalMinutes: Int) {
        self.book = book
        self.goalMinutes = goalMinutes
        self.startPage = book.page
        _page = State(initialValue: book.page)
        _chapter = State(initialValue: max(1, book.chapter))
    }

    private var target: TimeInterval { TimeInterval(goalMinutes * 60) }
    private func elapsed(at now: Date) -> TimeInterval { accumulated + (resumedAt.map { now.timeIntervalSince($0) } ?? 0) }

    var body: some View {
        ZStack {
            Theme.navy.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Space.card) {
                    TimelineView(.periodic(from: .now, by: 0.5)) { ctx in timerCard(elapsed: elapsed(at: ctx.date)) }
                    pagesCard
                    statsCard
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.gutter)
            }
        }
        .safeAreaInset(edge: .bottom) { controls }
        .sensoryFeedback(.success, trigger: goalReached)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }     // keep the screen on while reading
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if !goalReached, elapsed(at: .now) >= target { goalReached = true }
            }
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .note(let type): NoteComposer(book: book, page: page, chapter: chapter, type: type)
            case .character: CharacterComposer(book: book, chapter: chapter)
            case .recap: RecapView(book: book).padding(24).presentationDetents([.medium]).presentationBackground(Theme.pink).foregroundStyle(Theme.ink)
            case .finish: FinishSheet(page: page, chapter: chapter, maxPage: book.pages) { p, c, left in finish(page: p, chapter: c, leftOff: left) }
            }
        }
    }

    // MARK: Cards

    private func timerCard(elapsed e: TimeInterval) -> some View {
        let remaining = target - e
        let secs = Int(abs(remaining))
        let fraction = target > 0 ? e / target : 0
        return VStack(spacing: 4) {
            HStack {
                Text(book.title).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                Spacer()
            }
            Text(String(format: "%02d:%02d:%02d", secs / 3600, (secs % 3600) / 60, secs % 60))
                .font(.system(size: 64, weight: .medium)).monospacedDigit()
                .foregroundStyle(remaining < 0 ? Color(hex: "0B6A50") : Theme.ink)
                .padding(.top, 8)
            HStack { ForEach(["H", "M", "S"], id: \.self) { Text($0).frame(maxWidth: .infinity) } }
                .font(.system(size: 12, weight: .semibold)).tracking(1.2)
            HStack(spacing: 0) {
                dot(on: fraction >= 1.0 / 3)
                line
                dot(on: fraction >= 2.0 / 3)
                line
                Image(systemName: "checkmark").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.mint).frame(width: 32, height: 32)
                    .background(Theme.ink.opacity(fraction >= 1 ? 1 : 0.25), in: Circle())
            }
            .padding(.top, 14)
            Text(resumedAt == nil ? "Paused" : remaining >= 0 ? "left of your \(goalMinutes) min goal" : "Goal reached. Bonus time!")
                .font(.system(size: 13, weight: .medium)).opacity(0.75).padding(.top, 6)
        }
        .card(Theme.mint)
    }

    private func dot(on: Bool) -> some View {
        Circle().fill(Theme.ink.opacity(on ? 1 : 0.25)).frame(width: 16, height: 16)
    }
    private var line: some View {
        Rectangle().fill(Theme.ink.opacity(0.18)).frame(height: 2).padding(.horizontal, 8)
    }

    private var pagesCard: some View {
        VStack(spacing: 2) {
            Text("Pages this session").font(.system(size: 15, weight: .semibold))
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("+\(max(0, page - startPage))").font(.system(size: 88, weight: .medium)).monospacedDigit()
                Text("pp").font(.system(size: 18, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .card(Theme.lime)
    }

    private var statsCard: some View {
        TimelineView(.periodic(from: .now, by: 5)) { ctx in
            let hours = max(elapsed(at: ctx.date), 60) / 3600
            let covered = max(0, page - startPage)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "waveform.path.ecg").foregroundStyle(Theme.pink)
                        .frame(width: 34, height: 34).background(Theme.ink, in: Circle())
                    Text("Statistics & details").font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Button("Recap") { sheet = .recap }.buttonStyle(OutlinePill())
                }
                stepperRow("NOW AT: PAGE \(page)", minus: { page = max(0, page - 1) }, plus: { page = min(book.pages, page + 1) }, big: { page = min(book.pages, page + 10) })
                stepperRow("CHAPTER \(chapter)", minus: { chapter = max(1, chapter - 1) }, plus: { chapter += 1 }, big: nil)
                Divider().overlay(Theme.ink.opacity(0.15))
                HStack {
                    stat("Covered", "\(covered)", "pp")
                    stat("Speed", String(format: "%.1f", Double(covered) / hours), "pp/h")
                    stat("Left", "\(max(0, book.pages - page))", "pp")
                }
                HStack(spacing: 8) {
                    quick("Note", "pencil") { sheet = .note(.note) }
                    quick("Quote", "quote.opening") { sheet = .note(.quote) }
                }
                HStack(spacing: 8) {
                    quick("Event", "flag") { sheet = .note(.event) }
                    quick("Character", "person") { sheet = .character }
                }
            }
            .card(Theme.pink)
        }
    }

    private func stepperRow(_ title: String, minus: @escaping () -> Void, plus: @escaping () -> Void, big: (() -> Void)?) -> some View {
        HStack(spacing: 6) {
            Text(title).font(.system(size: 18, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            roundButton("−", minus)
            roundButton("+", plus)
            if let big { roundButton("+10", big) }
        }
    }

    private func roundButton(_ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 14, weight: .bold)).frame(minWidth: 38, minHeight: 38)
                .padding(.horizontal, 4).background(Theme.ink, in: Capsule()).foregroundStyle(Theme.pink)
        }
    }

    private func stat(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(.system(size: 13)).opacity(0.7)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.system(size: 26, weight: .bold))
                Text(unit).font(.system(size: 13)).opacity(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func quick(_ label: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon).font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity).padding(.vertical, 11)
                .background(Theme.ink, in: Capsule()).foregroundStyle(.white)
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack {
            controlButton("play.fill", active: resumedAt == nil) { resume() }
            controlButton("pause.fill", active: resumedAt != nil) { pause() }
            controlButton("stop.fill", active: false) { sheet = .finish }
        }
        .padding(8)
        .background(Theme.blue, in: Capsule())
        .shadow(color: .black.opacity(0.35), radius: 10, y: 8)
        .padding(.horizontal, Space.gutter)
        .padding(.bottom, 4)
    }

    private func controlButton(_ icon: String, active: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 19))
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(active ? Theme.ink : .clear, in: Capsule())
                .foregroundStyle(active ? Theme.blue : Theme.ink)
        }
    }

    private func pause() {
        guard let r = resumedAt else { return }
        accumulated += Date().timeIntervalSince(r)
        resumedAt = nil
    }
    private func resume() { if resumedAt == nil { resumedAt = .now } }

    // MARK: Saving

    private func finish(page: Int, chapter: Int, leftOff: String) {
        let minutes = max(1, Int((elapsed(at: .now) / 60).rounded()))
        let s = ReadingSession(minutes: minutes, fromPage: startPage, toPage: page)
        context.insert(s)
        s.book = book

        book.page = min(max(page, 0), book.pages)
        book.chapter = chapter
        if !leftOff.isEmpty {
            book.leftOff = leftOff
            let n = Note(type: .event, text: leftOff, chapter: chapter, page: page)   // also lands on the timeline
            context.insert(n)
            n.book = book
        }
        if book.page >= book.pages { book.status = .finished }
        try? context.save()
        dismiss()
    }
}

private struct FinishSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var page: Int
    @State var chapter: Int
    @State private var leftOff = ""
    let maxPage: Int
    let onSave: (Int, Int, String) -> Void

    init(page: Int, chapter: Int, maxPage: Int, onSave: @escaping (Int, Int, String) -> Void) {
        _page = State(initialValue: page)
        _chapter = State(initialValue: chapter)
        self.maxPage = maxPage
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Stepper("Page \(page)", value: $page, in: 0...maxPage)
                Stepper("Chapter \(chapter)", value: $chapter, in: 1...200)
                TextField("Where did you leave off? (adds to your timeline)", text: $leftOff, axis: .vertical).lineLimit(2...4)
            }
            .navigationTitle("Nice session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Keep reading") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { onSave(page, chapter, leftOff.trimmingCharacters(in: .whitespacesAndNewlines)) } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
