//
//  DocumentStore.swift
//  DocDoc
//

import Foundation
import Observation
import UIKit

@Observable
final class DocumentStore {
    var documents: [Document]

    init(documents: [Document]? = nil) {
        if let documents {
            self.documents = documents
        } else {
            self.documents = DocumentFileStore.loadDocuments()
        }
    }

    @discardableResult
    func add(_ scanned: ScannedDocument, pdfData: Data) throws -> Document {
        let id = UUID()
        let pdfFileName = "\(id.uuidString).pdf"
        let pdfURL = try DocumentFileStore.savePDF(pdfData, fileName: pdfFileName)

        var thumbnailFileName: String?
        if let thumbnail = DocumentFileStore.makeThumbnail(from: pdfURL) {
            let name = "\(id.uuidString).jpg"
            try DocumentFileStore.saveThumbnail(thumbnail, fileName: name)
            thumbnailFileName = name
        }

        let fileSize = ByteCountFormatter.string(
            fromByteCount: Int64(pdfData.count),
            countStyle: .file
        )

        let document = Document(
            id: id,
            title: scanned.title,
            pagesCount: scanned.pagesCount,
            dateLabel: "Сегодня, \(formattedTime(scanned.createdAt))",
            fileSize: fileSize,
            pdfFileName: pdfFileName,
            thumbnailFileName: thumbnailFileName,
            createdAt: scanned.createdAt
        )

        documents.insert(document, at: 0)
        try persist()
        return document
    }

    func pdfURL(for document: Document) -> URL? {
        DocumentFileStore.pdfURL(for: document)
    }

    func thumbnail(for document: Document) -> UIImage? {
        DocumentFileStore.thumbnailImage(for: document)
    }

    private func persist() throws {
        try DocumentFileStore.saveDocuments(documents)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
