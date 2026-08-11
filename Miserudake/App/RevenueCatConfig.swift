import Foundation

/// RevenueCatのAPIキー・エンタイトルメント識別子。
/// APIキーは公開鍵（クライアント埋め込み前提）だが、プロジェクトごとに異なるため
/// RevenueCatダッシュボードで発行したiOS用Public API Keyに置き換えること。
enum RevenueCatConfig {
    static let apiKey = "REVENUECAT_API_KEY"

    /// 透かし解除の権利を表すエンタイトルメント識別子（RevenueCatダッシュボードで作成）。
    static let watermarkRemovalEntitlement = "watermark_removal"

    /// 買い切り商品を含むオファリング識別子（Defaultでよければ未使用）。
    static let defaultOfferingID: String? = nil
}
