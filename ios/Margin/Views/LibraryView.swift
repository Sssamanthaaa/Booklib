import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \Book.addedAt) private var books: [Book]
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.navy.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.section) {
                        HStack {
                            Text("Library").pageTitle()
                            Spacer()
                            Button("+ Add book") { showAdd = true }
                                .buttonStyle(.borderedProminent).tint(Theme.lime).foregroundStyle(Theme.ink)
                                .buttonBorderShape(.capsule)
                        }
                        ForEach(BookStatus.allCases.sorted(by: Self.order), id: \.self) { status in
                            ShelfView(status: status, books: books.filter { $0.status == status })
                        }
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.vertical, Space.gutter)
                }
            }
            .navigationDestination(for: Book.self) { BookDetailView(book: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showAdd) { AddBookView() }
    }

    private static func order(_ a: BookStatus, _ b: BookStatus) -> Bool {
        let rank: [BookStatus: Int] = [.reading: 0, .want: 1, .finished: 2]
        return rank[a]! < rank[b]!
    }
}

/// One dark shelf panel of spines.
struct ShelfView: View {
    let status: BookStatus
    let books: [Book]

    private var shelfHeight: CGFloat {
        (books.map { SpineView.height(of: $0) }.max() ?? 90) + 50
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(status.label).font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(books.count) book\(books.count == 1 ? "" : "s")").font(.system(size: 13)).foregroundStyle(Theme.muted)
            }
            .foregroundStyle(Theme.text).padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(books) { book in
                        NavigationLink(value: book) { SpineView(book: book) }.buttonStyle(.plain)
                    }
                    if books.isEmpty {
                        Text(emptyText).font(.system(size: 14)).foregroundStyle(Theme.muted).padding(.bottom, 22)
                    }
                }
                .padding(.horizontal, 14).padding(.top, 20)
                .frame(minHeight: shelfHeight, alignment: .bottom)
            }
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.line).frame(height: 9)   // shelf edge
                    .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24))
            }
        }
    }

    private var emptyText: String {
        switch status {
        case .reading: "Nothing in progress"
        case .want: "Books you want to read next live here"
        case .finished: "Finished books settle here"
        }
    }
}

struct AddBookView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var books: [Book]

    @State private var status: BookStatus = .want
    @State private var title = ""
    @State private var author = ""
    @State private var pagesText = ""
    @State private var why = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Add to", selection: $status) {
                    Text("Want to read").tag(BookStatus.want)
                    Text("Reading now").tag(BookStatus.reading)
                }
                .pickerStyle(.segmented)
                Section {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Pages", text: $pagesText).keyboardType(.numberPad)
                    TextField("Why do you want to read it? (optional)", text: $why)
                }
                Text("ISBN scan and search come later.").font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("Add a book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func add() {
        let color = Theme.bookColors[books.count % Theme.bookColors.count]
        let book = Book(title: title.trimmingCharacters(in: .whitespaces),
                        author: author.isEmpty ? "Unknown" : author,
                        pages: Int(pagesText) ?? 300, status: status, colorHex: color, why: why)
        context.insert(book)
        try? context.save()
        dismiss()
    }
}
