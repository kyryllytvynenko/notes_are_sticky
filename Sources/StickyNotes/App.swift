import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only app: no Dock icon.
        NSApp.setActivationPolicy(.accessory)
    }
}

/// Filled pink rgb(255, 101, 163) square, sized like standard menu bar icons.
/// Non-template so the system doesn't repaint it black/white.
private let menuBarIcon: NSImage = {
    // Taller transparent canvas with the square near the top nudges the icon
    // up ~1px so it lines up with neighboring menu bar icons.
    let image = NSImage(size: NSSize(width: 14, height: 16), flipped: false) { _ in
        NSColor(srgbRed: 255 / 255, green: 101 / 255, blue: 163 / 255, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 2, width: 14, height: 14), xRadius: 3, yRadius: 3).fill()
        return true
    }
    image.isTemplate = false
    return image
}()

@main
struct StickyNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = NotesStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
        } label: {
            Image(nsImage: menuBarIcon)
        }
        .menuBarExtraStyle(.window)

        Window("All Notes", id: WindowID.allNotes) {
            AllNotesView()
                .environmentObject(store)
        }
        .defaultSize(width: 780, height: 560)

        WindowGroup("Note", id: WindowID.noteEditor, for: UUID.self) { $noteID in
            if let noteID {
                NoteEditorWindow(noteID: noteID)
                    .environmentObject(store)
            }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 340, height: 400)
    }
}

enum WindowID {
    static let allNotes = "all-notes"
    static let noteEditor = "note-editor"
}

/// Bring the app forward before opening a window — as an accessory app our
/// windows would otherwise appear behind whatever app is currently active.
func activateApp() {
    NSApp.activate(ignoringOtherApps: true)
}
