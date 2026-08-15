import CoreGraphics
import Testing
@testable import Sumi

struct ImageMaskingServiceTests {
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
}
