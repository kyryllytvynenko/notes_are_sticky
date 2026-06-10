# Sticky Notes (menu bar)

A lightweight macOS menu bar replacement for the native Stickies app. Notes stay
out of your way — they live behind a menu bar icon (the pink square), not on
your desktop.

## Features

- **Menu bar popover** — preview of your top notes sorted by priority, with
  quick mark-done / delete buttons on each row, plus buttons to add a note or
  open the full view.
- **All Notes window** — grid of every note with search (matches note text and
  project names), project filter, and an Archive of done notes.
- **Note editor** — small sticky-style windows; pick a color, assign a project
  and a priority.
- **Projects** — create work types/projects with a name and dedicated color;
  notes take their project's color and show the project name on top.
- **Priority** — Urgent / Soon / Someday / None; drives sort order, shown as a
  colored tag (left stripe in the popover).
- **Done & archive** — mark notes done; they move to the archive where you can
  restore or permanently delete them.
- **Local storage** — everything is saved to
  `~/Library/Application Support/StickyNotes/notes.json`. No accounts, no cloud.

## Requirements

- macOS 14 (Sonoma) or newer
- Xcode (full install, not just Command Line Tools) to build

## Build

```sh
git clone https://github.com/kyryllytvynenko/notes_are_sticky.git
cd notes_are_sticky
./build_app.sh
```

This produces `dist/StickyNotes.app`. Try it without installing:

```sh
open dist/StickyNotes.app
```

## Install & keep it permanent

1. **Copy the app to Applications** (so it survives `dist/` cleanups and
   rebuilds):

   ```sh
   cp -R dist/StickyNotes.app /Applications/
   ```

2. **Launch it from Applications** (quit the dev copy first if it's running):

   ```sh
   pkill -x StickyNotes; open /Applications/StickyNotes.app
   ```

3. **Start it at login**: System Settings → **General** → **Login Items &
   Extensions** → under "Open at Login" press **+** and add
   `/Applications/StickyNotes.app`.

That's it — the pink square lives in your menu bar, and your notes are kept in
`~/Library/Application Support/StickyNotes/notes.json` independent of the app
binary, so reinstalling/updating the app never touches your notes.

### Updating after code changes

```sh
git pull
./build_app.sh
pkill -x StickyNotes
cp -R dist/StickyNotes.app /Applications/
open /Applications/StickyNotes.app
```

## Development

Plain Swift Package (SwiftUI, no Xcode project needed). Quick dev loop:

```sh
swift run
```

Sources live in `Sources/StickyNotes/`; `build_app.sh` wraps the release binary
into a proper `.app` bundle (menu-bar-only `LSUIElement` app, ad-hoc signed).
