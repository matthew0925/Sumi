import Testing
import CoreGraphics
@testable import Sumi

struct DetectionServiceTests {
    @Test("長い数字列は個人情報候補として初期ONになる")
    func longDigitSequenceIsFlagged() {
        #expect(DetectionService.looksLikePersonalInformation("123456789012"))
    }

    @Test("住所らしきキーワードを含む文字列は初期ONになる")
    func addressKeywordIsFlagged() {
        #expect(DetectionService.looksLikePersonalInformation("東京都渋谷区"))
    }

    @Test("生年月日らしき年月日の組み合わせは初期ONになる")
    func dateLikeTextIsFlagged() {
        #expect(DetectionService.looksLikePersonalInformation("1990年1月1日生"))
    }

    @Test("それらしいパターンに当てはまらない短いテキストは初期OFFのまま")
    func genericTextIsNotFlagged() {
        #expect(!DetectionService.looksLikePersonalInformation("運転免許証"))
    }

    @Test("短い数字（1〜2桁）だけでは誤検知しない")
    func shortDigitsAreNotFlagged() {
        #expect(!DetectionService.looksLikePersonalInformation("12"))
    }

    @Test("Visionが番号を断片化して認識しても4桁あれば見逃さない")
    func fragmentedNumberIsStillFlagged() {
        // 実機テストで、免許証番号のような長い数字列がVisionによって
        // 複数の断片に分割認識され、8桁閾値だと取りこぼすケースが確認されたため、
        // 4桁の断片でも検出できることを保証する。
        #expect(DetectionService.looksLikePersonalInformation("0127"))
        #expect(DetectionService.looksLikePersonalInformation("78900"))
    }

    @Test("全角数字の郵便番号も個人情報候補として検出する")
    func fullWidthPostalCodeIsFlagged() {
        #expect(DetectionService.looksLikePersonalInformation("〒１５０－０００１"))
    }

    @Test("ハイフンを含む電話番号を個人情報候補として検出する")
    func phoneNumberIsFlagged() {
        #expect(DetectionService.looksLikePersonalInformation("03-1234-5678"))
    }

    @Test("個人情報ラベルは数字がなくても候補として検出する")
    func identityLabelIsFlagged() {
        #expect(DetectionService.looksLikePersonalInformation("氏名"))
        #expect(DetectionService.looksLikePersonalInformation("本籍"))
        #expect(DetectionService.looksLikePersonalInformation("東京都公安委員会"))
    }

    @Test("丸印が3つ以上並ぶ文字列も候補として検出する")
    func repeatedCircleSymbolsAreFlagged() {
        #expect(DetectionService.looksLikePersonalInformation("○○○○○"))
        #expect(DetectionService.looksLikePersonalInformation("◯◯◯"))
    }

    @Test("検出矩形には文字切れを防ぐ余白を加える")
    func detectedBoundsReceiveAdaptivePadding() {
        let source = CGRect(x: 0.30, y: 0.40, width: 0.20, height: 0.05)
        let adjusted = DetectionService.adjustedMaskBoundingBox(
            for: "1990年1月1日生",
            boundingBox: source,
            documentType: .driversLicense
        )

        #expect(adjusted.minX < source.minX)
        #expect(adjusted.maxX > source.maxX)
        #expect(adjusted.minY < source.minY)
        #expect(adjusted.maxY > source.maxY)
    }

    @Test("公安委員会は発行地域を含むよう左側を広く確保する")
    func issuingAuthorityExpandsTowardRegionName() {
        let source = CGRect(x: 0.55, y: 0.05, width: 0.18, height: 0.04)
        let adjusted = DetectionService.adjustedMaskBoundingBox(
            for: "公安委員会",
            boundingBox: source,
            documentType: .driversLicense
        )

        #expect(adjusted.minX <= source.minX - 0.12)
        #expect(adjusted.maxX >= source.maxX + 0.14)
        #expect(adjusted.height > source.height + 0.04)
    }

    @Test("カード番号の右隣にある3桁認識を4桁セキュリティコードとして補完する")
    func myNumberSecurityCodeRecognizedAsThreeDigitsIsFlagged() {
        let codeBox = CGRect(x: 0.31, y: 0.12, width: 0.035, height: 0.018)
        let fragments = [
            RecognizedTextFragment(
                text: "0123456789ABCDEF",
                boundingBox: CGRect(x: 0.08, y: 0.115, width: 0.22, height: 0.022)
            ),
            RecognizedTextFragment(text: "234", boundingBox: codeBox)
        ]

        #expect(DetectionService.isLikelyMyNumberSecurityCode(
            text: "234",
            boundingBox: codeBox,
            fragments: fragments
        ))
    }

    @Test("離れた3桁の日付断片はセキュリティコードと誤判定しない")
    func unrelatedThreeDigitsAreNotSecurityCode() {
        let codeBox = CGRect(x: 0.70, y: 0.55, width: 0.035, height: 0.018)
        let fragments = [
            RecognizedTextFragment(
                text: "0123456789ABCDEF",
                boundingBox: CGRect(x: 0.08, y: 0.115, width: 0.22, height: 0.022)
            ),
            RecognizedTextFragment(text: "202", boundingBox: codeBox)
        ]

        #expect(!DetectionService.isLikelyMyNumberSecurityCode(
            text: "202",
            boundingBox: codeBox,
            fragments: fragments
        ))
    }
}
