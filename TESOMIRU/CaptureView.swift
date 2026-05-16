import SwiftUI
import PhotosUI
import UIKit

struct CaptureView: View {
    let onAnalyze: (UIImage) -> Void
    let onBack: () -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showImageSizeTip = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            RadialGradient(
                colors: [Color.appPrimary.opacity(0.10), Color.clear],
                center: .bottom,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                ScrollView {
                    VStack(spacing: 28) {
                        headerText
                        imagePreviewArea
                        captureButtons
                        if selectedImage != nil {
                            analyzeButton
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedImage = image
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(image: $selectedImage)
                .ignoresSafeArea()
        }
    }

    private var navigationBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("戻る")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color.appPrimaryLight)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var headerText: some View {
        VStack(spacing: 8) {
            Text("手のひらを")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Text("撮影してください")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Spacer().frame(height: 4)
            Text("手のひら全体がはっきり写るように\n明るい場所で撮影してください")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.appSubtext)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    private var imagePreviewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            selectedImage != nil
                                ? Color.appPrimary.opacity(0.6)
                                : Color.white.opacity(0.12),
                            style: StrokeStyle(lineWidth: 1.5, dash: selectedImage == nil ? [8, 6] : [])
                        )
                )

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.black.opacity(0.05))
                    )
            } else {
                emptyPreviewContent
            }
        }
        .frame(height: 280)
        .clipped()
    }

    private var emptyPreviewContent: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "hand.raised")
                    .font(.system(size: 36))
                    .foregroundColor(Color.appPrimaryLight)
            }
            Text("写真を選択または撮影してください")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.appSubtext)
                .multilineTextAlignment(.center)
        }
    }

    private var captureButtons: some View {
        HStack(spacing: 12) {
            Button {
                showCamera = true
            } label: {
                captureButtonLabel(icon: "camera.fill", title: "カメラで撮る")
            }
            .buttonStyle(.plain)

            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                captureButtonLabel(icon: "photo.fill", title: "ライブラリから")
            }
        }
    }

    private func captureButtonLabel(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.appCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var analyzeButton: some View {
        Button {
            guard let image = selectedImage else { return }
            onAnalyze(image)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                Text("この写真で解析する")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.appPrimary, Color(red: 0.35, green: 0.18, blue: 0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color.appPrimary.opacity(0.6), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    CaptureView(onAnalyze: { _ in }, onBack: {})
}
