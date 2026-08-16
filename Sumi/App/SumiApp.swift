import SwiftUI
import RevenueCat

@main
struct SumiApp: App {
    @StateObject private var flow = MaskingFlow()
    @StateObject private var purchaseManager: PurchaseManager

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
