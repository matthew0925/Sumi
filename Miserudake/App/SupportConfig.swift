import Foundation

/// サポート導線用の連絡先・URL。実際に公開したページのURLへ差し替えること。
enum SupportConfig {
    static let supportEmail = "support@example.com"
    static let privacyPolicyURL = URL(string: "https://example.com/miserudake/privacy")!
}
