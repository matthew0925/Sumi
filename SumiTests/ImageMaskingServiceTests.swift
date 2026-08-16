import CoreGraphics
import Testing
@testable import Sumi

struct ImageMaskingServiceTests {
    @Test("対象種別ルールを適用すると一致する領域だけが有効になる")
    func appliesEnabledKinds() {
        let regions = [
            MaskRegion(boundingBox: .zero, kind: .text, isEnabled: false),
            MaskRegion(boundingBox: .zero, kind: .barcode, isEnabled: true),
            MaskRegion(boundingBox: .zero, kind: .face, isEnabled: true)
        ]

        let applied = MaskRegion.applying(enabledKinds: [.text, .barcode], to: regions)

        #expect(applied[0].isEnabled)
        #expect(applied[1].isEnabled)
        #expect(!applied[2].isEnabled)
    }

    @Test("安全余白はマスク領域を広げ、画像端で切り詰める")
    func expandsAndClampsSafetyPadding() {
        let center = CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2)
        let expanded = ImageMaskingService.expandedBoundingBox(center, safetyPadding: .wide)
        #expect(expanded.minX < center.minX)
        #expect(expanded.minY < center.minY)
        #expect(expanded.maxX > center.maxX)
        #expect(expanded.maxY > center.maxY)

        let edge = ImageMaskingService.expandedBoundingBox(
            CGRect(x: 0, y: 0, width: 0.1, height: 0.1),
            safetyPadding: .maximum
        )
        #expect(edge.minX == 0)
        #expect(edge.minY == 0)
        #expect(edge.maxX <= 1)
        #expect(edge.maxY <= 1)
    }

    @Test("Visionの正規化座標（左下原点）が画面ピクセル座標（左上原点）に変換される")
    func convertsBottomLeftOriginToTopLeftOrigin() {
        let size = CGSize(width: 1000, height: 500)

        // 画像の左下隅にある正規化矩形は、UIKit座標系では左下（yが大きい側）になるはず。
        let bottomLeft = CGRect(x: 0, y: 0, width: 0.1, height: 0.1)
        let converted = ImageMaskingService.convert(bottomLeft, to: size)
        #expect(converted.origin.x == 0)
        #expect(converted.origin.y == 450)
        #expect(converted.width == 100)
        #expect(converted.height == 50)
    }

    @Test("画像の右上隅にある正規化矩形はUIKit座標の原点付近に変換される")
    func convertsTopRightRegion() {
        let size = CGSize(width: 1000, height: 500)
        let topRight = CGRect(x: 0.9, y: 0.9, width: 0.1, height: 0.1)
        let converted = ImageMaskingService.convert(topRight, to: size)
        #expect(converted.origin.x == 900)
        #expect(abs(converted.origin.y) < 0.001)
    }

    @Test("画像外へはみ出す正規化矩形は画像領域内に切り詰められる")
    func clampsOutOfBoundsRegion() {
        let converted = ImageMaskingService.convert(
            CGRect(x: -0.2, y: 0.8, width: 0.5, height: 0.5),
            to: CGSize(width: 1000, height: 500)
        )

        #expect(converted.origin.x == 0)
        #expect(converted.origin.y == 0)
        #expect(abs(converted.width - 300) < 0.001)
        #expect(abs(converted.height - 100) < 0.001)
    }

    @Test("画像と交差しない矩形は空のマスクになる")
    func rejectsRegionOutsideImage() {
        let converted = ImageMaskingService.convert(
            CGRect(x: 2, y: 2, width: 0.5, height: 0.5),
            to: CGSize(width: 1000, height: 500)
        )

        #expect(converted.isEmpty)
    }

    @Test("不正な数値を含む矩形は空のマスクとして安全に扱う")
    func rejectsNonFiniteRegion() {
        let converted = ImageMaskingService.convert(
            CGRect(x: .nan, y: 0, width: 0.5, height: 0.5),
            to: CGSize(width: 1000, height: 500)
        )

        #expect(converted.isEmpty)
    }
}
