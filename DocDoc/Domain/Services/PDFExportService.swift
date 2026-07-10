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
    static func createPDF(from document: ScannedDocument, options: PDFExportOptions) throws -> Data {
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

    static func estimatedSize(for document: ScannedDocument, options: PDFExportOptions) -> Int {
        (try? createPDF(from: document, options: options).count) ?? document.pagesCount * 140_000
    }

    private static func pageBounds(for image: UIImage, orientation: PDFOrientation) -> CGRect {
        let pixelSize = image.pixelSize
        var width = pixelSize.width
        var height = pixelSize.height

        switch orientation {
        case .portrait where width > height:
            swap(&width, &height)
        case .landscape where height > width:
            swap(&width, &height)
        case .auto, .portrait, .landscape:
            break
        }

        return CGRect(x: 0, y: 0, width: width, height: height)
    }

    private static func draw(image: UIImage, in bounds: CGRect, options: PDFExportOptions) {
        if options.compress {
            let jpegData = image.jpegData(compressionQuality: options.quality.compressionQuality)
            if let jpegData, let compressed = UIImage(data: jpegData) {
                compressed.draw(in: bounds)
                return
            }
        }
        image.draw(in: bounds)
    }
}
