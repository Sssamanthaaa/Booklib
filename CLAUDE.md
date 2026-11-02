# Margin

A reading companion app: countdown reading sessions, chapter-based notes, a story timeline, typographic book-spine shelves.

**Start here:** read [HANDOFF.md](HANDOFF.md) (decisions, design system, status, next steps), then [ios/README.md](ios/README.md).

## Layout
- `index.html`, `manifest.json`, `sw.js`, `server.js`: the web prototype (behaviour and design reference). Run with `node server.js`, open http://localhost:5173.
- `ios/Margin/`: the native SwiftUI app (iOS 17+, SwiftData). First draft, not yet compiled.

## Rules
- The design system lives in `ios/Margin/Design/Theme.swift`. Use its colours and `Space` values; do not hard-code them in views. Spacing is 16 gutter / 10 between cards / 22 between sections.
- One sans font everywhere; serif/mono lettering only on book spines and covers.
- Do not invent reading history or story details; the user is mid-book (East of Eden). Ask for progress.
- Keep the web prototype intact; it is the reference.
- Build check: `xcodebuild -project ios/Margin.xcodeproj -scheme Margin -destination 'platform=iOS Simulator,name=iPhone 15' build`.
- Commit and push only when asked. Never touch saved credentials.
