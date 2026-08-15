import SwiftUI

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
        sourceImage = image
        regions = []
        path = [.documentType]
    }
}
