#!/usr/bin/env swift
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("no context") }

// 背景グラデーション（アクセントカラー系）
let colors = [
    CGColor(red: 0.086, green: 0.114, blue: 0.157, alpha: 1),
    CGColor(red: 0.15, green: 0.20, blue: 0.30, alpha: 1)
] as CFArray
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

// 中央のカード型モチーフ
let cardRect = CGRect(x: Double(size) * 0.18, y: Double(size) * 0.32, width: Double(size) * 0.64, height: Double(size) * 0.42)
let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 48, cornerHeight: 48, transform: nil)
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
context.addPath(cardPath)
context.fillPath()

// マスキング帯（黒塗り部分の表現）
let barHeight = Double(size) * 0.07
let barColor = CGColor(red: 0.361, green: 0.541, blue: 0.847, alpha: 1)
context.setFillColor(barColor)
let bar1 = CGRect(x: cardRect.minX + 60, y: cardRect.minY + 80, width: cardRect.width * 0.55, height: barHeight)
let bar2 = CGRect(x: cardRect.minX + 60, y: cardRect.minY + 80 + barHeight + 24, width: cardRect.width * 0.4, height: barHeight)
context.fill(bar1)
context.fill(bar2)

// 丸いアイコン部分（顔写真枠の表現）
context.setFillColor(CGColor(red: 0.086, green: 0.114, blue: 0.157, alpha: 1))
let circleRect = CGRect(x: cardRect.maxX - 190, y: cardRect.minY + 70, width: 120, height: 120)
context.fillEllipse(in: circleRect)

guard let image = context.makeImage() else { fatalError("no image") }

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("no destination")
}
CGImageDestinationAddImage(destination, image, nil)
CGImageDestinationFinalize(destination)
print("wrote \(outputURL.path)")
