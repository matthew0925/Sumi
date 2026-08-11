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

    @Test("短い数字（有効期限の日数など）だけでは誤検知しない")
    func shortDigitsAreNotFlagged() {
        #expect(!DetectionService.looksLikePersonalInformation("12"))
    }
}
