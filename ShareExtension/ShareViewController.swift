import UIKit
import UniformTypeIdentifiers

/// 写真アプリ等の共有シートから呼び出されるShare Extension本体。
/// 独自のUIは持たず、共有された画像をApp Groupコンテナに渡してから本体アプリを開き、
/// 検出・マスキング・書き出しの実際の操作はすべて本体アプリ側に任せる。
final class ShareViewController: UIViewController {
    private let spinner = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        spinner.startAnimating()

        handleSharedItem()
    }

    private func handleSharedItem() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachment = item.attachments?.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] loaded, _ in
            let data: Data?
            switch loaded {
            case let url as URL:
                // Files/iCloud Drive等から共有された場合、urlはセキュリティスコープ付き
                // （startAccessingSecurityScopedResourceを呼ばないと読み取りに失敗する）
                // であることがある。Photosからの共有等スコープが不要なケースでも
                // 呼び出し自体は安全なため、常に呼んでおく。
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing { url.stopAccessingSecurityScopedResource() }
                }
                data = try? Data(contentsOf: url)
            case let image as UIImage:
                data = image.jpegData(compressionQuality: 0.95)
            case let raw as Data:
                data = raw
            default:
                data = nil
            }

            DispatchQueue.main.async {
                guard let data else {
                    self?.extensionContext?.completeRequest(returningItems: nil)
                    return
                }
                SharedContainer.writeHandoffImage(data)
                self?.openHostApp()
            }
        }
    }

    private func openHostApp() {
        guard let url = URL(string: "sumi://share") else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }
        extensionContext?.open(url) { [weak self] _ in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
