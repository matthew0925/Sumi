import SwiftUI
import ImageIO

/// ホーム→書類種別→検出プレビュー→スタイル選択→書き出し→購入 の画面遷移と、
/// その間で受け渡される画像・検出結果・選択状態を保持する。
@MainActor
final class MaskingFlow: ObservableObject {
    enum Step: Hashable {
        case documentType
        case detectionPreview
        case maskingStyle
        case export
        case purchase
    }

    @Published var path: [Step] = []

    @Published var sourceImage: UIImage?
    @Published var documentType: DocumentType = .other
    @Published var regions: [MaskRegion] = []
    @Published var maskingStyle: MaskingStyle = .solidBlack
    @Published var shareImportErrorMessage: String?

    func reset() {
        path.removeAll()
        sourceImage = nil
        documentType = .other
        regions = []
        maskingStyle = .solidBlack
    }

    func startFlow(with image: UIImage) {
        sourceImage = Self.preparedForProcessing(image)
        documentType = .other
        regions = []
        maskingStyle = .solidBlack
        path = [.documentType]
    }

    /// カメラの高解像度画像をそのまま複数回レンダリングするとメモリ不足になりやすい。
    /// 向きをピクセルへ焼き込み、長辺を上限内へ縮小してからフロー全体で共有する。
    static func preparedForProcessing(_ image: UIImage, maximumDimension: CGFloat = 4096) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }

        let pixelSize = CGSize(width: size.width * image.scale, height: size.height * image.scale)
        let longestSide = max(pixelSize.width, pixelSize.height)
        let scale = min(1, maximumDimension / longestSide)
        if scale == 1, image.scale == 1, image.imageOrientation == .up, image.cgImage != nil {
            return image
        }
        let targetSize = CGSize(width: pixelSize.width * scale, height: pixelSize.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// 圧縮データからフル解像度画像を一度展開せず、ImageIOで処理用サイズへ直接ダウンサンプルする。
    static func preparedForProcessing(data: Data, maximumDimension: CGFloat = 4096) -> UIImage? {
        guard !data.isEmpty,
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maximumDimension),
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }
}
