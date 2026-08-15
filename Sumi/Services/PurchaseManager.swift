import Combine
import Foundation
import RevenueCat

/// 透かし解除（非消費型・買い切り）の購入状態をRevenueCat経由で管理する。
/// レシート検証・エンタイトルメント判定はRevenueCatに委譲し、独自サーバーは持たない。
@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var isWatermarkRemoved = false
    @Published private(set) var package: Package?
    @Published var errorMessage: String?

    private var delegateProxy: PurchasesDelegateProxy?

    init() {
        let proxy = PurchasesDelegateProxy { [weak self] customerInfo in
            Task { @MainActor in self?.apply(customerInfo) }
        }
        delegateProxy = proxy
        Purchases.shared.delegate = proxy
        Task { await refresh() }
    }

    func refresh() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            let offering = RevenueCatConfig.defaultOfferingID.flatMap { offerings.offering(identifier: $0) } ?? offerings.current
            package = offering?.availablePackages.first
        } catch {
            errorMessage = error.localizedDescription
        }
        await refreshEntitlements()
    }

    func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            apply(customerInfo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase() async {
        guard let package else { return }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            apply(result.customerInfo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            apply(customerInfo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ customerInfo: CustomerInfo) {
        isWatermarkRemoved = customerInfo.entitlements[RevenueCatConfig.watermarkRemovalEntitlement]?.isActive == true
    }
}

/// PurchasesDelegateはNSObjectProtocol準拠を要求するため、@MainActorなPurchaseManager本体とは
/// 切り離した薄いプロキシで受け、更新をクロージャ経由でPurchaseManagerに橋渡しする。
private final class PurchasesDelegateProxy: NSObject, PurchasesDelegate {
    private let onUpdate: (CustomerInfo) -> Void

    init(onUpdate: @escaping (CustomerInfo) -> Void) {
        self.onUpdate = onUpdate
    }

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        onUpdate(customerInfo)
    }
}
