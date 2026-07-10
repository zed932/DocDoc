//
//  DocumentsView.swift
//  DocDoc
//

import SwiftUI

struct DocumentsView: View {
    @Environment(DocumentStore.self) private var documentStore

    var onScan: () -> Void

    @State private var search = ""
    @State private var openedDocument: Document?
    @State private var shareURL: URL?

    private var filteredDocuments: [Document] {
        guard !search.trimmingCharacters(in: .whitespaces).isEmpty else {
            return documentStore.documents
        }
        return documentStore.documents.filter {
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

                    if filteredDocuments.isEmpty {
                        emptyState
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredDocuments) { document in
                                LibraryDocumentRow(
                                    document: document,
                                    thumbnail: documentStore.thumbnail(for: document),
                                    onTap: { openedDocument = document },
                                    onShare: { share(document) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 8)
            }
            .background(DocDocTheme.background)
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $openedDocument) { document in
            DocumentDetailView(document: document)
        }
        .sheet(isPresented: shareSheetBinding) {
            if let shareURL {
                ActivityView(items: [shareURL])
            }
        }
    }

    private var shareSheetBinding: Binding<Bool> {
        Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 40))
                .foregroundStyle(DocDocTheme.textSecondary)
            Text("Нет документов")
                .font(.headline)
            Text("Отсканируйте документ и сохраните PDF, чтобы он появился здесь.")
                .font(.subheadline)
                .foregroundStyle(DocDocTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Сканировать", action: onScan)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private func share(_ document: Document) {
        shareURL = documentStore.pdfURL(for: document)
    }
}

#Preview {
    DocumentsView(onScan: {})
        .environment(DocumentStore(documents: Document.mockDocuments))
}
