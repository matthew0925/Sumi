import Foundation

enum MaskingStyle: String, CaseIterable, Identifiable {
    case solidBlack
    case mosaic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .solidBlack: return "黒塗り"
        case .mosaic: return "モザイク"
        }
    }
}
