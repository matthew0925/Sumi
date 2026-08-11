import SwiftUI
import PhotosUI

struct HomeView: View {
    @EnvironmentObject private var flow: MaskingFlow
    @State private var showCamera = false
    @State private var photoPickerItem: PhotosPickerItem?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("ミセルダケ")
                    .font(.largeTitle.bold())
                Text("必要な情報だけ、見せる。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                Button {
                    showCamera = true
                } label: {
                    Label("撮影する", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("カメラロールから選択", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 32)

            Spacer()

            Text("画像は端末の外に送信されません。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView { image in
                showCamera = false
                if let image {
                    flow.startFlow(with: image)
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: photoPickerItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                flow.startFlow(with: image)
                photoPickerItem = nil
            }
        }
        .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("設定")
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView().environmentObject(MaskingFlow())
    }
}
