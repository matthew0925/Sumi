import Testing
@testable import Sumi

struct DocumentTypeTests {
    @Test("すべての書類種別に隠すべき項目の目安が用意されている", arguments: DocumentType.allCases)
    func everyTypeHasGuidance(type: DocumentType) {
        #expect(!type.commonlyHiddenFields.isEmpty)
        #expect(!type.displayName.isEmpty)
    }

    @Test("書類別の推奨ルールは文字とバーコードを安全側で選択する", arguments: DocumentType.allCases)
    func recommendedRuleIncludesSensitiveKinds(type: DocumentType) {
        #expect(type.recommendedMaskKinds.contains(.text))
        #expect(type.recommendedMaskKinds.contains(.barcode))
        #expect(!type.recommendedMaskKinds.contains(.face))
    }
}
