import SwiftUI

struct DetectionPreviewView: View {
    @EnvironmentObject private var flow: MaskingFlow
    @State private var isDetecting = true
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var initialRegions: [MaskRegion] = []
    @State private var showNoMaskConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            if let image = flow.sourceImage {
                GeometryReader { proxy in
                    let geometry = ImageDisplayGeometry(containerSize: proxy.size, imageSize: image.size)

                    ZStack(alignment: .topLeading) {
                        Color(uiColor: .secondarySystemBackground)

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
                                Haptics.light()
                            }
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                }
                .padding(.horizontal)
            }

            if isDetecting {
                ProgressView("個人情報らしき領域を検出中…")
                    .padding(.bottom)
            } else {
                if flow.regions.isEmpty {
                    Label("自動検出できませんでした。隠したい部分をドラッグで追加してください。", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                }

                VStack(spacing: 4) {
                    Text("\(flow.regions.filter { $0.isEnabled }.count)件の候補をマスク対象に選択中")
                    Text("タップでON/OFF・長押しで削除・ドラッグで領域を追加できます")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Button {
                        Haptics.medium()
                        flow.regions = initialRegions
                    } label: {
                        Label("リセット", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(flow.regions == initialRegions)

                    Button {
                        if flow.regions.contains(where: { $0.isEnabled }) {
                            flow.path.append(.maskingStyle)
                        } else {
                            showNoMaskConfirmation = true
                        }
                    } label: {
                        Text("次へ")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
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
        .alert("マスク対象がありません", isPresented: $showNoMaskConfirmation) {
            Button("戻って追加する", role: .cancel) {}
            Button("このまま進む（何も隠さない）", role: .destructive) {
                flow.path.append(.maskingStyle)
            }
        } message: {
            Text("有効なマスク領域が1件もありません。このまま書き出すと、隠すべき情報がそのまま見える状態で書き出されます。")
        }
    }

    private func runDetection() async {
        guard let image = flow.sourceImage else { return }
        isDetecting = true
        let detected = await DetectionService.detectCandidates(in: image)
        flow.regions = detected
        initialRegions = detected
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
            // 親（画像全体）に付けたドラッグで新規領域を追加するジェスチャーより、
            // 既存領域の上でのタップ・長押しを優先させるためhighPriorityGestureにする。
            .highPriorityGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        Haptics.warning()
                        onDelete()
                    }
                    .exclusively(before: TapGesture().onEnded {
                        Haptics.light()
                        region.isEnabled.toggle()
                    })
            )
            .accessibilityLabel(region.isEnabled ? "マスク対象。タップで解除" : "マスク対象外。タップで追加")
            .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack {
        DetectionPreviewView().environmentObject(MaskingFlow())
    }
}
