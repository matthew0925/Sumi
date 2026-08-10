import Foundation
import CoreGraphics

/// 検出された（あるいはユーザーが手動追加した）マスク候補領域。
/// 座標は元画像の正規化座標系（左下原点、Vision準拠）で保持する。
struct MaskRegion: Identifiable, Equatable {
    enum Kind: String {
        case text
        case barcode
        case manual
    }

    let id: UUID
    var boundingBox: CGRect
    var kind: Kind
    var isEnabled: Bool

    init(id: UUID = UUID(), boundingBox: CGRect, kind: Kind, isEnabled: Bool = true) {
        self.id = id
        self.boundingBox = boundingBox
        self.kind = kind
        self.isEnabled = isEnabled
    }
}
