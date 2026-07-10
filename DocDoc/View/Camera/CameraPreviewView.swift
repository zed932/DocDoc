//
//  CameraPreviewView.swift
//  DocDoc
//

import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        // Контейнер задаётся с тем же соотношением 4:3, что и снимок,
        // поэтому aspectFill не обрезает и не растягивает кадр.
        view.previewLayer.videoGravity = .resizeAspectFill
        updateOrientation(for: view.previewLayer)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
        updateOrientation(for: uiView.previewLayer)
    }

    private func updateOrientation(for layer: AVCaptureVideoPreviewLayer) {
        guard let connection = layer.connection, connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .currentInterfaceOrientation
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

extension AVCaptureVideoOrientation {
    static var currentInterfaceOrientation: AVCaptureVideoOrientation {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .portrait
        }

        switch scene.interfaceOrientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return .portrait
        }
    }
}
