//
//  PDFExportService.swift
//  DocDoc
//

import PDFKit
import UIKit

enum PDFExportQuality: String, CaseIterable, Identifiable {
    case high = "Высокое"
    case medium = "Среднее"
    case low = "Низкое (меньше размер)"

    var id: String { rawValue }

    var compressionQuality: CGFloat {
        switch self {
        case .high: return 0.92
        case .medium: return 0.75
        case .low: return 0.55
        }
    }
}

enum PDFOrientation: String, CaseIterable, Identifiable {
    case auto = "Авто"
    case portrait = "Книжная"
    case landscape = "Альбомная"

    var id: String { rawValue }
}

struct PDFExportOptions {
    var quality: PDFExportQuality = .high
    var orientation: PDFOrientation = .auto
    var compress: Bool = true
}

enum PDFExportError: LocalizedError {
    case noPages
    case creationFailed

    var errorDescription: String? {
        switch self {
        case .noPages: return "Нет страниц для экспорта."
        case .creationFailed: return "Не удалось создать PDF."
        }
    }
}

enum PDFExportService {
    private static let a4Portrait = CGSize(width: 595.2, height: 841.8)
    private static let pageMargin: CGFloat = 36

    nonisolated static func createPDF(from document: ScannedDocument, options: PDFExportOptions) throws -> Data {
        guard !document.pages.isEmpty else { throw PDFExportError.noPages }

        let pdfMeta = [
            kCGPDFContextCreator: "DocDoc",
            kCGPDFContextTitle: document.title
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMeta as [String: Any]

        let pageImages = document.pages.map(\.displayImage)
        let firstBounds = pageBounds(for: pageImages[0], orientation: options.orientation)

        let renderer = UIGraphicsPDFRenderer(bounds: firstBounds, format: format)
        return renderer.pdfData { context in
            for image in pageImages {
                let bounds = pageBounds(for: image, orientation: options.orientation)
                context.beginPage(withBounds: bounds, pageInfo: [:])
                draw(image: image, in: bounds, options: options)
            }
        }
    }

    nonisolated static func estimatedSize(for document: ScannedDocument, options: PDFExportOptions) -> Int {
        document.pagesCount * estimatedBytesPerPage(options: options)
    }

    private nonisolated static func estimatedBytesPerPage(options: PDFExportOptions) -> Int {
        switch options.quality {
        case .high: return 280_000
        case .medium: return 180_000
        case .low: return 110_000
        }
    }

    private nonisolated static func pageBounds(for image: UIImage, orientation: PDFOrientation) -> CGRect {
        let resolved = resolvedOrientation(for: image, orientation: orientation)
        let size = resolved == .landscape
            ? CGSize(width: a4Portrait.height, height: a4Portrait.width)
            : a4Portrait
        return CGRect(origin: .zero, size: size)
    }

    private nonisolated static func resolvedOrientation(
        for image: UIImage,
        orientation: PDFOrientation
    ) -> PDFOrientation {
        switch orientation {
        case .auto:
            let size = image.pixelSize
            return size.width > size.height ? .landscape : .portrait
        case .portrait, .landscape:
            return orientation
        }
    }

    private nonisolated static func draw(image: UIImage, in bounds: CGRect, options: PDFExportOptions) {
        let contentRect = bounds.insetBy(dx: pageMargin, dy: pageMargin)
        let imageSize = image.pixelSize
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let scale = min(contentRect.width / imageSize.width, contentRect.height / imageSize.height)
        let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = CGRect(
            x: contentRect.midX - drawSize.width / 2,
            y: contentRect.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )

        UIColor.white.setFill()
        UIRectFill(bounds)

        let renderedImage: UIImage
        if options.compress, let jpegData = image.jpegData(compressionQuality: options.quality.compressionQuality),
           let compressed = UIImage(data: jpegData) {
            renderedImage = compressed
        } else {
            renderedImage = image
        }

        renderedImage.draw(in: drawRect)
    }
}
