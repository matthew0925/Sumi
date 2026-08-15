import SwiftUI

enum SumiTheme {
    static let ink = Color(red: 0.11, green: 0.12, blue: 0.12)
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let paperRaised = Color(red: 1.00, green: 0.99, blue: 0.97)
    static let teal = Color(red: 0.33, green: 0.56, blue: 0.55)
    static let mutedInk = Color(red: 0.40, green: 0.39, blue: 0.36)

    static let background = LinearGradient(
        colors: [paperRaised, paper],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct SumiCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .background(SumiTheme.paperRaised, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(SumiTheme.ink.opacity(0.07), lineWidth: 1)
            }
            .shadow(color: SumiTheme.ink.opacity(0.08), radius: 18, y: 8)
    }
}

struct SumiPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(minHeight: 54)
            .background(SumiTheme.ink.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SumiSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(SumiTheme.ink)
            .padding(.horizontal, 20)
            .frame(minHeight: 54)
            .background(SumiTheme.paperRaised.opacity(configuration.isPressed ? 0.65 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(SumiTheme.ink.opacity(0.13), lineWidth: 1)
            }
    }
}
