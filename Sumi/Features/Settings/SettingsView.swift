import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("購入") {
                    HStack {
                        Text("透かし解除")
                        Spacer()
                        Text(purchaseManager.isWatermarkRemoved ? "購入済み" : "未購入")
                            .foregroundStyle(.secondary)
                    }
                    Button("購入を復元") {
                        Task { await purchaseManager.restorePurchases() }
                    }
                    .disabled(purchaseManager.isWatermarkRemoved)
                }

                Section("プライバシー") {
                    VStack(alignment: .leading, spacing: 12) {
                        privacyItem(
                            icon: "network.slash",
                            title: "画像は外部に送信しません",
                            description: "撮影・選択した画像や検出結果は、サーバーへ一切送信されません。すべての処理はこの端末の中だけで完結します。"
                        )
                        privacyItem(
                            icon: "person.crop.circle.badge.xmark",
                            title: "アカウント登録は不要です",
                            description: "氏名・メールアドレス・電話番号などの収集は行いません。"
                        )
                        privacyItem(
                            icon: "location.slash",
                            title: "位置情報等の権限は要求しません",
                            description: "書き出し時にEXIF情報（位置情報を含む）を保持せず、新規画像として生成します。"
                        )
                        privacyItem(
                            icon: "trash",
                            title: "一時ファイルは自動で破棄されます",
                            description: "処理中の一時データはアプリのサンドボックス内にのみ保持され、書き出し完了後に破棄されます。"
                        )
                    }
                    .padding(.vertical, 4)
                }

                Section("サポート") {
                    Link(destination: SupportConfig.privacyPolicyURL) {
                        HStack {
                            Text("プライバシーポリシー")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.footnote)
                        }
                    }
                    if let mailURL = URL(string: "mailto:\(SupportConfig.supportEmail)") {
                        Link(destination: mailURL) {
                            HStack {
                                Text("お問い合わせ")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.footnote)
                            }
                        }
                    }
                }

                Section("このアプリについて") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func privacyItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView().environmentObject(PurchaseManager())
}
