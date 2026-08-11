import Foundation

/// サポート導線用の連絡先・URL。
/// privacyPolicyURLは、リポジトリのGitHub Pages（Settings > Pages > Source: main branch /docs）を
/// 有効化した上で有効になる。有効化するまでは404になる点に注意。
enum SupportConfig {
    static let supportEmail = "miserudake.support@gmail.com"
    static let privacyPolicyURL = URL(string: "https://matthew0925.github.io/miserudake/privacy-policy.html")!
}
