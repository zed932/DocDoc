//
//  Document.swift
//  DocDoc
//

import Foundation

struct Document: Identifiable, Hashable {
    let id: UUID
    var title: String
    var pagesCount: Int
    var systemImage: String
    var dateLabel: String
    var fileSize: String?

    init(
        id: UUID = UUID(),
        title: String,
        pagesCount: Int,
        systemImage: String = "doc.fill",
        dateLabel: String,
        fileSize: String? = nil
    ) {
        self.id = id
        self.title = title
        self.pagesCount = pagesCount
        self.systemImage = systemImage
        self.dateLabel = dateLabel
        self.fileSize = fileSize
    }
}

extension Document {
    static var mockDocuments: [Document] {
        [
            Document(title: "Паспорт — стр. 2-3", pagesCount: 2, dateLabel: "Сегодня, 14:32", fileSize: "1.2 MB"),
            Document(title: "Договор аренды", pagesCount: 5, dateLabel: "Вчера", fileSize: "420 KB"),
            Document(title: "Справка с работы", pagesCount: 1, dateLabel: "28 июн", fileSize: "180 KB"),
            Document(title: "Мед. полис", pagesCount: 2, dateLabel: "15 июн", fileSize: "310 KB"),
            Document(title: "Техническое задание", pagesCount: 24, systemImage: "doc.richtext.fill", dateLabel: "3 июл 2026", fileSize: "2.1 MB"),
            Document(title: "Доверенность", pagesCount: 3, systemImage: "doc.badge.plus", dateLabel: "2 июл 2026", fileSize: "540 KB"),
            Document(title: "Акт выполненных работ", pagesCount: 5, systemImage: "checkmark.doc.fill", dateLabel: "28 июн 2026", fileSize: "390 KB"),
            Document(title: "Приказ №127", pagesCount: 2, systemImage: "doc.text.magnifyingglass", dateLabel: "20 июн 2026", fileSize: "210 KB"),
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
}
