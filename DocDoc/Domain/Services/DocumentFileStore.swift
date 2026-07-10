//
//  DocumentFileStore.swift
//  DocDoc
//

import Foundation
import PDFKit
import UIKit

enum DocumentFileStore {
    private static let rootFolderName = "DocDoc"
    private static let pdfsFolderName = "PDFs"
    private static let thumbnailsFolderName = "Thumbnails"
    private static let indexFileName = "documents.json"

    static var rootDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(rootFolderName, isDirectory: true)
    }

    static var pdfsDirectory: URL {
        rootDirectory.appendingPathComponent(pdfsFolderName, isDirectory: true)
    }

    static var thumbnailsDirectory: URL {
        rootDirectory.appendingPathComponent(thumbnailsFolderName, isDirectory: true)
    }

    static var indexURL: URL {
        rootDirectory.appendingPathComponent(indexFileName)
    }

    static func prepareDirectories() throws {
        try FileManager.default.createDirectory(at: pdfsDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
    }

    static func loadDocuments() -> [Document] {
        guard FileManager.default.fileExists(atPath: indexURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: indexURL)
            return try JSONDecoder().decode([Document].self, from: data)
        } catch {
            return []
        }
    }

    static func saveDocuments(_ documents: [Document]) throws {
        try prepareDirectories()
        let data = try JSONEncoder().encode(documents)
        try data.write(to: indexURL, options: .atomic)
    }

    static func savePDF(_ data: Data, fileName: String) throws -> URL {
        try prepareDirectories()
        let url = pdfsDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func pdfURL(for document: Document) -> URL? {
        let url = pdfsDirectory.appendingPathComponent(document.pdfFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func pdfData(for document: Document) -> Data? {
        guard let url = pdfURL(for: document) else { return nil }
        return try? Data(contentsOf: url)
    }

    static func saveThumbnail(_ image: UIImage, fileName: String) throws {
        try prepareDirectories()
        let url = thumbnailsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.82) else { return }
        try data.write(to: url, options: .atomic)
    }

    static func thumbnailImage(for document: Document) -> UIImage? {
        guard let fileName = document.thumbnailFileName else { return nil }
        let url = thumbnailsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func makeThumbnail(from pdfURL: URL, maxDimension: CGFloat = 160) -> UIImage? {
        guard let page = PDFDocument(url: pdfURL)?.page(at: 0) else { return nil }

        let pageRect = page.bounds(for: .mediaBox)
        let scale = maxDimension / max(pageRect.width, pageRect.height)
        let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let cgContext = context.cgContext
            cgContext.translateBy(x: 0, y: size.height)
            cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: cgContext)
        }
    }
}
