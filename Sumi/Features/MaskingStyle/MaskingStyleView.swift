import SwiftUI

struct MaskingStyleView: View {
    @EnvironmentObject private var flow: MaskingFlow

    var body: some View {
        VStack(spacing: 24) {
            if let preview = previewImage {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
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

            Spacer()

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
    }

    private var previewImage: UIImage? {
        guard let source = flow.sourceImage else { return nil }
        return ImageMaskingService.renderMaskedImage(
            source: source,
            regions: flow.regions,
            style: flow.maskingStyle,
            watermarked: false
        )
    }
}

#Preview {
    NavigationStack {
        MaskingStyleView().environmentObject(MaskingFlow())
    }
}
