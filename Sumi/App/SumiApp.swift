import SwiftUI
import RevenueCat

@main
struct SumiApp: App {
    @StateObject private var flow = MaskingFlow()
    @StateObject private var purchaseManager: PurchaseManager
    @State private var didConfigureSnapshot = false

    init() {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        _purchaseManager = StateObject(wrappedValue: PurchaseManager())
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $flow.path) {
                HomeView()
                    .navigationDestination(for: MaskingFlow.Step.self) { step in
                        switch step {
                        case .documentType:
                            DocumentTypeView()
                        case .detectionPreview:
                            DetectionPreviewView()
                        case .maskingStyle:
                            MaskingStyleView()
                        case .export:
                            ExportPreviewView()
                        case .purchase:
                            PurchaseView()
                        }
                    }
            }
            .environmentObject(flow)
            .environmentObject(purchaseManager)
            .environmentObject(IntentBridge.shared)
            .task { configureSnapshotIfRequested() }
            .onChange(of: flow.path) { _, path in
                // 戻る操作で処理フローを終了した場合も、元画像と検出位置を残さない。
                if path.isEmpty, flow.sourceImage != nil {
                    flow.discardSensitiveWorkingData()
                }
            }
            .onOpenURL { url in
                handle(url: url)
            }
        }
    }

    /// App Store素材を実画面から再現可能に撮影するためのDebug専用入口。
    /// Releaseビルドにはサンプル書類も起動引数処理も含まれない。
    @MainActor
    private func configureSnapshotIfRequested() {
#if DEBUG
        guard !didConfigureSnapshot else { return }
        didConfigureSnapshot = true
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-ASOSnapshot"),
              arguments.indices.contains(flagIndex + 1) else { return }

        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        let step = arguments[flagIndex + 1]
        if step == "home" {
            flow.reset()
            return
        }

        flow.startFlow(with: Self.snapshotSampleImage())
        flow.documentType = .driversLicense
        flow.regions = [
            MaskRegion(boundingBox: CGRect(x: 0.16, y: 0.59, width: 0.68, height: 0.065), kind: .text),
            MaskRegion(boundingBox: CGRect(x: 0.16, y: 0.47, width: 0.68, height: 0.065), kind: .text),
            MaskRegion(boundingBox: CGRect(x: 0.16, y: 0.35, width: 0.46, height: 0.065), kind: .text),
            MaskRegion(boundingBox: CGRect(x: 0.67, y: 0.12, width: 0.18, height: 0.12), kind: .barcode)
        ]

        switch step {
        case "detection": flow.path = [.detectionPreview]
        case "style": flow.path = [.maskingStyle]
        case "export": flow.path = [.export]
        default: flow.path = [.detectionPreview]
        }
#endif
    }

#if DEBUG
    private static func snapshotSampleImage() -> UIImage {
        let size = CGSize(width: 900, height: 1_400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let ink = UIColor(red: 0.10, green: 0.11, blue: 0.11, alpha: 1)
            let muted = UIColor(red: 0.38, green: 0.36, blue: 0.32, alpha: 1)
            let title = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 48, weight: .bold), .foregroundColor: ink]
            let body = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 34, weight: .medium), .foregroundColor: ink]
            let caption = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 25, weight: .regular), .foregroundColor: muted]

            NSAttributedString(string: "SAMPLE ID CARD", attributes: title).draw(at: CGPoint(x: 70, y: 80))
            NSAttributedString(string: "撮影用サンプル（実在しない情報）", attributes: caption).draw(at: CGPoint(x: 72, y: 145))
            NSAttributedString(string: "氏名　墨田 すみ", attributes: body).draw(at: CGPoint(x: 140, y: 450))
            NSAttributedString(string: "住所　東京都サンプル区 1-2-3", attributes: body).draw(at: CGPoint(x: 140, y: 620))
            NSAttributedString(string: "生年月日　2000年1月1日", attributes: body).draw(at: CGPoint(x: 140, y: 790))
            NSAttributedString(string: "番号　1234 5678 9000", attributes: body).draw(at: CGPoint(x: 140, y: 960))

            ink.setFill()
            UIBezierPath(roundedRect: CGRect(x: 590, y: 1_055, width: 170, height: 170), cornerRadius: 18).fill()
            UIColor.white.setFill()
            for row in 0..<4 {
                for column in 0..<4 where (row + column).isMultiple(of: 2) {
                    context.fill(CGRect(x: 610 + column * 32, y: 1_075 + row * 32, width: 20, height: 20))
                }
            }
        }
    }
#endif

    /// Share Extension（sumi://share）とApp Intent双方の着地を1箇所で処理する。
    @MainActor
    private func handle(url: URL) {
        guard url.scheme == "sumi" else { return }
        switch url.host {
        case "share":
            guard let data = SharedContainer.consumeHandoffImage() else {
                flow.shareImportErrorMessage = "共有された画像を受け取れませんでした。共有メニューからもう一度お試しください。"
                return
            }
            guard let image = MaskingFlow.preparedForProcessing(data: data) else {
                flow.shareImportErrorMessage = "共有された画像を読み込めませんでした。もう一度お試しください。"
                return
            }
            flow.startFlow(with: image)
        default:
            break
        }
    }
}
