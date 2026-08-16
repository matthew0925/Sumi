#!/usr/bin/env swift

import AppKit
import Foundation

struct Arguments {
    let input: String
    let output: String
    let headline: String
    let subheadline: String

    init?(_ values: [String]) {
        func value(after flag: String) -> String? {
            guard let index = values.firstIndex(of: flag), values.indices.contains(index + 1) else { return nil }
            return values[index + 1]
        }
        guard let input = value(after: "--input"),
              let output = value(after: "--output"),
              let headline = value(after: "--headline") else { return nil }
        self.input = input
        self.output = output
        self.headline = headline
        self.subheadline = value(after: "--subheadline") ?? ""
    }
}

guard let arguments = Arguments(Array(CommandLine.arguments.dropFirst())) else {
    fputs("Usage: swift Scripts/generate_aso_screenshot.swift --input <screenshot.png> --output <aso.png> --headline <text> [--subheadline <text>]\n", stderr)
    exit(2)
}

guard let screenshot = NSImage(contentsOfFile: arguments.input) else {
    fputs("Could not read input screenshot: \(arguments.input)\n", stderr)
    exit(1)
}

let canvasSize = NSSize(width: 1290, height: 2796) // App Store 6.9-inch portrait
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize.width),
    pixelsHigh: Int(canvasSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 32
) else {
    fputs("Could not create the output bitmap.\n", stderr)
    exit(1)
}
bitmap.size = canvasSize

NSGraphicsContext.saveGraphicsState()
guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Could not create a bitmap graphics context.\n", stderr)
    exit(1)
}
NSGraphicsContext.current = graphicsContext
let context = graphicsContext.cgContext

let colors = [
    NSColor(red: 1.00, green: 0.99, blue: 0.97, alpha: 1).cgColor,
    NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1).cgColor
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: canvasSize.height),
    end: CGPoint(x: canvasSize.width, y: 0),
    options: []
)

func topRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
    NSRect(x: x, y: canvasSize.height - y - height, width: width, height: height)
}

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
paragraph.lineBreakMode = .byWordWrapping

let headlineAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 78, weight: .bold),
    .foregroundColor: NSColor(red: 0.11, green: 0.12, blue: 0.12, alpha: 1),
    .paragraphStyle: paragraph
]
NSAttributedString(string: arguments.headline, attributes: headlineAttributes)
    .draw(with: topRect(x: 90, y: 150, width: 1110, height: 240), options: [.usesLineFragmentOrigin, .usesFontLeading])

if !arguments.subheadline.isEmpty {
    let subheadlineAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 38, weight: .medium),
        .foregroundColor: NSColor(red: 0.40, green: 0.39, blue: 0.36, alpha: 1),
        .paragraphStyle: paragraph
    ]
    NSAttributedString(string: arguments.subheadline, attributes: subheadlineAttributes)
        .draw(with: topRect(x: 120, y: 430, width: 1050, height: 120), options: [.usesLineFragmentOrigin, .usesFontLeading])
}

// 上1/3をコピー、下2/3を端末画面に割り当てるスプリットレイアウト。
// 端末を下端から少しはみ出させ、背景を端まで使うfull-bleedな印象も加える。
let deviceRect = topRect(x: 105, y: 760, width: 1080, height: 2210)
let devicePath = NSBezierPath(roundedRect: deviceRect, xRadius: 112, yRadius: 112)
NSColor(red: 0.08, green: 0.085, blue: 0.09, alpha: 1).setFill()
devicePath.fill()

let screenRect = deviceRect.insetBy(dx: 26, dy: 26)
let screenPath = NSBezierPath(roundedRect: screenRect, xRadius: 88, yRadius: 88)
NSGraphicsContext.saveGraphicsState()
screenPath.addClip()

let sourceSize = screenshot.size
let scale = max(screenRect.width / sourceSize.width, screenRect.height / sourceSize.height)
let drawSize = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
let drawRect = NSRect(
    x: screenRect.midX - drawSize.width / 2,
    y: screenRect.midY - drawSize.height / 2,
    width: drawSize.width,
    height: drawSize.height
)
screenshot.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()

let islandRect = NSRect(x: deviceRect.midX - 115, y: deviceRect.maxY - 74, width: 230, height: 54)
NSColor.black.setFill()
NSBezierPath(roundedRect: islandRect, xRadius: 27, yRadius: 27).fill()

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
let outputURL = URL(fileURLWithPath: arguments.output)
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outputURL, options: .atomic)
print("Generated \(outputURL.path)")
