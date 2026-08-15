import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0
    private let pages = [
        OnboardingPage(icon: "viewfinder", title: "撮るだけで、候補を見つける", subtitle: "住所や生年月日など、隠したい部分を端末内で検出します。"),
        OnboardingPage(icon: "hand.draw.fill", title: "最後は、自分の目で確認", subtitle: "候補をタップで選び、足りない場所は指で追加できます。"),
        OnboardingPage(icon: "lock.shield.fill", title: "写真は、端末の外へ出さない", subtitle: "アカウント登録なし。画像処理はこの端末の中だけで完結します。")
    ]

    var body: some View {
        ZStack {
            SumiTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Sumi").font(.title2.bold()).foregroundStyle(SumiTheme.ink); Spacer()
                    if page < pages.count - 1 { Button("スキップ", action: onFinish).foregroundStyle(SumiTheme.mutedInk) }
                }.padding(24)
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 34) {
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 42, style: .continuous).fill(SumiTheme.paperRaised)
                                    .frame(width: 220, height: 220).shadow(color: SumiTheme.ink.opacity(0.10), radius: 24, y: 12)
                                Image(systemName: item.icon).font(.system(size: 76, weight: .light))
                                    .foregroundStyle(index == 2 ? SumiTheme.teal : SumiTheme.ink)
                            }
                            VStack(spacing: 12) {
                                Text(item.title).font(.title.bold()).foregroundStyle(SumiTheme.ink).multilineTextAlignment(.center)
                                Text(item.subtitle).foregroundStyle(SumiTheme.mutedInk).multilineTextAlignment(.center)
                            }.padding(.horizontal, 30)
                            Spacer()
                        }.tag(index)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .never))
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule().fill(index == page ? SumiTheme.ink : SumiTheme.ink.opacity(0.18)).frame(width: index == page ? 24 : 7, height: 7)
                    }
                }.padding(.bottom, 22)
                Button {
                    if page < pages.count - 1 { withAnimation(.snappy) { page += 1 } } else { onFinish() }
                } label: { Text(page < pages.count - 1 ? "次へ" : "Sumiをはじめる").frame(maxWidth: .infinity) }
                    .buttonStyle(SumiPrimaryButtonStyle()).padding(.horizontal, 24).padding(.bottom, 28)
            }
        }
    }
}

private struct OnboardingPage { let icon: String; let title: String; let subtitle: String }
#Preview { OnboardingView(onFinish: {}) }
