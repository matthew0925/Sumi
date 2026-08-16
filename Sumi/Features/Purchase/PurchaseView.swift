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
                Text("Sumi Plus")
                    .font(.title2.bold())
                Text("透かし解除に加え、安全余白とマスクプリセットを利用できます。一度のお支払いで、サブスクリプションはありません。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let package = purchaseManager.package {
                Text(package.storeProduct.localizedPriceString)
                    .font(.title.bold())
            }

            Spacer()

            Button {
                Task {
                    await purchaseManager.purchase()
                    if purchaseManager.isWatermarkRemoved {
                        Haptics.success()
                        flow.path.removeLast()
                    }
                }
            } label: {
                Text(purchaseManager.isWatermarkRemoved ? "購入済み" : "購入する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(purchaseManager.isWatermarkRemoved || purchaseManager.package == nil)
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
        .navigationTitle("Sumi Plus")
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
