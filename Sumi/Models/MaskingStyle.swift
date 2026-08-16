import Foundation

enum MaskingStyle: String, CaseIterable, Identifiable, Codable {
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

enum MaskSafetyPadding: String, CaseIterable, Identifiable, Codable {
    case standard
    case wide
    case maximum

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "標準"
        case .wide: return "広め"
        case .maximum: return "最大"
        }
    }

    /// 正規化座標で矩形の各辺へ追加する余白。元画像サイズに依存せず一貫して適用できる。
    var normalizedInset: CGFloat {
        switch self {
        case .standard: return 0.006
        case .wide: return 0.014
        case .maximum: return 0.025
        }
    }
}

struct MaskingPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var style: MaskingStyle
    var safetyPadding: MaskSafetyPadding
    var enabledKinds: Set<MaskRegion.Kind>

    init(
        id: UUID = UUID(),
        name: String,
        style: MaskingStyle,
        safetyPadding: MaskSafetyPadding,
        enabledKinds: Set<MaskRegion.Kind>
    ) {
        self.id = id
        self.name = name
        self.style = style
        self.safetyPadding = safetyPadding
        self.enabledKinds = enabledKinds
    }
}

enum MaskingPresetStore {
    private static let key = "maskingPresets.v1"

    static func load(defaults: UserDefaults = .standard) -> [MaskingPreset] {
        guard let data = defaults.data(forKey: key),
              let presets = try? JSONDecoder().decode([MaskingPreset].self, from: data) else {
            return []
        }
        return presets
    }

    @discardableResult
    static func save(_ presets: [MaskingPreset], defaults: UserDefaults = .standard) -> Bool {
        guard let data = try? JSONEncoder().encode(presets) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}
