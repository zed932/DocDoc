//
//  ScannedDocument.swift
//  DocDoc
//

import UIKit

struct ScannedPage: Identifiable {
    let id: UUID
    var originalImage: UIImage
    var processedImage: UIImage
    var rotation: Int

    init(
        id: UUID = UUID(),
        originalImage: UIImage,
        processedImage: UIImage,
        rotation: Int = 0
    ) {
        self.id = id
        self.originalImage = originalImage
        self.processedImage = processedImage
        self.rotation = rotation
    }

    var displayImage: UIImage {
        processedImage.rotated(degrees: rotation)
    }
}

struct ScannedDocument: Identifiable {
    let id: UUID
    var title: String
    var pages: [ScannedPage]
    let createdAt: Date
    var inferenceDuration: TimeInterval?

    init(
        id: UUID = UUID(),
        title: String = "Новый документ",
        pages: [ScannedPage],
        createdAt: Date = Date(),
        inferenceDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.pages = pages
        self.createdAt = createdAt
        self.inferenceDuration = inferenceDuration
    }

    var pagesCount: Int { pages.count }

    var exportFileName: String {
        let sanitized = title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        return "\(sanitized).pdf"
    }
}
