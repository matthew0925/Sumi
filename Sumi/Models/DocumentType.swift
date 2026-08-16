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

    /// 「よく隠す項目」の初期候補としてユーザーに提示するガイド。
    /// あくまで一般的な目安であり、最終判断は必ずユーザー自身が行う。
    var commonlyHiddenFields: [String] {
        switch self {
        case .driversLicense:
            return ["住所", "生年月日", "免許証番号", "本籍（表示されている場合）"]
        case .myNumberCard:
            return ["個人番号（12桁）", "住所", "生年月日", "QRコード"]
        case .healthInsuranceCard:
            return ["保険者番号", "住所", "生年月日", "記号・番号"]
        case .passport:
            return ["旅券番号", "生年月日", "本籍", "身分事項ページのQR/バーコード"]
        case .other:
            return ["住所", "生年月日", "各種番号（会員番号・口座番号等）"]
        }
    }

    /// Visionの日本語OCRで書類固有の語を認識しやすくするための補助辞書。
    var ocrCustomWords: [String] {
        switch self {
        case .driversLicense:
            return ["運転免許証", "免許の条件等", "公安委員会", "優良"]
        case .myNumberCard:
            return ["個人番号カード", "個人番号", "電子証明書", "臓器提供意思"]
        case .healthInsuranceCard:
            return ["健康保険", "被保険者", "保険者番号", "記号", "枝番"]
        case .passport:
            return ["日本国旅券", "旅券番号", "国籍", "有効期間満了日", "PASSPORT"]
        case .other:
            return []
        }
    }

    /// 書類全体へ一括適用できる安全側の初期ルール。
    /// 顔は本人確認用途で必要なことが多いため自動では隠さず、手動で選べる状態にする。
    var recommendedMaskKinds: Set<MaskRegion.Kind> {
        switch self {
        case .driversLicense, .myNumberCard, .healthInsuranceCard, .passport:
            return [.text, .barcode, .manual]
        case .other:
            return [.text, .barcode, .manual]
        }
    }
}
