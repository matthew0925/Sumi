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
        // カメラロールの写真はEXIFの向き情報を持ち、source.cgImageは回転前の
        // 生ピクセルのままのことが多い。黒塗り（source.draw経由、向きが自動で
        // 補正される）は問題にならないが、モザイクはsource.cgImageを直接
        // ピクセル座標で切り出すため、向きを先に焼き込んでおかないと
        // Visionが返した矩形とズレて切り出しに失敗し、その領域だけ無加工の
        // まま残ってしまう。先に正規化することで両スタイルの座標系を揃える。
        let normalizedSource = source.normalizedOrientation()
        let size = normalizedSource.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = normalizedSource.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            normalizedSource.draw(in: CGRect(origin: .zero, size: size))

            let cgContext = context.cgContext
            for region in regions where region.isEnabled {
                let rect = convert(region.boundingBox, to: size)
                switch style {
                case .solidBlack:
                    cgContext.setFillColor(UIColor.black.cgColor)
                    cgContext.fill(rect)
                case .mosaic:
                    // モザイク描画が何らかの理由で失敗した場合、その領域が無加工のまま
                    // 残ることだけは絶対に避けたいため、黒塗りにフォールバックする。
                    // 「隠したつもりが隠れていなかった」を防ぐための最後の砦。
                    if !drawMosaic(from: normalizedSource, in: rect, context: cgContext) {
                        cgContext.setFillColor(UIColor.black.cgColor)
                        cgContext.fill(rect)
                    }
                }
            }

            if watermarked {
                drawWatermark(in: size)
            }
        }
    }

    /// Visionの正規化座標（左下原点）をUIKit座標（左上原点）のピクセル矩形に変換する。
    /// テストから直接検証できるようinternalにしている。
    static func convert(_ normalized: CGRect, to size: CGSize) -> CGRect {
        CGRect(
            x: normalized.origin.x * size.width,
            y: (1 - normalized.origin.y - normalized.height) * size.height,
            width: normalized.width * size.width,
            height: normalized.height * size.height
        )
    }

    /// モザイクを描画できた場合はtrue、何らかの理由で描画できなかった場合はfalseを返す。
    /// falseの場合、呼び出し側が黒塗りにフォールバックする。
    @discardableResult
    private static func drawMosaic(from source: UIImage, in rect: CGRect, context: CGContext) -> Bool {
        guard let cgImage = source.cgImage else { return false }

        // source.cgImageはピクセル単位、rectはsource.size（ポイント単位）で
        // 計算されている。scaleが1でない画像でもズレないよう、ピクセル座標に変換してから切り出す。
        let scaleX = CGFloat(cgImage.width) / source.size.width
        let scaleY = CGFloat(cgImage.height) / source.size.height
        let pixelRect = CGRect(
            x: rect.origin.x * scaleX,
            y: rect.origin.y * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        ).integral.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))

        guard !pixelRect.isEmpty, let cropped = cgImage.cropping(to: pixelRect) else { return false }
        let ciImage = CIImage(cgImage: cropped)

        // ブロックサイズは矩形の短い方の辺を基準にする。住所行のように
        // 横長・縦短の矩形で長い方（横幅）を基準にすると、ブロックサイズが
        // 縦幅を大きく超えてしまい、CIPixellateが範囲外の情報を要求して
        // 出力生成に失敗する（＝何も描画されず元の文字が透けて見える）ことがあった。
        let shortSide = min(pixelRect.width, pixelRect.height)
        let blockSize = max(4, shortSide * 0.2)
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(blockSize, forKey: kCIInputScaleKey)

        let ciContext = CIContext()
        guard let output = filter?.outputImage else { return false }
        let renderExtent = output.extent.intersection(ciImage.extent)
        guard !renderExtent.isEmpty, !renderExtent.isInfinite,
              let renderedCG = ciContext.createCGImage(output, from: renderExtent) else { return false }

        context.saveGState()
        context.clip(to: rect)
        context.draw(renderedCG, in: rect)
        context.restoreGState()
        return true
    }

    private static func drawWatermark(in size: CGSize) {
        let text = "Sumi"
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

private extension UIImage {
    /// EXIFの向き情報を実ピクセルに焼き込み、imageOrientationが常に.upな
    /// 新しい画像として返す。以後cgImageをピクセル座標で直接操作しても
    /// UIKit側の表示座標とズレなくなる。
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
