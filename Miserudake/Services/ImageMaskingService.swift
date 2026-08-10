import UIKit
import CoreImage

/// 有効なマスク領域を元画像に合成し、書き出し用画像を生成する。
/// EXIF等のメタデータは持ち越さず、新規に描画した画像として書き出す。
enum ImageMaskingService {
    static func renderMaskedImage(
        source: UIImage,
        regions: [MaskRegion],
        style: MaskingStyle,
        watermarked: Bool
    ) -> UIImage {
        let size = source.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = source.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            source.draw(in: CGRect(origin: .zero, size: size))

            let cgContext = context.cgContext
            for region in regions where region.isEnabled {
                let rect = convert(region.boundingBox, to: size)
                switch style {
                case .solidBlack:
                    cgContext.setFillColor(UIColor.black.cgColor)
                    cgContext.fill(rect)
                case .mosaic:
                    drawMosaic(from: source, in: rect, context: cgContext)
                }
            }

            if watermarked {
                drawWatermark(in: size)
            }
        }
    }

    /// Visionの正規化座標（左下原点）をUIKit座標（左上原点）のピクセル矩形に変換する。
    private static func convert(_ normalized: CGRect, to size: CGSize) -> CGRect {
        CGRect(
            x: normalized.origin.x * size.width,
            y: (1 - normalized.origin.y - normalized.height) * size.height,
            width: normalized.width * size.width,
            height: normalized.height * size.height
        )
    }

    private static func drawMosaic(from source: UIImage, in rect: CGRect, context: CGContext) {
        guard let cgImage = source.cgImage,
              let cropped = cgImage.cropping(to: rect.integral) else { return }
        let ciImage = CIImage(cgImage: cropped)
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(max(rect.width, rect.height) * 0.12, forKey: kCIInputScaleKey)

        let ciContext = CIContext()
        guard let output = filter?.outputImage,
              let renderedCG = ciContext.createCGImage(output, from: ciImage.extent) else { return }

        context.saveGState()
        context.clip(to: rect)
        context.draw(renderedCG, in: rect)
        context.restoreGState()
    }

    private static func drawWatermark(in size: CGSize) {
        let text = "Miserudake"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size.width * 0.035, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()
        let margin = size.width * 0.02
        let origin = CGPoint(
            x: size.width - textSize.width - margin,
            y: size.height - textSize.height - margin
        )
        attributed.draw(at: origin)
    }
}
