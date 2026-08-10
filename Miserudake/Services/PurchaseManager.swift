import StoreKit

/// 透かし解除（非消費型・買い切り）の購入状態を管理する。
/// レシート検証はローカルの Transaction.currentEntitlements のみで完結し、サーバー通信は行わない。
@MainActor
final class PurchaseManager: ObservableObject {
    static let watermarkRemovalProductID = "com.matthew0925.miserudake.watermark_removal"

    @Published private(set) var isWatermarkRemoved = false
    @Published private(set) var product: Product?
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update: update)
            }
        }
        Task { await refresh() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refresh() async {
        do {
            let products = try await Product.products(for: [Self.watermarkRemovalProductID])
            product = products.first
        } catch {
            errorMessage = error.localizedDescription
        }
        await refreshEntitlements()
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = error.localizedDescription
        }
        await refreshEntitlements()
    }

    func purchase() async {
        guard let product else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(update: verification)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handle(update: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = update else { return }
        if transaction.productID == Self.watermarkRemovalProductID {
            isWatermarkRemoved = true
        }
        await transaction.finish()
    }

    private func refreshEntitlements() async {
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            if transaction.productID == Self.watermarkRemovalProductID {
                isWatermarkRemoved = true
            }
        }
    }
}
