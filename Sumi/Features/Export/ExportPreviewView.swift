import Photos
import SwiftUI

struct ExportPreviewView: View {
    @EnvironmentObject private var flow: MaskingFlow
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var saveMessage: String?
    @State private var saveFailed = false
    @State private var zoomScale: CGFloat = 1
    @State private var lastZoomScale: CGFloat = 1
    @State private var didSave = false

    var body: some View {
        VStack(spacing: 24) {
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(zoomScale)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                    }
                    .padding(.horizontal)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                zoomScale = min(max(lastZoomScale * value, 1), 4)
                            }
                            .onEnded { _ in
                                lastZoomScale = zoomScale
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.snappy) {
                            zoomScale = 1
                            lastZoomScale = 1
                        }
                    }
                    .accessibilityLabel("書き出しプレビュー。ダブルタップで拡大をリセット")
            }

            if !purchaseManager.isWatermarkRemoved {
                Text("無料版では書き出し画像に控えめな透かしが入ります。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        saveToPhotos()
                    } label: {
                        Label("保存する", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if let image = renderedImage {
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview("ミセルダケで作成した画像", image: Image(uiImage: image))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }

                if !purchaseManager.isWatermarkRemoved {
                    Button {
                        flow.path.append(.purchase)
                    } label: {
                        Text("透かしを解除する（買い切り）")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                if didSave {
                    Button {
                        flow.reset()
                    } label: {
                        Text("最初からやり直す")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("書き出し")
        .navigationBarTitleDisplayMode(.inline)
        .alert(saveFailed ? "保存できませんでした" : "保存しました", isPresented: .constant(saveMessage != nil)) {
            Button("OK") { saveMessage = nil }
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private var renderedImage: UIImage? {
        guard let source = flow.sourceImage else { return nil }
        return ImageMaskingService.renderMaskedImage(
            source: source,
            regions: flow.regions,
            style: flow.maskingStyle,
            watermarked: !purchaseManager.isWatermarkRemoved
        )
    }

    private func saveToPhotos() {
        guard let image = renderedImage else { return }
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            Task { @MainActor in
                if success {
                    saveFailed = false
                    saveMessage = "カメラロールに保存しました。"
                    didSave = true
                    Haptics.success()
                } else {
                    saveFailed = true
                    saveMessage = "写真ライブラリへのアクセスが許可されていないか、保存に失敗しました。設定アプリから写真へのアクセスを確認してください。"
                    Haptics.warning()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExportPreviewView()
            .environmentObject(MaskingFlow())
            .environmentObject(PurchaseManager())
    }
}
