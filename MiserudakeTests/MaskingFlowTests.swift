import UIKit
import Testing
@testable import Miserudake

@MainActor
struct MaskingFlowTests {
    @Test("startFlowで画面遷移パスと状態が初期化される")
    func startFlowResetsStateAndNavigates() {
        let flow = MaskingFlow()
        flow.maskingStyle = .mosaic
        flow.regions = [MaskRegion(boundingBox: .zero, kind: .manual)]
        flow.path = [.export, .purchase]

        let image = UIImage()
        flow.startFlow(with: image)

        #expect(flow.sourceImage === image)
        #expect(flow.regions.isEmpty)
        #expect(flow.path == [.documentType])
    }

    @Test("resetで全状態が初期化される")
    func resetClearsEverything() {
        let flow = MaskingFlow()
        flow.startFlow(with: UIImage())
        flow.path.append(.detectionPreview)
        flow.documentType = .passport

        flow.reset()

        #expect(flow.path.isEmpty)
        #expect(flow.sourceImage == nil)
        #expect(flow.documentType == .other)
        #expect(flow.regions.isEmpty)
        #expect(flow.maskingStyle == .solidBlack)
    }
}
