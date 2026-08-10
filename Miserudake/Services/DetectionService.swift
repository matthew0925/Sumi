import Vision
import UIKit

/// テキスト領域・バーコード/QR領域をオンデバイスで検出し、マスク候補として返す。
/// 意味解釈は行わず「検出→候補提示→人間が最終確認」に徹する。
enum DetectionService {
    static func detectCandidates(in image: UIImage) async throws -> [MaskRegion] {
        guard let cgImage = image.cgImage else { return [] }
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation)

        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .fast
        textRequest.usesLanguageCorrection = false

        let barcodeRequest = VNDetectBarcodesRequest()

        try handler.perform([textRequest, barcodeRequest])

        var regions: [MaskRegion] = []

        if let textResults = textRequest.results {
            regions += textResults.map {
                MaskRegion(boundingBox: $0.boundingBox, kind: .text)
            }
        }

        if let barcodeResults = barcodeRequest.results {
            regions += barcodeResults.map {
                MaskRegion(boundingBox: $0.boundingBox, kind: .barcode)
            }
        }

        return regions
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
