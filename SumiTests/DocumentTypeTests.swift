import Foundation
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
        // .manualは種類ベースの一括ルールの対象外（MaskRegion.applyingが個別に無視する）なので、
        // ここに含めても意味がない。
        #expect(!type.recommendedMaskKinds.contains(.manual))
    }

    @Test("プリセットは保存後に同じ内容で復元できる")
    func presetRoundTrip() throws {
        let suiteName = "MaskingPresetStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preset = MaskingPreset(
            name: "SNS投稿用",
            style: .mosaic,
            safetyPadding: .maximum,
            enabledKinds: [.text, .face]
        )

        #expect(MaskingPresetStore.save([preset], defaults: defaults))
        #expect(MaskingPresetStore.load(defaults: defaults) == [preset])
    }
}
