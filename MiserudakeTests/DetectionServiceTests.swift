import Testing
@testable import Miserudake

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
}
