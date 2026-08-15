import SwiftUI

struct DocumentTypeView: View {
    @EnvironmentObject private var flow: MaskingFlow
    @State private var expandedType: DocumentType?

    var body: some View {
        List {
            Section {
                Text("書類の種類ごとに、一般的によく隠される項目を確認できます。検出結果は次の画面で手動調整できます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(DocumentType.allCases) { type in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button {
                                flow.documentType = type
                                flow.path.append(.detectionPreview)
                            } label: {
                                HStack {
                                    Text(type.displayName)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                withAnimation(.snappy) {
                                    expandedType = expandedType == type ? nil : type
                                }
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.tint)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(type.displayName)の隠すべき項目の例を表示")
                        }

                        if expandedType == type {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("一般的によく隠される項目の例")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ForEach(type.commonlyHiddenFields, id: \.self) { field in
                                    Label(field, systemImage: "eye.slash")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.leading, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("書類の種類")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("スキップ") {
                    flow.documentType = .other
                    flow.path.append(.detectionPreview)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DocumentTypeView().environmentObject(MaskingFlow())
    }
}
