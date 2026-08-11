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
        }
    }
}
