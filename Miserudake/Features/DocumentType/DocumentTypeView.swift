import SwiftUI

struct DocumentTypeView: View {
    @EnvironmentObject private var flow: MaskingFlow

    var body: some View {
        List {
            Section {
                Text("書類の種類を選ぶと、隠すべき項目の初期候補を絞り込めます。あとで手動でも調整できます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(DocumentType.allCases) { type in
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
