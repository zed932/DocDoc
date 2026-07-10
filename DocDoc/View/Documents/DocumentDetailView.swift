//
//  DocumentDetailView.swift
//  DocDoc
//

import SwiftUI

struct DocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DocumentStore.self) private var documentStore

    let document: Document

    @State private var showShareSheet = false

    private var pdfURL: URL? {
        documentStore.pdfURL(for: document)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let pdfURL {
                    PDFKitView(url: pdfURL)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    missingFileView
                }
            }
            .background(DocDocTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(document.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(document.metaLabel)
                            .font(.caption)
                            .foregroundStyle(DocDocTheme.textSecondary)
                            .lineLimit(1)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(pdfURL == nil)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let pdfURL {
                    ActivityView(items: [pdfURL])
                }
            }
        }
    }

    private var missingFileView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(DocDocTheme.textSecondary)
            Text("Файл не найден")
                .font(.title3.bold())
            Text("PDF для этого документа отсутствует на устройстве.")
                .font(.subheadline)
                .foregroundStyle(DocDocTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DocumentDetailView(document: .mockDocument)
        .environment(DocumentStore())
}
