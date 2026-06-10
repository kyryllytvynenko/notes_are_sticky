// Draws the app icon (pink folded sticky note with text lines) at all
// macOS iconset sizes. Run: swift Tools/generate_icon.swift <output-iconset-dir>
import AppKit

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("usage: generate_icon.swift <output-iconset-dir>\n".utf8))
    exit(1)
}
let outDir = URL(fileURLWithPath: args[1])
try? FileManager.default.removeItem(at: outDir)
try! FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let pink = NSColor(srgbRed: 255 / 255, green: 101 / 255, blue: 163 / 255, alpha: 1)
let foldBack = NSColor(srgbRed: 0xC2 / 255, green: 0x3D / 255, blue: 0x77 / 255, alpha: 1)
let foldLift = NSColor(srgbRed: 0xFF / 255, green: 0x8F / 255, blue: 0xBD / 255, alpha: 0.45)

func render(_ pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    let s = CGFloat(pixels)
    // Apple icon grid: ~824/1024 body with transparent margin around it.
    let margin = s * 100 / 1024
    let body = NSRect(x: margin, y: margin, width: s - 2 * margin, height: s - 2 * margin)
    let w = body.width
    let h = body.height
    let squircle = NSBezierPath(roundedRect: body, xRadius: w * 0.2237, yRadius: w * 0.2237)
    pink.setFill()
    squircle.fill()
    squircle.addClip()

    // Folded bottom-right corner: dark back side + subtle lift above the crease.
    let back = NSBezierPath()
    back.move(to: NSPoint(x: body.maxX - 0.32 * w, y: body.minY))
    back.line(to: NSPoint(x: body.maxX, y: body.minY + 0.32 * h))
    back.line(to: NSPoint(x: body.maxX, y: body.minY))
    back.close()
    foldBack.setFill()
    back.fill()

    let lift = NSBezierPath()
    lift.move(to: NSPoint(x: body.maxX - 0.32 * w, y: body.minY))
    lift.line(to: NSPoint(x: body.maxX, y: body.minY + 0.32 * h))
    lift.line(to: NSPoint(x: body.maxX - 0.32 * w, y: body.minY + 0.32 * h))
    lift.close()
    foldLift.setFill()
    lift.fill()

    // Three "text" lines, fading downward. Fractions measured from body top.
    let lines: [(width: CGFloat, top: CGFloat, alpha: CGFloat)] = [
        (0.52, 0.24, 0.92),
        (0.44, 0.40, 0.75),
        (0.34, 0.56, 0.55),
    ]
    let lineH = 0.07 * h
    for line in lines {
        let rect = NSRect(
            x: body.minX + 0.18 * w,
            y: body.maxY - line.top * h - lineH,
            width: line.width * w,
            height: lineH
        )
        NSColor.white.withAlphaComponent(line.alpha).setFill()
        NSBezierPath(roundedRect: rect, xRadius: lineH / 2, yRadius: lineH / 2).fill()
    }

    return rep
}

let variants: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for variant in variants {
    let rep = render(variant.px)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: outDir.appendingPathComponent("\(variant.name).png"))
}
print("Wrote \(variants.count) PNGs to \(outDir.path)")
