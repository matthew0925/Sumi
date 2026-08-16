import UIKit
import Testing
@testable import Sumi

@MainActor
struct MaskingFlowTests {
    @Test("startFlowで画面遷移パスと状態が初期化される")
    func startFlowResetsStateAndNavigates() {
        let flow = MaskingFlow()
        flow.maskingStyle = .mosaic
        flow.safetyPadding = .maximum
        flow.regions = [MaskRegion(boundingBox: .zero, kind: .manual)]
        flow.path = [.export, .purchase]

        let image = UIImage()
        flow.startFlow(with: image)

        #expect(flow.sourceImage === image)
        #expect(flow.regions.isEmpty)
        #expect(flow.path == [.documentType])
        #expect(flow.safetyPadding == .standard)
    }

    @Test("resetで全状態が初期化される")
    func resetClearsEverything() {
        let flow = MaskingFlow()
        flow.startFlow(with: UIImage())
        flow.path.append(.detectionPreview)
        flow.documentType = .passport
        flow.safetyPadding = .wide

        flow.reset()

        #expect(flow.path.isEmpty)
        #expect(flow.sourceImage == nil)
        #expect(flow.documentType == .other)
        #expect(flow.regions.isEmpty)
        #expect(flow.maskingStyle == .solidBlack)
        #expect(flow.safetyPadding == .standard)
    }

    @Test("高解像度画像は向きを正規化して長辺4096px以内へ縮小される")
    func preparesLargeImageForProcessing() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 5000, height: 2500))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 5000, height: 2500))
        }

        let prepared = MaskingFlow.preparedForProcessing(image)

        #expect(prepared.size.width == 4096)
        #expect(prepared.size.height == 2048)
        #expect(prepared.imageOrientation == .up)
        #expect(prepared.scale == 1)
    }

    @Test("新しい画像で開始すると書類種別とマスク方式も初期化される")
    func startFlowResetsDocumentAndStyle() {
        let flow = MaskingFlow()
        flow.documentType = .passport
        flow.maskingStyle = .mosaic
        flow.safetyPadding = .maximum

        flow.startFlow(with: UIImage())

        #expect(flow.documentType == .other)
        #expect(flow.maskingStyle == .solidBlack)
        #expect(flow.safetyPadding == .standard)
    }

    @Test("圧縮画像データはフル解像度展開前に処理用サイズへダウンサンプルされる")
    func downsamplesEncodedImageData() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 5000, height: 2500))
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 5000, height: 2500))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.8))

        let prepared = try #require(MaskingFlow.preparedForProcessing(data: data))

        #expect(prepared.size.width == 4096)
        #expect(prepared.size.height == 2048)
        #expect(prepared.imageOrientation == .up)
    }
}
