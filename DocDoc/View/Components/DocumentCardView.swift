//
//  DocumentCardView.swift
//  DocDoc
//

import SwiftUI

struct DocumentCardView: View {
    let document: Document
    var thumbnail: UIImage?
    var onTap: () -> Void
    var onShare: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                thumbnailView
                    .frame(width: 48, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(document.homeMetaLabel)
                        .font(.caption)
                        .foregroundStyle(DocDocTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 36)
            }
            .padding(12)
            .docDocCard()
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            Button {
                onShare?()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.body)
                    .foregroundStyle(DocDocTheme.textSecondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
        } else {
            DocPreviewPlaceholder()
        }
    }
}

#Preview {
    DocumentCardView(document: .mockDocument, onTap: {})
        .padding()
        .background(DocDocTheme.background)
}
