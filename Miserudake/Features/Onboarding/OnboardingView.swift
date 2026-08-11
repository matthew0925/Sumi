import SwiftUI

/// 初回起動時にのみ表示するカルーセル形式のオンボーディング。
/// 「裏側の仕組み」ではなく、ユーザー視点での価値（何が嬉しいか）を1画面1メッセージで伝える。
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "text.viewfinder",
            colors: [Color(red: 0.30, green: 0.55, blue: 0.98), Color(red: 0.16, green: 0.32, blue: 0.78)],
            title: "撮るだけで、隠す場所が分かる",
            subtitle: "身分証を撮影すると、住所や生年月日など隠したい場所を自動で見つけます。"
        ),
        OnboardingPage(
            icon: "hand.tap.fill",
            colors: [Color(red: 0.98, green: 0.55, blue: 0.30), Color(red: 0.86, green: 0.30, blue: 0.24)],
            title: "最後はあなたの指で確認",
            subtitle: "隠す場所はタップでON・OFF、範囲もかんたんに調整できます。"
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            colors: [Color(red: 0.30, green: 0.78, blue: 0.60), Color(red: 0.14, green: 0.52, blue: 0.46)],
            title: "写真は、あなただけのもの",
            subtitle: "処理はすべてこの端末の中だけ。誰にも送信されません。"
        )
    ]

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    OnboardingPageView(page: item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            HStack {
                Spacer()
                if page < pages.count - 1 {
                    Button("スキップ") { onFinish() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            .padding(.top, 8)
            .padding(.trailing, 8)

            VStack {
                Spacer()

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(.white.opacity(index == page ? 1 : 0.35))
                            .frame(width: index == page ? 20 : 6, height: 6)
                            .animation(.snappy, value: page)
                    }
                }
                .padding(.bottom, 24)

                Button {
                    if page < pages.count - 1 {
                        withAnimation(.snappy) { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "次へ" : "はじめる")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.plain)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(pages[page].colors.last ?? .black)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .background(
            LinearGradient(colors: pages[page].colors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: page)
        )
    }
}

private struct OnboardingPage {
    let icon: String
    let colors: [Color]
    let title: String
    let subtitle: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 176, height: 176)
                Circle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 128, height: 128)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
