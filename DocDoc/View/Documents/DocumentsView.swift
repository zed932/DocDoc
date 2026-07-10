//
//  DocumentsView.swift
//  DocDoc
//

import SwiftUI

struct DocumentsView: View {
    let documents: [Document]
    var onScan: () -> Void

    @State private var search = ""

    private var filteredDocuments: [Document] {
        guard !search.trimmingCharacters(in: .whitespaces).isEmpty else {
            return documents
        }
        return documents.filter {
            $0.title.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Документы")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                        Button(action: onScan) {
                            Image(systemName: "plus")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(DocDocTheme.accent)
                                .frame(width: 40, height: 40)
                                .background(DocDocTheme.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)

                    searchField
                        .padding(.horizontal, 20)

                    LazyVStack(spacing: 8) {
                        ForEach(filteredDocuments) { document in
                            LibraryDocumentRow(document: document)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .background(DocDocTheme.background)
            .navigationBarHidden(true)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DocDocTheme.textSecondary)
            TextField("Поиск документов...", text: $search)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DocDocTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DocDocTheme.stroke, lineWidth: 1)
        )
    }
}

#Preview {
    DocumentsView(documents: Document.mockDocuments, onScan: {})
}
