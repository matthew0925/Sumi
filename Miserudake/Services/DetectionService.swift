import Vision
import UIKit

/// テキスト領域・バーコード/QR領域をオンデバイスで検出し、マスク候補として返す。
/// 意味解釈は行わず「検出→候補提示→人間が最終確認」に徹する。
enum DetectionService {
    /// Visionの認識処理はCPU負荷が高く同期APIのため、呼び出し元（MainActor）を
    /// ブロックしないよう明示的にバックグラウンドタスクへ切り離して実行する。
    static func detectCandidates(in image: UIImage) async -> [MaskRegion] {
        await Task.detached(priority: .userInitiated) {
            detectCandidatesSynchronously(in: image)
        }.value
    }

    private static func detectCandidatesSynchronously(in image: UIImage) -> [MaskRegion] {
        guard let cgImage = image.cgImage else { return [] }
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation)

        // テキスト検出とバーコード検出は互いに独立させておく。
        // 一方が失敗（例: Simulatorでの.accurateモデル読み込み失敗）しても、
        // もう一方の結果は失わずに済むようにするため。
        let textResults = recognizeText(handler: handler)
        let barcodeResults = detectBarcodes(handler: handler)

        var regions: [MaskRegion] = []

        regions += textResults.map { observation in
            let text = observation.topCandidates(1).first?.string ?? ""
            return MaskRegion(
                boundingBox: observation.boundingBox,
                kind: .text,
                isEnabled: looksLikePersonalInformation(text)
            )
        }

        // QR/バーコードはマイナンバーカード等で個人情報を符号化していることが多いため、常に候補として有効にする。
        regions += barcodeResults.map {
            MaskRegion(boundingBox: $0.boundingBox, kind: .barcode, isEnabled: true)
        }

        return regions
    }

    /// .accurateでの認識に失敗した場合（Simulator等でモデルの初期化に失敗するケースを含む）は
    /// .fastにフォールバックする。両方失敗した場合は「検出0件」として扱い、
    /// ユーザーが手動でマスク領域を追加できる状態に倒す（アプリを詰まらせない）。
    private static func recognizeText(handler: VNImageRequestHandler) -> [VNRecognizedTextObservation] {
        for level in [VNRequestTextRecognitionLevel.accurate, .fast] {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = level
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["ja-JP", "en-US"]
            do {
                try handler.perform([request])
                if let results = request.results {
                    return results
                }
            } catch {
                continue
            }
        }
        return []
    }

    private static func detectBarcodes(handler: VNImageRequestHandler) -> [VNBarcodeObservation] {
        let request = VNDetectBarcodesRequest()
        do {
            try handler.perform([request])
            return request.results ?? []
        } catch {
            return []
        }
    }

    /// 生年月日・個人番号など「隠すべき可能性が高い」パターンにマッチするかどうかの簡易判定。
    /// 意味の断定はせず、初期のON/OFF状態を決めるためだけに使う（最終判断は必ずユーザー確認）。
    /// テストから直接検証できるようinternalにしている。
    static func looksLikePersonalInformation(_ text: String) -> Bool {
        let digitsOnly = text.filter(\.isNumber)

        // 12桁の個人番号（マイナンバー）や、和暦・西暦の生年月日表記に典型的な数字の並び。
        if digitsOnly.count >= 8 {
            return true
        }

        let addressKeywords = ["都", "道", "府", "県", "市", "区", "町", "村", "丁目", "番地"]
        if addressKeywords.contains(where: text.contains) {
            return true
        }

        let dateKeywords = ["年", "月", "日", "生"]
        let dateKeywordHits = dateKeywords.filter(text.contains).count
        if dateKeywordHits >= 2 {
            return true
        }

        return false
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
