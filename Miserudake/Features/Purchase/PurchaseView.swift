import SwiftUI

struct PurchaseView: View {
    @EnvironmentObject private var flow: MaskingFlow
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("透かしを解除")
                    .font(.title2.bold())
                Text("一度のお支払いで、以後すべての書き出しから透かしが消えます。サブスクリプションはありません。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let product = purchaseManager.product {
                Text(product.displayPrice)
                    .font(.title.bold())
            }

            Spacer()

            Button {
                Task {
                    await purchaseManager.purchase()
                    if purchaseManager.isWatermarkRemoved {
                        flow.path.removeLast()
                    }
                }
            } label: {
                Text(purchaseManager.isWatermarkRemoved ? "購入済み" : "購入する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(purchaseManager.isWatermarkRemoved || purchaseManager.product == nil)
            .padding(.horizontal)

            if !purchaseManager.isWatermarkRemoved {
                Button("購入を復元") {
                    Task { await purchaseManager.restorePurchases() }
                }
                .font(.footnote)
                .padding(.bottom)
            } else {
                Spacer().frame(height: 8)
            }
        }
        .navigationTitle("購入")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await purchaseManager.refresh()
        }
        .alert("エラー", isPresented: .constant(purchaseManager.errorMessage != nil)) {
            Button("OK") { purchaseManager.errorMessage = nil }
        } message: {
            Text(purchaseManager.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        PurchaseView()
            .environmentObject(MaskingFlow())
            .environmentObject(PurchaseManager())
    }
}
