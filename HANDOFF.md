# Handoff: Margin (reading companion app)

Written so a fresh Claude session on a Mac can pick up the iPhone build without re-deriving anything.
Everything below was true when this was written (the work was done on a Windows machine, in one long session).

## 1. What this is

**Margin** is a personal reading app for Samantha (passion project, solo-first, not monetised).
It started as an ideation conversation and became a working web prototype, then a decision to build the real thing as a **native iPhone app in SwiftUI**.

- Repo: `https://github.com/Sssamanthaaa/Booklib` (private, branch `main`)
- Web prototype (done, working): repo root. Plain HTML/CSS/JS PWA in `index.html`, run with `node server.js`.
- iPhone app (first draft, **never compiled**): `ios/`. This is the work to continue.

### The idea in one paragraph
A reading **companion** plus a **habit/focus** tool. One tap starts a countdown from your daily reading goal (default 30 min); while you read you log pages and chapter, and capture notes, quotes, plot events and characters. Everything is filed by chapter, builds a "story so far" timeline and a "Previously on..." recap for next time. You can link a YouTube read-aloud whose play/pause drives the timer. Library is a set of typographic book-spine shelves.

## 2. Decisions already made (do not re-litigate)

| Decision | Detail |
|---|---|
| Purpose | Passion project, not monetised |
| Social | Solo-first. No accounts, no social features for now |
| Core directions | Reading companion (notes, characters, recaps) **+** habit/focus (timer, streak) |
| Platform | **Native iPhone, SwiftUI + SwiftData**, iOS 17+. She has a Mac and an iPhone. |
| Data | Local-first. Sync later via CloudKit (needs the paid Apple Developer account). No custom backend. |
| Starting book | **East of Eden** by John Steinbeck, 601 pages (Penguin Classics edition), **page 80 is an estimate** ("early Part 1"). Ask her for the real page and chapter. |
| Characters pre-filled | Only spoiler-safe early characters: Adam, Charles and Cyrus Trask, Samuel Hamilton. Do not add anyone from later in the book. |
| Streak | Forgiving: one missed day in a row is a "rest day" and does not break it; two in a row breaks it |
| Daily goal | 30 min default, adjustable 5 to 180 |
| Demo data | None. She wanted her real book only. Stats start at zero (no invented history). |

## 3. Design system (must match across every screen)

She repeatedly asked for consistency ("theme is all over the place", "spacing is off"), so treat this as strict.

- **Background:** navy `#0F2236`. Tab bar `#0B1A2B`. Shelf panel `#060F19`.
- **Cards** (rounded 30pt, padding 18 vertical / 20 horizontal, text navy `#10243A`):
  mint `#B9F1E0`, lime `#C8F52F`, pink `#F9D4EC`, blue `#5DB4EE`.
- **Accent on navy:** lime `#C8F52F`. Text on navy `#E8F2F0`, titles `#F1F7F5`, muted `#8EA6BB`, lines `#2C4258`.
- **Spacing:** 16 page gutter, **10 between stacked cards**, **22 between sections**, 4 inset for headings/labels so they line up with card edges.
- **Type:** one sans-serif everywhere (system font, heavy weights for titles and big numbers). Serif/mono/Impact-style lettering appears **only** on book spines and covers.
- **Big numerals:** 88pt medium for the headline number on cards, 64pt for the timer digits.
- **Buttons:** pills. Outline pill (navy border) for small actions, solid navy pill with lime text for primary actions ("Start reading").
- Cards on the timer screen have a small navy "notch" tab at the top right where they stack (web version only so far; optional polish on iOS).
- All of this is already in `ios/Margin/Design/Theme.swift`. Add to that file rather than hard-coding colours or spacing in views.

### Reference images she liked
1. A phone UI with **timer cards**: navy background, stacked mint / lime / pink / blue cards with notches, huge `00:14:98` digits with H M S labels, milestone dots with a check, a bottom blue pill with play / pause / stop. This is the timer screen.
2. A **Colophon-style shelf**: densely packed typographic spines of different heights, widths, colours and lettering on near-black, a few leaning. This is the library shelf.
3. An earlier favourite (superseded by #2 for the library): face-out covers on translucent coloured glass shelf bars with screws. Still used for "Currently reading" on Today.

## 4. Web prototype (reference for behaviour)

Single file, ~700 lines, no build. Key functions in `index.html`: `home`, `library`, `bookView`, `session`, `stats`, `recap`, `streak`, `timelineHTML`, `sshelf` (spines), `shelf` (glass shelf), plus a YouTube IFrame API block (`AU`, `syncAudio`, `placeAudio`).

Behaviours worth copying exactly (they were tuned through feedback):
- **Timer maths:** `elapsed = accumulated + (now - resumedAt)`. Counts **down** from the goal, then **up** as bonus time with a "Goal reached" toast. Three milestone dots at 1/3, 2/3, 100%.
- **Easy start:** the big "Start reading, 30 min" button on Today and on the book page goes straight into the timer. No intermediate screen.
- **Today:** tapping the *selected* cover opens that book's page; tapping a different cover selects it. (A bug here once made tapping do nothing.)
- **Finish sheet:** asks page, chapter, and "where did you leave off". That last line becomes both `book.leftOff` and a **timeline event**.
- **Recap:** page and chapter line, last 3 events as "The story so far", last 2 notes, last 4 character names.
- **Notes tab:** grouped under "Chapter N" headings, newest chapter first, "Unsorted" last. **Timeline tab:** oldest chapter first, events + "New: characters", ending in a "You are here" marker.
- **Add book:** choose "Want to read" or "Reading now", optional "why do you want to read it" note, shown on that book's page.
- **Today has two shelves:** "Currently reading" (face-out covers) and "Up next" (want-to-read spines with a dashed "+").
- **Spines:** width from page count, height from title length, one of six lettering styles from a **stable** hash of the title, long titles get smaller type so they fit, "reading" books are lifted with a red bookmark ribbon, finished books slightly muted, some want-to-read books lean.

## 5. The iPhone code: what exists

Read `ios/README.md` first (setup steps, source map, roadmap, parity checklist). Summary:

```
ios/Margin/
  App/MarginApp.swift        entry, SwiftData container for the 4 models
  Design/Theme.swift         colours, Space, .card(), pill styles, ProgressBar
  Model/Models.swift         Book, Note, StoryCharacter, ReadingSession
  Model/Seed.swift           East of Eden on first launch
  Model/ReadingStats.swift   streak, week strip, totals, StableHash
  Views/RootView.swift       TabView: Today, Library, Stats
  Views/TodayView.swift      streak card, reading shelf, start button, recap
  Views/LibraryView.swift    shelves of spines, AddBookView
  Views/BookArt.swift        BookCover (face-out) and SpineView
  Views/BookDetailView.swift book page, RecapView, TimelineList, NoteComposer, CharacterComposer
  Views/SessionView.swift    countdown, steppers, quick-add, finish sheet
  Views/StatsView.swift      streak, hours, last 7 days, goal
```

~1,300 lines. **Status: written without Xcode, never compiled, never run.** Expect compile errors and layout problems. Treat the first job as "make it build, then make it look like the web app".

### Modelling notes
- `chapter == 0` means unset/unsorted (web used `null`).
- A plot event is a `Note` with `type == .event`; the timeline is built from those.
- `StoryCharacter`, not `Character` (clashes with Swift's `Character`).
- Spine styling uses `StableHash`, not `hashValue` (which changes every launch).
- Daily goal is `@AppStorage("dailyGoalMinutes")`.

### Known risks to check when it first builds
- `SpineView`: vertical text via `rotationEffect` may clip or mis-size. Tune on a real device.
- `NavigationStack(path:)` with `Book` as the path value. If SwiftData complains about `Hashable`, navigate by `persistentModelID`.
- `Text + Text` concatenation in `TimelineList` may warn; swap for an `HStack`.
- `NoteType: Identifiable` extension is declared in `BookDetailView.swift`; if that causes a conflict, move it to `Models.swift`.
- `UnevenRoundedRectangle`, `presentationBackground`, `sensoryFeedback` need iOS 16.4 to 17, so keep the deployment target at 17.0.

## 6. Recommended order of work

1. **Create the Xcode project** inside `ios/` (see `ios/README.md`), or generate it from the command line (see below). Bundle ID is up to Samantha.
2. **Get it compiling.** Fix errors without changing the design or data model unless something is genuinely wrong.
3. **Run in the simulator, then on her iPhone.** Compare each screen with the web app (`node server.js`, open `http://localhost:5173`, use a ~390px-wide window). Fix layout drift: spacing rules in section 3 are the acceptance test.
4. **Persist an in-progress session** across app kills (store `startedAt`, `accumulated`, `resumedAt`).
5. **Live Activity** (ActivityKit + widget extension) using `Text(timerInterval:)` so the countdown runs on the lock screen and in the Dynamic Island.
6. **Remaining parity:** phone-free mode (dim screen), reset all data, YouTube read-aloud.
7. **ISBN scan** (VisionKit `DataScannerViewController`) + Open Library lookup for title/author/pages.
8. **Reminders**, then a **widget** (needs an App Group), then **iCloud sync** (paid account), then **Markdown/JSON export**.

### Optional: generate the Xcode project from the command line
Untested idea so a Claude session on the Mac can avoid dragging files around: install XcodeGen (`brew install xcodegen`) and add `ios/project.yml` with a single iOS app target named `Margin`, sources `Margin`, deployment target iOS 17.0, `GENERATE_INFOPLIST_FILE: YES`, and a placeholder bundle ID; run `xcodegen` in `ios/`. If this is flaky, create the project in Xcode manually instead.

### Verify builds from the terminal
```bash
cd ios
xcodebuild -project Margin.xcodeproj -scheme Margin \
  -destination 'platform=iOS Simulator,name=iPhone 15' build
```
Use `xcrun simctl` to boot a simulator and launch the app; screenshots with `xcrun simctl io booted screenshot out.png`.

## 7. Open questions for Samantha

- Real **page and chapter** in East of Eden, and her edition's page count.
- Keep the **YouTube read-aloud**? Embedded YouTube stops playing when the screen locks on every platform, native included. Alternative: playback of audiobooks she owns, or drop it.
- Bundle ID / app name for the App Store, and whether she will pay the $99/year account (needed for TestFlight, CloudKit and some Live Activity setup).
- Free Apple ID builds expire after 7 days; that is fine for testing.

## 8. Things that went wrong (so they are not repeated)

- **Spacing and layout complaints came up three times.** She said "layout doesn't fit right" and "spacing is off" about different things: horizontal overflow, uneven gaps, headings not aligned with cards, dead space in shelves. Measure real positions instead of eyeballing; keep to the 16/10/22 rules.
- **Truncated spine titles** looked broken. Size spines from the title and shrink type for long titles.
- **Switching themes piecemeal** (parchment, wood, glass, then navy) left leftover styles. Keep everything in the design tokens.
- **Git push failed with 403** on the Windows machine because a *different* GitHub account's login was cached. On the Mac, make sure `git push` is using the `Sssamanthaaa` account.
- **Do not invent reading history or story details.** She is mid-book; spoilers and fake data are not welcome. Ask her for progress.
- She prefers that you act and show results, but **ask before anything that publishes or touches credentials**. When she said "noo" it was when credentials were being investigated: do not poke at her saved logins.

## 9. Working agreements

- Git identity on the original machine: name "Samantha". Commits from Claude end with the attribution trailer `Co-Authored-By: Claude <noreply@anthropic.com>` (use your own model name).
- Commit and push only when she asks.
- The web prototype stays in the repo as the reference; do not delete or restyle it unless asked.
- Keep answers concise; use plain language (she is learning native iOS coming from React).

## 10. Starter prompt to paste into Claude on the Mac

```
Read HANDOFF.md and ios/README.md. We're building the native iPhone version of Margin (SwiftUI + SwiftData, iOS 17).
The Swift in ios/ was written without Xcode and has never been compiled.
First: create the Xcode project in ios/, get it building for the simulator, and fix compile errors without changing the design.
Then run it and compare each screen with the web app in the repo root (node server.js, open localhost:5173 at ~390px wide).
Show me screenshots as you go. Ask me before committing or pushing.
```
