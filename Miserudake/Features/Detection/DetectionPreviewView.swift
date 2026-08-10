import SwiftUI

struct DetectionPreviewView: View {
    @EnvironmentObject private var flow: MaskingFlow
    @State private var isDetecting = true
    @State private var errorMessage: String?
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?

    var body: some View {
        VStack(spacing: 16) {
            if let image = flow.sourceImage {
                GeometryReader { proxy in
                    let geometry = ImageDisplayGeometry(containerSize: proxy.size, imageSize: image.size)

                    ZStack(alignment: .topLeading) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: proxy.size.width, height: proxy.size.height)

                        ForEach($flow.regions) { $region in
                            RegionOverlay(region: $region, geometry: geometry) {
                                flow.regions.removeAll { $0.id == region.id }
                            }
                        }

                        if let start = dragStart, let current = dragCurrent {
                            let rect = CGRect(
                                x: min(start.x, current.x),
                                y: min(start.y, current.y),
                                width: abs(current.x - start.x),
                                height: abs(current.y - start.y)
                            )
                            Rectangle()
                                .fill(Color.blue.opacity(0.25))
                                .overlay(Rectangle().stroke(Color.blue, lineWidth: 2))
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { value in
                                if dragStart == nil { dragStart = value.startLocation }
                                dragCurrent = value.location
                            }
                            .onEnded { value in
                                defer {
                                    dragStart = nil
                                    dragCurrent = nil
                                }
                                let screenRect = CGRect(
                                    x: min(value.startLocation.x, value.location.x),
                                    y: min(value.startLocation.y, value.location.y),
                                    width: abs(value.location.x - value.startLocation.x),
                                    height: abs(value.location.y - value.startLocation.y)
                                )
                                guard screenRect.width > 12, screenRect.height > 12 else { return }
                                let normalized = geometry.normalizedRect(fromScreenRect: screenRect)
                                flow.regions.append(MaskRegion(boundingBox: normalized, kind: .manual))
                            }
                    )
                }
                .padding(.horizontal)
            }

            if isDetecting {
                ProgressView("個人情報らしき領域を検出中…")
                    .padding(.bottom)
            } else {
                VStack(spacing: 4) {
                    Text("\(flow.regions.filter { $0.isEnabled }.count)件の候補をマスク対象に選択中")
                    Text("タップでON/OFF・長押しで削除・ドラッグで領域を追加できます")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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

/// 画像の aspect-fit 表示と、Visionの正規化座標（左下原点）・
/// 画面上のポイント座標（左上原点）との相互変換をまとめたヘルパー。
private struct ImageDisplayGeometry {
    let containerSize: CGSize
    let imageSize: CGSize

    private var fittedSize: CGSize {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        if imageAspect > containerAspect {
            return CGSize(width: containerSize.width, height: containerSize.width / imageAspect)
        } else {
            return CGSize(width: containerSize.height * imageAspect, height: containerSize.height)
        }
    }

    private var offset: CGPoint {
        CGPoint(
            x: (containerSize.width - fittedSize.width) / 2,
            y: (containerSize.height - fittedSize.height) / 2
        )
    }

    func screenRect(fromNormalizedRect box: CGRect) -> CGRect {
        let size = fittedSize
        let origin = offset
        return CGRect(
            x: origin.x + box.origin.x * size.width,
            y: origin.y + (1 - box.origin.y - box.height) * size.height,
            width: box.width * size.width,
            height: box.height * size.height
        )
    }

    func normalizedRect(fromScreenRect rect: CGRect) -> CGRect {
        let size = fittedSize
        let origin = offset
        guard size.width > 0, size.height > 0 else { return .zero }
        let x = (rect.origin.x - origin.x) / size.width
        let y = 1 - (rect.origin.y - origin.y + rect.height) / size.height
        return CGRect(
            x: min(max(x, 0), 1),
            y: min(max(y, 0), 1),
            width: min(rect.width / size.width, 1),
            height: min(rect.height / size.height, 1)
        )
    }
}

private struct RegionOverlay: View {
    @Binding var region: MaskRegion
    let geometry: ImageDisplayGeometry
    let onDelete: () -> Void

    var body: some View {
        let rect = geometry.screenRect(fromNormalizedRect: region.boundingBox)
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
            .onLongPressGesture {
                onDelete()
            }
    }
}

#Preview {
    NavigationStack {
        DetectionPreviewView().environmentObject(MaskingFlow())
    }
}
