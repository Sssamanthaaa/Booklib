import Foundation
import SwiftData

enum BookStatus: String, Codable, CaseIterable {
    case reading, want, finished

    var label: String {
        switch self {
        case .reading: "Reading"
        case .want: "Want to read"
        case .finished: "Finished"
        }
    }
}

enum NoteType: String, Codable, CaseIterable {
    case note, quote, event   // event = a plot point shown on the timeline

    var label: String {
        switch self {
        case .note: "Note"
        case .quote: "Quote"
        case .event: "Plot event"
        }
    }
}

@Model
final class Book {
    var title: String
    var author: String
    var pages: Int
    var page: Int
    var chapter: Int            // 0 = not set yet
    var statusRaw: String
    var colorHex: String
    var why: String             // "why I want to read it"
    var leftOff: String         // last "where did you leave off" line
    var audioVideoID: String    // YouTube read-aloud (empty = none)
    var audioPlaylistID: String
    var audioPosition: Double   // seconds
    var addedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Note.book) var notes: [Note] = []
    @Relationship(deleteRule: .cascade, inverse: \StoryCharacter.book) var characters: [StoryCharacter] = []
    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book) var sessions: [ReadingSession] = []

    var status: BookStatus {
        get { BookStatus(rawValue: statusRaw) ?? .want }
        set { statusRaw = newValue.rawValue }
    }

    var progress: Double { pages > 0 ? min(1, Double(page) / Double(pages)) : 0 }
    var percent: Int { Int((progress * 100).rounded()) }

    init(title: String, author: String, pages: Int, page: Int = 0, chapter: Int = 0,
         status: BookStatus = .want, colorHex: String, why: String = "") {
        self.title = title
        self.author = author
        self.pages = pages
        self.page = page
        self.chapter = chapter
        self.statusRaw = status.rawValue
        self.colorHex = colorHex
        self.why = why
        self.leftOff = ""
        self.audioVideoID = ""
        self.audioPlaylistID = ""
        self.audioPosition = 0
        self.addedAt = .now
    }
}

@Model
final class Note {
    var typeRaw: String
    var text: String
    var chapter: Int            // 0 = unsorted
    var page: Int
    var date: Date
    var book: Book?

    var type: NoteType {
        get { NoteType(rawValue: typeRaw) ?? .note }
        set { typeRaw = newValue.rawValue }
    }

    init(type: NoteType, text: String, chapter: Int, page: Int, date: Date = .now) {
        self.typeRaw = type.rawValue
        self.text = text
        self.chapter = chapter
        self.page = page
        self.date = date
    }
}

/// Named StoryCharacter because `Character` already means a single text character in Swift.
@Model
final class StoryCharacter {
    var name: String
    var detail: String
    var chapter: Int            // chapter they first appear in (0 = unknown)
    var book: Book?

    init(name: String, detail: String, chapter: Int = 0) {
        self.name = name
        self.detail = detail
        self.chapter = chapter
    }
}

@Model
final class ReadingSession {
    var date: Date
    var minutes: Int
    var fromPage: Int
    var toPage: Int
    var book: Book?

    init(date: Date = .now, minutes: Int, fromPage: Int, toPage: Int) {
        self.date = date
        self.minutes = minutes
        self.fromPage = fromPage
        self.toPage = toPage
    }
}
