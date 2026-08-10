import SwiftUI

struct ExportPreviewView: View {
    @EnvironmentObject private var flow: MaskingFlow
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var saveMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal)
            }

            if !purchaseManager.isWatermarkRemoved {
                Text("無料版では書き出し画像に控えめな透かしが入ります。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    saveToPhotos()
                } label: {
                    Text("保存する")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

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
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("書き出し")
        .navigationBarTitleDisplayMode(.inline)
        .alert("保存しました", isPresented: .constant(saveMessage != nil)) {
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
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        saveMessage = "カメラロールに保存しました。"
    }
}

#Preview {
    NavigationStack {
        ExportPreviewView()
            .environmentObject(MaskingFlow())
            .environmentObject(PurchaseManager())
    }
}
