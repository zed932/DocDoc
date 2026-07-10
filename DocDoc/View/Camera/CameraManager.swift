//
//  CameraManager.swift
//  DocDoc
//

import AVFoundation
import Combine
import UIKit

final class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isAuthorized = false
    @Published var isCapturing = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?

    /// Соотношение сторон снимка (portrait). Preset `.photo` даёт 4:3 → в портрете 3:4.
    let captureAspectRatio: CGFloat = 3.0 / 4.0

    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "docdoc.camera.session")

    override init() {
        super.init()
        checkAuthorization()
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.configureSession()
                    }
                }
            }
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func prepareForDismiss() {
        sessionQueue.sync { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func clearCapturedImage() {
        capturedImage = nil
    }

    func capturePhoto() {
        guard !isCapturing else { return }

        isCapturing = true
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto

        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }

            // `.photo` — превью-фид и снимок имеют одинаковое соотношение 4:3,
            // что гарантирует WYSIWYG при aspect-constrained превью.
            self.session.sessionPreset = .photo

            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }

            guard
                let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: camera),
                self.session.canAddInput(input)
            else {
                DispatchQueue.main.async {
                    self.errorMessage = "Камера недоступна на этом устройстве."
                }
                return
            }

            self.session.addInput(input)

            guard self.session.canAddOutput(self.photoOutput) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Не удалось настроить вывод фото."
                }
                return
            }

            self.session.addOutput(self.photoOutput)
            self.photoOutput.maxPhotoQualityPrioritization = .balanced

            if let connection = self.photoOutput.connection(with: .video),
               connection.isVideoOrientationSupported {
                connection.videoOrientation = .currentInterfaceOrientation
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        defer {
            DispatchQueue.main.async {
                self.isCapturing = false
            }
        }

        if let error {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)?.normalizedOrientation() else {
            DispatchQueue.main.async {
                self.errorMessage = "Не удалось получить изображение с камеры."
            }
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}
