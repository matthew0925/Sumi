import Foundation
import Testing
@testable import Sumi

struct ExportFileNamingTests {
    @Test("Sumi_書類種別_日時 の形式でファイル名を生成する")
    func generatesTemplatedFileName() {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 21
        components.hour = 7
        components.minute = 30
        components.second = 5
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = calendar.date(from: components)!

        let name = ExportFileNaming.fileName(documentType: .driversLicense, date: date)
        #expect(name == "Sumi_運転免許証_20260821_073005.jpg")
    }

    @Test("書類種別名の「・」等ファイル名に使えない文字は取り除く")
    func sanitizesDisallowedCharacters() {
        let name = ExportFileNaming.fileName(documentType: .other, date: Date(timeIntervalSince1970: 0))
        #expect(!name.contains("・"))
        #expect(name.hasPrefix("Sumi_"))
        #expect(name.hasSuffix(".jpg"))
    }
}
