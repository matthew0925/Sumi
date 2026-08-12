import SwiftUI
import RevenueCat

@main
struct MiserudakeApp: App {
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
            .onOpenURL { url in
                handle(url: url)
            }
        }
    }

    /// Share Extension（miserudake://share）とApp Intent双方の着地を1箇所で処理する。
    @MainActor
    private func handle(url: URL) {
        guard url.scheme == "miserudake" else { return }
        switch url.host {
        case "share":
            guard let data = SharedContainer.consumeHandoffImage(),
                  let image = UIImage(data: data) else { return }
            flow.startFlow(with: image)
        default:
            break
        }
    }
}
