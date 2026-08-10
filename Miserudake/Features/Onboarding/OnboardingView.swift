import SwiftUI

/// 初回起動時にのみ表示する、プライバシー方針の簡潔な説明。
/// 「画像は端末外に送信しない」という設計上の最大の訴求ポイントを最初に伝える。
struct OnboardingView: View {
    let onFinish: () -> Void

    private let points: [(icon: String, title: String, description: String)] = [
        ("iphone", "この端末の中だけで処理", "撮影した画像はサーバーに送信されません。すべてこの端末の中で完結します。"),
        ("eye.slash", "検出はあくまで候補", "個人情報らしき場所を自動検出しますが、最終的にマスクする範囲は必ずあなたが確認・調整します。"),
        ("person.crop.circle.badge.xmark", "アカウント登録は不要", "氏名・メールアドレスなどの登録は必要ありません。")
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("ミセルダケ")
                    .font(.largeTitle.bold())
                Text("必要な情報だけ、見せる。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 24) {
                ForEach(points, id: \.title) { point in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: point.icon)
                            .font(.title2)
                            .foregroundStyle(.tint)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(point.title)
                                .font(.headline)
                            Text(point.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onFinish) {
                Text("はじめる")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom)
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
