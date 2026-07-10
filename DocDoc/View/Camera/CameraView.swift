//
//  CameraView.swift
//  DocDoc
//

import PhotosUI
import SwiftUI

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedPhotoItem: PhotosPickerItem?

    let onCapture: (UIImage) -> Void

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Spacer(minLength: 0)

            viewfinder

            Text("Наведите на документ")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 12)

            Spacer(minLength: 0)

            bottomBar
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) { _, image in
            guard let image else { return }
            cameraManager.prepareForDismiss()
            onCapture(image)
            cameraManager.clearCapturedImage()
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        onCapture(image)
                    }
                }
            }
        }
        .alert(
            "Ошибка камеры",
            isPresented: Binding(
                get: { cameraManager.errorMessage != nil },
                set: { if !$0 { cameraManager.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cameraManager.errorMessage ?? "")
        }
    }

    // MARK: - Viewfinder (preview + рамка в одном контейнере)

    @ViewBuilder
    private var viewfinder: some View {
        if cameraManager.isAuthorized {
            ZStack {
                CameraPreviewView(session: cameraManager.session)

                DocumentFrameOverlay()
            }
            .aspectRatio(cameraManager.captureAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipped()
        } else {
            permissionView
                .aspectRatio(cameraManager.captureAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Controls

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.35), in: Circle())
            }

            Spacer()

            Image(systemName: "bolt.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.35), in: Circle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var bottomBar: some View {
        HStack(alignment: .center) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.2))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundStyle(.white)
                    }
            }

            Spacer()

            Button {
                cameraManager.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                }
            }
            .disabled(!cameraManager.isAuthorized || cameraManager.isCapturing)
            .opacity(cameraManager.isCapturing ? 0.5 : 1)

            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath.camera")
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
        }
        .padding(.horizontal, 36)
        .padding(.bottom, 36)
    }

    private var permissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.8))
            Text("Нужен доступ к камере")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Разрешите доступ в настройках, чтобы сканировать документы.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Рамка документа (рисуется поверх реального превью)

private struct DocumentFrameOverlay: View {
  private let inset: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            let rect = CGRect(
                x: inset,
                y: inset,
                width: geometry.size.width - inset * 2,
                height: geometry.size.height - inset * 2
            )

            ZStack {
                Path { path in
                    path.addRect(rect)
                }
                .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))

                CornerMark(position: .topLeft, rect: rect)
                CornerMark(position: .topRight, rect: rect)
                CornerMark(position: .bottomLeft, rect: rect)
                CornerMark(position: .bottomRight, rect: rect)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct CornerMark: View {
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    let position: Position
    let rect: CGRect
    private let length: CGFloat = 28

    var body: some View {
        Path { path in
            switch position {
            case .topLeft:
                path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
            case .topRight:
                path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
            case .bottomLeft:
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY - length))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX + length, y: rect.maxY))
            case .bottomRight:
                path.move(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
            }
        }
        .stroke(Color.white, lineWidth: 3)
    }
}

#Preview {
    CameraView { _ in }
}
