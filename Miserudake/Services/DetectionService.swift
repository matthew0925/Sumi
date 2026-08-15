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
        let faceResults = detectFaces(handler: handler)

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

        // 顔写真は「本人確認のため見える必要がある」場面が多く、他の候補と違い
        // 隠すべきかどうかの前提が用途次第で変わる。誤って隠したまま提出する
        // 事故を防ぐため、検出はするが初期状態は無効（OFF）にしておき、
        // 隠したい場合はユーザーが自分でタップして有効にする形にする。
        regions += faceResults.map {
            MaskRegion(boundingBox: $0.boundingBox, kind: .face, isEnabled: false)
        }

        return regions
    }

    /// .accurateと.fastの両方で認識を試み、結果を合成する。
    /// 実機実測で、片方の認識レベルだけでは住所や番号などの行を取りこぼす
    /// ケースが確認されたため（Visionが1行を複数の断片に分割して認識し、
    /// 断片ごとの情報量が閾値に届かない等）、両方の結果を合わせることで
    /// 見逃しを減らす。同一箇所の重複はほぼ同じ矩形として弾く。
    /// 片方が失敗（例: Simulatorでの.accurateモデル読み込み失敗）しても、
    /// もう一方の結果は活かす。両方失敗した場合は「検出0件」として扱い、
    /// ユーザーが手動でマスク領域を追加できる状態に倒す（アプリを詰まらせない）。
    private static func recognizeText(handler: VNImageRequestHandler) -> [VNRecognizedTextObservation] {
        var merged: [VNRecognizedTextObservation] = []

        for level in [VNRequestTextRecognitionLevel.accurate, .fast] {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = level
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["ja-JP", "en-US"]
            do {
                try handler.perform([request])
                for observation in request.results ?? [] {
                    let isDuplicate = merged.contains {
                        $0.boundingBox.isApproximately(observation.boundingBox)
                    }
                    if !isDuplicate {
                        merged.append(observation)
                    }
                }
            } catch {
                continue
            }
        }

        return merged
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

    private static func detectFaces(handler: VNImageRequestHandler) -> [VNFaceObservation] {
        let request = VNDetectFaceRectanglesRequest()
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

        // 12桁の個人番号（マイナンバー）や免許証番号・生年月日などに典型的な数字の並び。
        // Visionは長い番号を複数の断片に分割して認識することがあるため、
        // 断片単位でも見逃さないよう閾値は低めに設定している
        // （閾値を下げるほど誤検知は増えるが、隠し忘れの方が致命的なため安全側に倒す）。
        if digitsOnly.count >= 4 {
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

private extension CGRect {
    /// 正規化座標系での「ほぼ同じ位置・大きさ」判定。
    /// .accurateと.fastそれぞれの結果を合成する際、同一箇所の重複行を弾くために使う。
    func isApproximately(_ other: CGRect, tolerance: CGFloat = 0.02) -> Bool {
        abs(origin.x - other.origin.x) < tolerance
            && abs(origin.y - other.origin.y) < tolerance
            && abs(width - other.width) < tolerance
            && abs(height - other.height) < tolerance
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
