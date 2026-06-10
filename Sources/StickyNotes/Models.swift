import SwiftUI
import AppKit

enum Priority: Int, Codable, CaseIterable, Identifiable, Comparable {
    case none = 0
    case someday = 1
    case soon = 2
    case urgent = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .someday: return "Someday"
        case .soon: return "Soon"
        case .urgent: return "Urgent"
        }
    }

    var colorHex: String {
        switch self {
        case .none: return "#8D8D8D"
        case .someday: return "#0090FF"
        case .soon: return "#F5A623"
        case .urgent: return "#E5484D"
        }
    }

    var color: Color { Color(hex: colorHex) }

    /// Colored dot for menu items — plain SwiftUI shapes don't render inside
    /// macOS menus, so we bake the dot into a non-template NSImage.
    var dotImage: NSImage {
        let hex = colorHex
        let image = NSImage(size: NSSize(width: 10, height: 10), flipped: false) { rect in
            NSColor(hex: hex).setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
        image.isTemplate = false
        return image
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct Project: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var colorHex: String
}

struct Note: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String = ""
    var colorHex: String = NoteColor.palette[0].hex
    var projectID: UUID? = nil
    var priority: Priority = .none
    var createdAt = Date()
    var updatedAt = Date()
    /// Set when the note is marked done; done notes live in the archive.
    var doneAt: Date? = nil

    var isDone: Bool { doneAt != nil }
}

/// Shared palette for both note colors and project colors.
struct NoteColor: Identifiable, Hashable {
    let name: String
    let hex: String
    var id: String { hex }

    static let palette: [NoteColor] = [
        .init(name: "Yellow", hex: "#FFF6A3"),
        .init(name: "Pink", hex: "#FFD3E8"),
        .init(name: "Blue", hex: "#C2E7FF"),
        .init(name: "Green", hex: "#CFF2C8"),
        .init(name: "Orange", hex: "#FFDFB0"),
        .init(name: "Purple", hex: "#E6D6FF"),
        .init(name: "Mint", hex: "#C9F0E4"),
        .init(name: "Coral", hex: "#FFCFC2"),
    ]
}

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespaces)
        if h.hasPrefix("#") { h.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}

extension NSColor {
    convenience init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespaces)
        if h.hasPrefix("#") { h.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(
            srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255,
            alpha: 1
        )
    }
}
