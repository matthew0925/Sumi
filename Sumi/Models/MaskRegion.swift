import Foundation
import CoreGraphics

/// 検出された（あるいはユーザーが手動追加した）マスク候補領域。
/// 座標は元画像の正規化座標系（左下原点、Vision準拠）で保持する。
struct MaskRegion: Identifiable, Equatable {
    enum Kind: String, CaseIterable, Codable {
        case text
        case barcode
        case face
        case manual
    }

    /// 書類種別の推奨ルールや保存済みプリセットを、種類（kind）ベースで一括適用する。
    /// `.manual`領域はユーザーがこの写真の特定の場所を見て個別に描いたもので、
    /// 「種類」による一般ルールの対象ではない。ここで一括ON/OFFしてしまうと、
    /// 自動検出が見逃した箇所を手動で隠した意図がプリセット適用のたびに
    /// 上書きされ、書き出し直前に無防備な状態へ戻ってしまう恐れがあるため、
    /// `.manual`領域は現在の状態のまま変更しない。
    static func applying(enabledKinds: Set<Kind>, to regions: [MaskRegion]) -> [MaskRegion] {
        regions.map { region in
            guard region.kind != .manual else { return region }
            var updated = region
            updated.isEnabled = enabledKinds.contains(region.kind)
            return updated
        }
    }

    let id: UUID
    var boundingBox: CGRect
    var kind: Kind
    var isEnabled: Bool

    init(id: UUID = UUID(), boundingBox: CGRect, kind: Kind, isEnabled: Bool = true) {
        self.id = id
        self.boundingBox = Self.clampedToUnitSquare(boundingBox)
        self.kind = kind
        self.isEnabled = isEnabled
    }

    /// Visionやドラッグ操作から受け取った矩形を、0...1の正規化画像領域内に収める。
    /// 負のサイズもstandardizedで補正し、画像外への描画や意図しない領域のマスクを防ぐ。
    static func clampedToUnitSquare(_ rect: CGRect) -> CGRect {
        guard rect.origin.x.isFinite, rect.origin.y.isFinite,
              rect.width.isFinite, rect.height.isFinite else { return .zero }
        let unitSquare = CGRect(x: 0, y: 0, width: 1, height: 1)
        let clamped = rect.standardized.intersection(unitSquare)
        return clamped.isNull ? .zero : clamped
    }
}
