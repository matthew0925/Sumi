import SwiftUI
import PhotosUI

struct HomeView: View {
    @EnvironmentObject private var flow: MaskingFlow
    @EnvironmentObject private var intentBridge: IntentBridge
    @State private var showCamera = false
    @State private var photoPickerItem: PhotosPickerItem?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSettings = false
    @State private var showCameraUnavailableAlert = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Sumi")
                    .font(.largeTitle.bold())
                Text("必要な情報だけ、見せる。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                Button {
                    openCameraIfAvailable()
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
        .alert("カメラが利用できません", isPresented: $showCameraUnavailableAlert) {
            Button("OK") {}
        } message: {
            Text("この端末ではカメラを利用できません。カメラロールから画像を選択してください。")
        }
        .alert("読み込みに失敗しました", isPresented: .constant(flow.shareImportErrorMessage != nil)) {
            Button("OK") { flow.shareImportErrorMessage = nil }
        } message: {
            Text(flow.shareImportErrorMessage ?? "")
        }
        .onChange(of: intentBridge.pendingAction) { _, action in
            guard action == .openCamera else { return }
            intentBridge.pendingAction = nil
            // 既に検出・書き出しなど進行中のフローがある状態でSiri等から呼ばれた場合、
            // カメラを問答無用で開くと進行中の作業（検出結果の手動調整など）が
            // 確認なしに失われてしまう。ホーム画面にいる（＝進行中のフローがない）
            // ときだけ反応する。
            guard flow.path.isEmpty else { return }
            openCameraIfAvailable()
        }
    }

    private func openCameraIfAvailable() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showCamera = true
        } else {
            showCameraUnavailableAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        HomeView().environmentObject(MaskingFlow())
    }
}
