import Testing
@testable import Sumi

struct DocumentTypeTests {
    @Test("すべての書類種別に隠すべき項目の目安が用意されている", arguments: DocumentType.allCases)
    func everyTypeHasGuidance(type: DocumentType) {
        #expect(!type.commonlyHiddenFields.isEmpty)
        #expect(!type.displayName.isEmpty)
    }
}
