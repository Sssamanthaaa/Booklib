import Foundation
import SwiftData

/// Starter data on first launch: just the book being read.
/// Page 80 is an estimate ("early Part 1"); adjust it in the app.
enum Seed {
    static func runIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Book>())) ?? 0
        guard existing == 0 else { return }

        let eden = Book(title: "East of Eden", author: "John Steinbeck", pages: 601, page: 80,
                        status: .reading, colorHex: "2B7A6F")
        context.insert(eden)

        let people: [(String, String)] = [
            ("Adam Trask", "Cyrus's younger son; Charles's half-brother"),
            ("Charles Trask", "Adam's older half-brother; fierce and physical"),
            ("Cyrus Trask", "Their father, a veteran with a wooden leg and big stories"),
            ("Samuel Hamilton", "Irish immigrant farmer in the Salinas Valley; the narrator's grandfather"),
        ]
        for (name, detail) in people {
            let c = StoryCharacter(name: name, detail: detail)
            context.insert(c)
            c.book = eden
        }
        try? context.save()
    }
}
