import SwiftUI
import SwiftData

@main
struct MarginApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Book.self, Note.self, StoryCharacter.self, ReadingSession.self])
    }
}
