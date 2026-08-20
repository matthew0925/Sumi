import Foundation

/// 保存・共有時のファイル名を「Sumi_書類種別_日時」の形式で組み立てる。
/// 業務・申請用途で複数枚を扱う際に、後から見て内容が分かるようにするため。
enum ExportFileNaming {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = .current
        return formatter
    }()

    /// - Parameters:
    ///   - documentType: ファイル名に含める書類種別。
    ///   - date: 生成日時（テストから固定できるよう引数化）。
    ///   - fileExtension: 拡張子（ドットなし）。
    static func fileName(documentType: DocumentType, date: Date = Date(), fileExtension: String = "jpg") -> String {
        let sanitizedType = sanitize(documentType.displayName)
        let timestamp = formatter.string(from: date)
        return "Sumi_\(sanitizedType)_\(timestamp).\(fileExtension)"
    }

    /// ファイル名に使えない文字（パス区切りや「・」等）を取り除く。
    private static func sanitize(_ text: String) -> String {
        let disallowed = CharacterSet(charactersIn: "/\\:*?\"<>|・")
        return text.components(separatedBy: disallowed).joined()
    }
}
