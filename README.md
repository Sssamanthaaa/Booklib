# Margin

A reading companion PWA: read more, remember more.

- **Easy start:** one tap starts a countdown from your daily reading goal (default 30 min), then keeps counting as bonus time.
- **Chapter notes and story timeline:** notes, quotes, plot events and characters are filed by chapter, with a "story so far" timeline and a "Previously on..." recap.
- **Listen along:** link a YouTube read-aloud (video or playlist). The timer follows play and pause, and your position is remembered.
- **Shelves:** typographic spine shelves for Reading, Want to read and Finished.
- **Habit:** forgiving streaks (a single rest day does not break it), weekly view and simple stats.
- **Local-first:** everything is stored in your browser (`localStorage`) and works offline. No account, no backend.

## Run it locally

```bash
node server.js        # serves on http://localhost:5173
```

Or serve the folder with any static file server. It is plain HTML, CSS and JavaScript with no build step.

## Files

| File | Purpose |
|---|---|
| `index.html` | The whole app (markup, styles, scripts) |
| `manifest.json` | PWA manifest |
| `sw.js` | Service worker for offline use |
| `icon.svg` | App icon |
| `server.js` | Tiny static server for local preview |

## Notes

- Installing to a phone home screen needs the app to be served over HTTPS.
- The YouTube player is the standard embedded player: on most phones audio stops when the screen locks.
- Starter data is one book (East of Eden). Use **Stats > Reset all data** to start over.

## iPhone app

A native SwiftUI version is in progress in [ios/](ios/README.md): setup steps, source map, roadmap and parity checklist are there.
