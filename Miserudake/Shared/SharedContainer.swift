import Foundation

/// アプリ本体とShare Extensionの間で、共有シートから渡された画像を1枚だけ
/// 受け渡すためのApp Groupコンテナ。渡した画像は読み取り側が読み込み次第すぐ削除する
/// （書き出し後は破棄する、という本アプリの一時ファイル方針をExtension経由でも維持する）。
enum SharedContainer {
    static let appGroupID = "group.com.matthew0925.miserudake"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private static var handoffImageURL: URL? {
        containerURL?.appendingPathComponent("share-handoff.jpg")
    }

    /// Share Extension側から呼ぶ。共有された画像をApp Groupコンテナに書き込む。
    static func writeHandoffImage(_ data: Data) {
        guard let url = handoffImageURL else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// アプリ本体側から呼ぶ。渡された画像を読み込み、読み込み後は即座に削除する。
    static func consumeHandoffImage() -> Data? {
        guard let url = handoffImageURL,
              let data = try? Data(contentsOf: url) else { return nil }
        try? FileManager.default.removeItem(at: url)
        return data
    }
}
