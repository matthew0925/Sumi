import Foundation

/// アプリ本体とShare Extensionの間で、共有シートから渡された画像を1枚だけ
/// 受け渡すためのApp Groupコンテナ。渡した画像は読み取り側が読み込み次第すぐ削除する
/// （本体アプリが読み込んだ直後に破棄し、受け渡しファイルを残さない）。
enum SharedContainer {
    static let appGroupID = "group.com.matthew0925.sumi"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private static var handoffImageURL: URL? {
        containerURL?.appendingPathComponent("share-handoff.jpg")
    }

    /// Share Extension側から呼ぶ。共有された画像をApp Groupコンテナに書き込む。
    @discardableResult
    static func writeHandoffImage(_ data: Data) -> Bool {
        guard !data.isEmpty, let url = handoffImageURL else { return false }
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            return true
        } catch {
            return false
        }
    }

    /// アプリ本体側から呼ぶ。渡された画像を読み込み、読み込み後は即座に削除する。
    /// 削除は後始末のベストエフォートであり、削除に失敗しても既に読み込めた
    /// 画像データ自体は正常なので、ユーザーに「共有に失敗した」と誤って
    /// 見せないよう読み込み成功を優先して返す。
    static func consumeHandoffImage() -> Data? {
        guard let url = handoffImageURL,
              let data = try? Data(contentsOf: url) else { return nil }
        try? FileManager.default.removeItem(at: url)
        return data
    }
}
