import Vision
import UIKit

/// テキスト領域・バーコード/QR領域をオンデバイスで検出し、マスク候補として返す。
/// 意味解釈は行わず「検出→候補提示→人間が最終確認」に徹する。
enum DetectionService {
    /// Visionの認識処理はCPU負荷が高く同期APIのため、呼び出し元（MainActor）を
    /// ブロックしないよう明示的にバックグラウンドタスクへ切り離して実行する。
    static func detectCandidates(in image: UIImage, documentType: DocumentType = .other) async -> [MaskRegion] {
        await Task.detached(priority: .userInitiated) {
            detectCandidatesSynchronously(in: image, documentType: documentType)
        }.value
    }

    private static func detectCandidatesSynchronously(in image: UIImage, documentType: DocumentType) -> [MaskRegion] {
        guard let cgImage = image.cgImage else { return [] }
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation)

        // テキスト検出とバーコード検出は互いに独立させておく。
        // 一方が失敗（例: Simulatorでの.accurateモデル読み込み失敗）しても、
        // もう一方の結果は失わずに済むようにするため。
        let textResults = recognizeText(handler: handler, documentType: documentType)
        let barcodeResults = detectBarcodes(handler: handler)
        let faceResults = detectFaces(handler: handler)

        var regions: [MaskRegion] = []

        regions += textResults.map { observation in
            guard let candidate = observation.topCandidates(1).first else {
                return MaskRegion(boundingBox: observation.boundingBox, kind: .text, isEnabled: false)
            }
            let text = candidate.string
            let recognizedBox = preciseNumericBoundingBox(in: candidate) ?? observation.boundingBox
            return MaskRegion(
                boundingBox: adjustedMaskBoundingBox(
                    for: text,
                    boundingBox: recognizedBox,
                    documentType: documentType
                ),
                kind: .text,
                isEnabled: looksLikePersonalInformation(text, documentType: documentType)
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
    private static func recognizeText(
        handler: VNImageRequestHandler,
        documentType: DocumentType
    ) -> [VNRecognizedTextObservation] {
        var merged: [VNRecognizedTextObservation] = []

        for level in [VNRequestTextRecognitionLevel.accurate, .fast] {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = level
            request.usesLanguageCorrection = level == .accurate
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.automaticallyDetectsLanguage = true
            request.minimumTextHeight = 0.006
            request.customWords = japaneseIdentityDocumentTerms + documentType.ocrCustomWords
            do {
                try handler.perform([request])
                for observation in request.results ?? [] {
                    let isDuplicate = merged.contains {
                        $0.boundingBox.intersectionOverUnion(with: observation.boundingBox) >= 0.72
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

    /// Visionが「番号 第 012345678900 号」のように1行で返した場合でも、
    /// 実際の数字部分だけの矩形を取得して周辺項目を巻き込まないようにする。
    private static func preciseNumericBoundingBox(in candidate: VNRecognizedText) -> CGRect? {
        let text = candidate.string
        guard let expression = try? NSRegularExpression(
            pattern: #"[0-9０-９][0-9０-９\s\-－]{2,}[0-9０-９]"#
        ) else { return nil }

        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = expression.matches(in: text, range: fullRange)
        guard let match = matches.max(by: { $0.range.length < $1.range.length }),
              let stringRange = Range(match.range, in: text) else { return nil }

        let matchedText = String(text[stringRange])
        guard matchedText.filter(\.isNumber).count >= 4,
              let rectangle = try? candidate.boundingBox(for: stringRange) else { return nil }
        return rectangle.boundingBox
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
    static func looksLikePersonalInformation(
        _ text: String,
        documentType: DocumentType = .other
    ) -> Bool {
        let normalized = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        let compact = normalized.replacingOccurrences(of: " ", with: "")
        let digitsOnly = compact.filter(\.isNumber)

        // fullwidthToHalfwidthで「○」が半角白丸「￮」へ変換されるケースも含める。
        let circleCharacters = compact.filter { "○◯〇￮Oo".contains($0) }
        if circleCharacters.count >= 3 {
            return true
        }

        // 12桁の個人番号（マイナンバー）や免許証番号・生年月日などに典型的な数字の並び。
        // Visionは長い番号を複数の断片に分割して認識することがあるため、
        // 断片単位でも見逃さないよう閾値は低めに設定している
        // （閾値を下げるほど誤検知は増えるが、隠し忘れの方が致命的なため安全側に倒す）。
        if digitsOnly.count >= 4 {
            return true
        }

        let personalInformationLabels = [
            "氏名", "名前", "住所", "生年月日", "個人番号", "免許証番号", "旅券番号",
            "保険者番号", "記号", "本籍", "性別", "交付", "有効期限", "国籍",
            "公安委員会", "公安", "委員会", "発行者", "発行元", "免許の条件",
            "条件等", "取得年月日", "種別"
        ]
        if personalInformationLabels.contains(where: compact.contains) {
            return true
        }
        if documentType.ocrCustomWords.contains(where: compact.contains) {
            return true
        }

        let patterns = [
            #"〒?\d{3}-?\d{4}"#,
            #"0\d{1,4}-?\d{1,4}-?\d{3,4}"#,
            #"\d{2,4}[./年-]\d{1,2}[./月-]\d{1,2}日?"#
        ]
        if patterns.contains(where: { compact.range(of: $0, options: .regularExpression) != nil }) {
            return true
        }

        let addressKeywords = ["都", "道", "府", "県", "市", "区", "町", "村", "丁目", "番地"]
        if addressKeywords.contains(where: compact.contains) {
            return true
        }

        let dateKeywords = ["年", "月", "日", "生"]
        let dateKeywordHits = dateKeywords.filter(compact.contains).count
        if dateKeywordHits >= 2 {
            return true
        }

        return false
    }

    /// Visionの矩形は認識文字に密着しており、アンチエイリアス部分や文字間の
    /// 断片が残ることがあるため、文字の高さに応じた余白を検出段階で加える。
    /// 「◯◯公安委員会」はVisionが「公安委員会」だけを切り出す場合があるため、
    /// 発行地域を含められるよう左側を広めに確保する。
    static func adjustedMaskBoundingBox(
        for text: String,
        boundingBox: CGRect,
        documentType: DocumentType = .other
    ) -> CGRect {
        let normalized = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        let compact = normalized.replacingOccurrences(of: " ", with: "")
        let horizontalPadding = max(0.008, boundingBox.height * 0.22)
        let verticalPadding = max(0.005, boundingBox.height * 0.18)

        var leftPadding = horizontalPadding
        var rightPadding = horizontalPadding
        if documentType == .driversLicense,
           compact.contains("公安委員会") || compact.contains("公安") || compact.contains("委員会") {
            leftPadding = max(0.12, boundingBox.width * 0.65)
            // 右隣の発行印・照合印も同じ発行者情報として覆う。
            rightPadding = max(0.15, boundingBox.width * 0.70)
        }

        // 生年月日や番号はVisionが末尾を別断片にしやすいため、左右の余白を
        // 最低2%確保する。DocumentTypeを受け取るのは書類別補正を拡張しやすくするため。
        if compact.contains("生年月日") {
            leftPadding = max(leftPadding, 0.02)
            rightPadding = max(rightPadding, 0.02)
        }
        let authorityVerticalPadding: CGFloat
        if documentType == .driversLicense,
           compact.contains("公安委員会") || compact.contains("公安") || compact.contains("委員会") {
            authorityVerticalPadding = max(verticalPadding, 0.025)
        } else {
            authorityVerticalPadding = verticalPadding
        }
        return CGRect(
            x: boundingBox.minX - leftPadding,
            y: boundingBox.minY - authorityVerticalPadding,
            width: boundingBox.width + leftPadding + rightPadding,
            height: boundingBox.height + authorityVerticalPadding * 2
        ).clampedToUnitSquare
    }

    private static let japaneseIdentityDocumentTerms = [
        "氏名", "住所", "生年月日", "個人番号", "運転免許証", "健康保険証",
        "旅券番号", "本籍", "有効期限", "臓器提供意思", "保険者番号", "公安委員会",
        "免許の条件等", "取得年月日"
    ]
}

private extension CGRect {
    var clampedToUnitSquare: CGRect {
        let x = min(max(minX, 0), 1)
        let y = min(max(minY, 0), 1)
        let maxX = min(max(self.maxX, 0), 1)
        let maxY = min(max(self.maxY, 0), 1)
        return CGRect(x: x, y: y, width: max(0, maxX - x), height: max(0, maxY - y))
    }

    /// 座標の近さではなく実際の重なり率で同じOCR結果かを判定する。
    /// 小さく隣接する文字を誤って重複扱いしないためのIoU（Intersection over Union）。
    func intersectionOverUnion(with other: CGRect) -> CGFloat {
        let intersection = intersection(other)
        guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = width * height + other.width * other.height - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
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
