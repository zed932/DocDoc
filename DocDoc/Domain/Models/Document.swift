//
//  Document.swift
//  DocDoc
//

import Foundation

struct Document: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var pagesCount: Int
    var systemImage: String
    var dateLabel: String
    var fileSize: String?
    var pdfFileName: String
    var thumbnailFileName: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        pagesCount: Int,
        systemImage: String = "doc.fill",
        dateLabel: String,
        fileSize: String? = nil,
        pdfFileName: String,
        thumbnailFileName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.pagesCount = pagesCount
        self.systemImage = systemImage
        self.dateLabel = dateLabel
        self.fileSize = fileSize
        self.pdfFileName = pdfFileName
        self.thumbnailFileName = thumbnailFileName
        self.createdAt = createdAt
    }
}

extension Document {
    static var mockDocuments: [Document] {
        [
            Document(
                title: "Паспорт — стр. 2-3",
                pagesCount: 2,
                dateLabel: "Сегодня, 14:32",
                fileSize: "1.2 MB",
                pdfFileName: "mock-1.pdf"
            ),
            Document(
                title: "Договор аренды",
                pagesCount: 5,
                dateLabel: "Вчера",
                fileSize: "420 KB",
                pdfFileName: "mock-2.pdf"
            ),
            Document(
                title: "Справка с работы",
                pagesCount: 1,
                dateLabel: "28 июн",
                fileSize: "180 KB",
                pdfFileName: "mock-3.pdf"
            ),
            Document(
                title: "Мед. полис",
                pagesCount: 2,
                dateLabel: "15 июн",
                fileSize: "310 KB",
                pdfFileName: "mock-4.pdf"
            ),
        ]
    }

    static var mockDocument: Document { mockDocuments[0] }

    var pagesLabel: String {
        let suffix: String
        switch pagesCount % 10 {
        case 1 where pagesCount % 100 != 11: suffix = "стр."
        case 2...4 where !(11...14).contains(pagesCount % 100): suffix = "стр."
        default: suffix = "стр."
        }
        return "\(pagesCount) \(suffix)"
    }

    var metaLabel: String {
        if let fileSize {
            return "\(dateLabel) · \(pagesLabel) · \(fileSize)"
        }
        return "\(dateLabel) · \(pagesLabel)"
    }

    var homeMetaLabel: String {
        "\(dateLabel) · \(pagesLabel)"
    }

    var exportFileName: String {
        let sanitized = title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        return "\(sanitized).pdf"
    }
}
