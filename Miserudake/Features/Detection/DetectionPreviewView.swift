import SwiftUI

struct DetectionPreviewView: View {
    @EnvironmentObject private var flow: MaskingFlow
    @State private var isDetecting = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            if let image = flow.sourceImage {
                GeometryReader { proxy in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: proxy.size.width, height: proxy.size.height)

                        ForEach($flow.regions) { $region in
                            RegionOverlay(region: $region, containerSize: proxy.size, imageSize: image.size)
                        }
                    }
                }
                .padding(.horizontal)
            }

            if isDetecting {
                ProgressView("個人情報らしき領域を検出中…")
                    .padding(.bottom)
            } else {
                Text("\(flow.regions.filter { $0.isEnabled }.count)件の候補をマスク対象に選択中。タップでON/OFFを切り替えられます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Button {
                    flow.path.append(.maskingStyle)
                } label: {
                    Text("次へ")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("検出結果の確認")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await runDetection()
        }
        .alert("検出に失敗しました", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func runDetection() async {
        guard let image = flow.sourceImage else { return }
        isDetecting = true
        do {
            flow.regions = try await DetectionService.detectCandidates(in: image)
        } catch {
            errorMessage = error.localizedDescription
        }
        isDetecting = false
    }
}

private struct RegionOverlay: View {
    @Binding var region: MaskRegion
    let containerSize: CGSize
    let imageSize: CGSize

    var body: some View {
        let rect = displayRect
        Rectangle()
            .fill(region.isEnabled ? Color.red.opacity(0.35) : Color.clear)
            .overlay(
                Rectangle()
                    .stroke(region.isEnabled ? Color.red : Color.gray, lineWidth: 2)
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .onTapGesture {
                region.isEnabled.toggle()
            }
    }

    /// 画像の aspect-fit 表示に合わせて、Visionの正規化座標（左下原点）を
    /// コンテナ内のスクリーン座標（左上原点）へ変換する。
    private var displayRect: CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        var fittedSize = containerSize
        var offset = CGPoint.zero
        if imageAspect > containerAspect {
            fittedSize.height = containerSize.width / imageAspect
            offset.y = (containerSize.height - fittedSize.height) / 2
        } else {
            fittedSize.width = containerSize.height * imageAspect
            offset.x = (containerSize.width - fittedSize.width) / 2
        }

        let box = region.boundingBox
        return CGRect(
            x: offset.x + box.origin.x * fittedSize.width,
            y: offset.y + (1 - box.origin.y - box.height) * fittedSize.height,
            width: box.width * fittedSize.width,
            height: box.height * fittedSize.height
        )
    }
}

#Preview {
    NavigationStack {
        DetectionPreviewView().environmentObject(MaskingFlow())
    }
}
