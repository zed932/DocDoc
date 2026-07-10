//
//  LibraryDocumentRow.swift
//  DocDoc
//

import SwiftUI

struct LibraryDocumentRow: View {
    let document: Document
    var onShare: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            DocPreviewPlaceholder()
                .frame(width: 44, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(document.metaLabel)
                    .font(.caption)
                    .foregroundStyle(DocDocTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                onShare?()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.body)
                    .foregroundStyle(DocDocTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .docDocCard()
    }
}

#Preview {
    LibraryDocumentRow(document: .mockDocument)
        .padding()
        .background(DocDocTheme.background)
}
