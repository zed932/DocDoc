//
//  ScanFlowView.swift
//  DocDoc
//

import SwiftUI

struct ScanFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DocumentStore.self) private var documentStore

    let sourceImage: UIImage
    var onAddPage: () -> Void

    @State private var step: ScanFlowStep = .processing
    @State private var document: ScannedDocument?
    @State private var pdfData: Data?
    @State private var errorMessage: String?
    @State private var showShareSheet = false

    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .processing:
                    if let errorMessage {
                        errorView(message: errorMessage)
                    } else {
                        ProcessingView(
                            sourceImage: sourceImage,
                            onComplete: { scanned in
                                document = scanned
                                step = .editor
                            },
                            onError: { message in
                                errorMessage = message
                            }
                        )
                    }

                case .editor:
                    if document != nil {
                        EditorView(
                            document: documentBinding,
                            onAddPage: onAddPage,
                            onNext: { step = .export },
                            onClose: { dismiss() }
                        )
                    }

                case .export:
                    if let document {
                        ExportView(
                            document: document,
                            onBack: { step = .editor },
                            onShare: { data in
                                pdfData = data
                                showShareSheet = true
                            },
                            onSave: { data in
                                saveToDocuments(data)
                                dismiss()
                            }
                        )
                    }
                }
            }
        }
        .overlay {
            if showShareSheet, let pdfData, let document {
                ShareSheetView(
                    fileName: document.exportFileName,
                    fileSize: ByteCountFormatter.string(fromByteCount: Int64(pdfData.count), countStyle: .file),
                    pdfData: pdfData,
                    onDone: {
                        showShareSheet = false
                        dismiss()
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showShareSheet)
        .alert("Не удалось сохранить", isPresented: saveErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )
    }

    private var documentBinding: Binding<ScannedDocument> {
        Binding(
            get: { document ?? ScannedDocument(pages: []) },
            set: { document = $0 }
        )
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("Не удалось обработать документ")
                .font(.title3.bold())
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(DocDocTheme.textSecondary)
                .padding(.horizontal, 24)
            Button("Закрыть") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DocDocTheme.background)
    }

    private func saveToDocuments(_ data: Data) {
        guard let document else { return }
        do {
            try documentStore.add(document, pdfData: data)
        } catch {
            saveError = error.localizedDescription
        }
    }
}

private enum ScanFlowStep {
    case processing
    case editor
    case export
}

#Preview {
    ScanFlowView(sourceImage: UIImage(systemName: "doc.text")!, onAddPage: {})
        .environment(DocumentStore())
}
