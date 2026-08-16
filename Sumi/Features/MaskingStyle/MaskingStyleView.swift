import SwiftUI

struct MaskingStyleView: View {
    @EnvironmentObject private var flow: MaskingFlow
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var presets: [MaskingPreset] = []
    @State private var presetName = ""
    @State private var showingPresetName = false
    @State private var presetMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(spacing: 24) {
                    if let preview = previewImage {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 420)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                            }
                            .padding(.horizontal)
                    }

                    Picker("マスキングスタイル", selection: $flow.maskingStyle) {
                        ForEach(MaskingStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("安全余白", systemImage: "rectangle.expand.vertical")
                            Spacer()
                            if !purchaseManager.isWatermarkRemoved {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline.weight(.semibold))

                        Picker("安全余白", selection: $flow.safetyPadding) {
                            ForEach(MaskSafetyPadding.allCases) { padding in
                                Text(padding.displayName).tag(padding)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(!purchaseManager.isWatermarkRemoved)

                        Text("検出枠より外側まで隠し、文字の端が残るリスクを減らします。")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            guard purchaseManager.isWatermarkRemoved else {
                                flow.path.append(.purchase)
                                return
                            }
                            presetName = ""
                            showingPresetName = true
                        } label: {
                            Label("現在の設定をプリセットに保存", systemImage: purchaseManager.isWatermarkRemoved ? "plus.square.on.square" : "lock")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        if purchaseManager.isWatermarkRemoved, !presets.isEmpty {
                            Menu {
                                Section("適用") {
                                    ForEach(presets) { preset in
                                        Button(preset.name) { apply(preset) }
                                    }
                                }
                                Section("削除") {
                                    ForEach(presets) { preset in
                                        Button(preset.name, role: .destructive) { delete(preset) }
                                    }
                                }
                            } label: {
                                Label("保存済みプリセット（\(presets.count)）", systemImage: "square.stack")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
            }

            Button {
                flow.path.append(.export)
            } label: {
                Text("次へ")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("マスキングスタイル")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { presets = MaskingPresetStore.load() }
        .alert("プリセット名", isPresented: $showingPresetName) {
            TextField("例：SNS投稿用", text: $presetName)
            Button("キャンセル", role: .cancel) {}
            Button("保存") { savePreset() }
                .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("マスク方式・安全余白・現在選択中の対象種別を保存します。")
        }
        .alert("プリセット", isPresented: Binding(
            get: { presetMessage != nil },
            set: { if !$0 { presetMessage = nil } }
        )) {
            Button("OK") { presetMessage = nil }
        } message: {
            Text(presetMessage ?? "")
        }
    }

    private var previewImage: UIImage? {
        guard let source = flow.sourceImage else { return nil }
        return ImageMaskingService.renderMaskedImage(
            source: source,
            regions: flow.regions,
            style: flow.maskingStyle,
            safetyPadding: flow.safetyPadding,
            watermarked: false
        )
    }

    private func savePreset() {
        let name = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let enabledKinds = Set(flow.regions.filter(\.isEnabled).map(\.kind))
        let preset = MaskingPreset(
            name: name,
            style: flow.maskingStyle,
            safetyPadding: flow.safetyPadding,
            enabledKinds: enabledKinds
        )
        presets.removeAll { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
        presets.append(preset)
        presetMessage = MaskingPresetStore.save(presets) ? "「\(name)」を保存しました。" : "保存できませんでした。"
    }

    private func apply(_ preset: MaskingPreset) {
        flow.maskingStyle = preset.style
        flow.safetyPadding = preset.safetyPadding
        flow.regions = MaskRegion.applying(enabledKinds: preset.enabledKinds, to: flow.regions)
        Haptics.light()
    }

    private func delete(_ preset: MaskingPreset) {
        presets.removeAll { $0.id == preset.id }
        _ = MaskingPresetStore.save(presets)
    }
}

#Preview {
    NavigationStack {
        MaskingStyleView()
            .environmentObject(MaskingFlow())
            .environmentObject(PurchaseManager())
    }
}
