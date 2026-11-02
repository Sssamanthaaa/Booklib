# Margin for iPhone (SwiftUI)

Native iOS version of Margin. The web app in the repo root is the design and behaviour reference.

> **Status: first draft, never compiled.** These files were written on a Windows machine without Xcode.
> Expect a round of compile fixes and visual tuning the first time they are built.

## Goals

- Same look as the web app: navy background, pastel cards (mint, lime, pink, blue), one sans font, 16 / 10 / 22 spacing.
- Same features: countdown sessions, chapter notes, story timeline, recap, shelves, forgiving streak, stats.
- Then the things only native can do: Live Activity timer, widgets, reminders, ISBN scan, iCloud sync.

## Requirements

- A Mac with Xcode 15 or later (SwiftData and `sensoryFeedback` need iOS 17).
- iPhone on iOS 17 or later, with Developer Mode on (Settings > Privacy & Security > Developer Mode).
- A free Apple ID is enough to run on your own phone (the build expires after 7 days).
  The paid Apple Developer Program ($99/year) is needed for TestFlight, the App Store, CloudKit sync and some Live Activity / widget setup.

## First-time setup (about 10 minutes)

1. Clone the repo on the Mac.
2. Xcode > **File > New > Project > iOS > App**.
   - Product Name: `Margin`, Interface: **SwiftUI**, Language: **Swift**, Storage: **None**, Testing: optional.
   - Save it inside this repo at `ios/` (so you get `ios/Margin.xcodeproj` next to the `Margin/` source folder).
3. Delete the generated `MarginApp.swift`, `ContentView.swift` and any `Item.swift`.
4. Drag the `ios/Margin/App`, `Design`, `Model` and `Views` folders into the Xcode project navigator.
   Choose **Create groups** and tick the `Margin` target.
5. Set **Minimum Deployments** to iOS 17.0 (target > General).
6. Pick your iPhone as the run destination, then **Run**.
   First run: trust the developer certificate on the phone (Settings > General > VPN & Device Management).

## Source map

| File | What it does | Web app equivalent |
|---|---|---|
| `App/MarginApp.swift` | App entry, SwiftData container | `load()` / `save()` |
| `Design/Theme.swift` | Colours, spacing, `.card()`, pill buttons, progress bar | the CSS variables and `.tcard` |
| `Model/Models.swift` | `Book`, `Note`, `StoryCharacter`, `ReadingSession` (SwiftData) | the `db` object |
| `Model/Seed.swift` | First-launch data (East of Eden, estimated page 80) | `seed()` |
| `Model/ReadingStats.swift` | Forgiving streak, weekly strip, totals, stable hash | `streak()`, `weekStrip()` |
| `Views/RootView.swift` | Tab bar: Today, Library, Stats | bottom nav |
| `Views/TodayView.swift` | Streak card, reading shelf, start button, recap | `home()` |
| `Views/LibraryView.swift` | Shelves of spines, add-a-book form | `library()` |
| `Views/BookArt.swift` | Face-out covers and typographic spines | `coverBtn()`, `sshelf()` |
| `Views/BookDetailView.swift` | Book page, recap, notes by chapter, timeline, characters | `bookView()` |
| `Views/SessionView.swift` | Countdown timer, page and chapter steppers, finish sheet | `session()` |
| `Views/StatsView.swift` | Streak, hours, last 7 days, daily goal | `stats()` |

## Data model notes

- `chapter == 0` means "not set / unsorted" (the web app used `null`).
- A plot event is a `Note` with `type == .event`; the timeline is built from those.
- The "where did you leave off" line is saved as both `book.leftOff` and an event on the timeline.
- `StoryCharacter` is named that because `Character` is already a Swift type.
- Spine styles use `StableHash`, not `hashValue`, because Swift's `hashValue` changes on every launch.
- The daily goal lives in `@AppStorage("dailyGoalMinutes")` (default 30).

## Roadmap

| # | Milestone | Notes |
|---|---|---|
| 0 | **Build and run the draft** | Fix compile errors, check each screen against the web app |
| 1 | Visual tuning | Spine lettering and sizes, shelf heights, card spacing on real devices, light/dark status bar |
| 2 | Persist session state | Survive the app being killed mid-session (store `startedAt`, `accumulated`, `resumedAt`) |
| 3 | **Live Activity** | ActivityKit + a widget extension. Use `Text(timerInterval:)` so the countdown runs on the lock screen and Dynamic Island with no updates. |
| 4 | YouTube read-aloud | `WKWebView` with the IFrame API. Port the play/pause to timer sync and the saved position. The audio still stops when the screen locks. |
| 5 | Add by ISBN | `DataScannerViewController` (VisionKit) to scan the barcode, then fetch title, author and pages from Open Library |
| 6 | Reminders | Local notification at a time you pick; skip it if today's goal is already met |
| 7 | Widget | Streak and today's minutes (needs an App Group to share data with the widget) |
| 8 | iCloud sync | SwiftData + CloudKit (paid developer account); make all model properties optional or defaulted first |
| 9 | Export | Markdown / JSON export of notes and timeline |
| 10 | Ship | App icon, privacy details, TestFlight, then App Store review |

## Parity checklist (web app features)

- [x] Countdown from daily goal, then bonus time (drafted)
- [x] Page and chapter steppers in session (drafted)
- [x] Notes, quotes, plot events, characters (drafted)
- [x] Notes grouped by chapter; story timeline with "you are here" (drafted)
- [x] Recap card (drafted)
- [x] Reading / Want to read / Finished shelves, add-a-book (drafted)
- [x] Forgiving streak, week strip, stats (drafted)
- [ ] Phone-free mode (dim screen; idle timer is already kept off during sessions)
- [ ] YouTube read-aloud link
- [ ] "Why I want to read it" shown on a want-to-read book (stored, displayed on the book page)
- [ ] Reset all data
- [ ] Desktop frame (not applicable on iPhone)

## Things to watch for when first building

- `SpineView` rotates text with `rotationEffect`; sizing may need adjusting so titles do not clip.
- `UnevenRoundedRectangle` and `presentationBackground` need iOS 16.4 / 17, so keep the deployment target at 17.
- `Text + Text` concatenation is used once in the timeline; if it warns, switch to an `HStack`.
- Navigation uses `NavigationStack(path:)` with `Book` as the value. If SwiftData complains about `Hashable`, navigate by `persistentModelID` instead.
- Only add `Info.plist` entries as features need them (camera usage for ISBN scan, notifications for reminders).

## Decisions and open questions

- Local-first with SwiftData now. Sync is a later opt-in (CloudKit), not a custom backend.
- Keep one codebase for iPhone; iPad layout is out of scope for now.
- Open question: should the YouTube feature stay, given the lock-screen limit, or be replaced by "audiobook you own" playback?
