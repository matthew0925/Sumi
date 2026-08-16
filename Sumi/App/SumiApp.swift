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
            MaskRegion(boundingBox: CGRect(x: 0.11, y: 0.86, width: 0.52, height: 0.075), kind: .text),
            MaskRegion(boundingBox: CGRect(x: 0.12, y: 0.72, width: 0.74, height: 0.08), kind: .text),
            MaskRegion(boundingBox: CGRect(x: 0.20, y: 0.245, width: 0.55, height: 0.08), kind: .text)
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
        UIImage(named: "ASOSampleLicense") ?? UIImage()
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
