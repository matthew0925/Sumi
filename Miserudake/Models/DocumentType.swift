import Foundation

/// 書類種別プリセット。「よく隠す項目」の初期候補を出すだけで、最終判断は必ずユーザー確認を挟む。
enum DocumentType: String, CaseIterable, Identifiable {
    case driversLicense
    case myNumberCard
    case healthInsuranceCard
    case passport
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .driversLicense: return "運転免許証"
        case .myNumberCard: return "マイナンバーカード"
        case .healthInsuranceCard: return "健康保険証"
        case .passport: return "パスポート"
        case .other: return "その他・自由選択"
        }
    }
}
