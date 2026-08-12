import AppIntents

/// Siri・Spotlight・ショートカットアプリから本アプリを直接開くためのApp Intent。
/// 検出〜手動確認〜書き出しは必ずユーザー操作を伴うため、Intent側では
/// 「アプリを開いて撮影画面から始める」ところまでを担当する。
struct OpenMiserudakeIntent: AppIntent {
    static var title: LocalizedStringResource = "ミセルダケで身分証を隠す"
    static var description = IntentDescription("ミセルダケを開いて、身分証の撮影からマスキングを始めます。")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentBridge.shared.pendingAction = .openCamera
        return .result()
    }
}

struct MiserudakeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenMiserudakeIntent(),
            phrases: [
                "\(.applicationName)で身分証を隠す",
                "\(.applicationName)を開く"
            ],
            shortTitle: "身分証を隠す",
            systemImageName: "text.viewfinder"
        )
    }
}

/// App IntentとSwiftUI側（HomeView）の間で、起動直後に行うべきアクションを橋渡しする。
/// App Intentは@MainActorなView階層の外から実行されるため、単純な共有状態で受け渡す。
@MainActor
final class IntentBridge: ObservableObject {
    enum PendingAction: Equatable {
        case openCamera
    }

    static let shared = IntentBridge()

    @Published var pendingAction: PendingAction?

    private init() {}
}
