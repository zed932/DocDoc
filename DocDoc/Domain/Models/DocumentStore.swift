//
//  DocumentStore.swift
//  DocDoc
//

import Foundation
import Observation

@Observable
final class DocumentStore {
    var documents: [Document]

    init(documents: [Document] = []) {
        self.documents = documents
    }

    func add(_ scanned: ScannedDocument, pdfSize: Int? = nil) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM yyyy"

        let fileSize: String?
        if let pdfSize {
            fileSize = ByteCountFormatter.string(fromByteCount: Int64(pdfSize), countStyle: .file)
        } else {
            fileSize = nil
        }

        let document = Document(
            title: scanned.title,
            pagesCount: scanned.pagesCount,
            dateLabel: "Сегодня, \(formattedTime(scanned.createdAt))",
            fileSize: fileSize
        )
        documents.insert(document, at: 0)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
