//
//  ExportView.swift
//  DocDoc
//

import SwiftUI

struct ExportView: View {
    let document: ScannedDocument
    var onBack: () -> Void
    var onShare: (Data) -> Void
    var onSave: (Data) -> Void

    @State private var options = PDFExportOptions()
    @State private var isExporting = false
    @State private var exportComplete = false
    @State private var pdfData: Data?
    @State private var errorMessage: String?

    private var estimatedSize: String {
        let bytes = PDFExportService.estimatedSize(for: document, options: options)
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    var body: some View {
        ZStack {
            DocDocTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 24) {
                        previewBlock
                        optionsBlock

                        if exportComplete, pdfData != nil {
                            completedActions
                        } else {
                            exportButton
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 40, height: 40)
            }
            Spacer()
            Text("Экспорт PDF")
                .font(.headline)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private var previewBlock: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.system(size: 48))
                .foregroundStyle(DocDocTheme.accent)

            Text(document.title)
                .font(.title3.bold())

            Text("\(document.pagesCount) стр. · A4 · ~\(estimatedSize)")
                .font(.subheadline)
                .foregroundStyle(DocDocTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var optionsBlock: some View {
        VStack(spacing: 0) {
            optionRow(title: "Качество") {
                Picker("", selection: $options.quality) {
                    ForEach(PDFExportQuality.allCases) { quality in
                        Text(quality.rawValue).tag(quality)
                    }
                }
                .labelsHidden()
            }
            Divider().padding(.leading, 16)
            optionRow(title: "Ориентация") {
                Picker("", selection: $options.orientation) {
                    ForEach(PDFOrientation.allCases) { orientation in
                        Text(orientation.rawValue).tag(orientation)
                    }
                }
                .labelsHidden()
            }
            Divider().padding(.leading, 16)
            HStack {
                Text("Сжатие PDF")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: $options.compress)
                    .labelsHidden()
                    .tint(DocDocTheme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .docDocCard()
        .disabled(exportComplete)
    }

    private func optionRow<Content: View>(title: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var exportButton: some View {
        Button {
            Task { await exportPDF() }
        } label: {
            HStack(spacing: 8) {
                if isExporting {
                    ProgressView()
                        .tint(.white)
                    Text("Создание PDF...")
                } else {
                    Image(systemName: "doc.fill")
                    Text("Создать PDF")
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle(fullWidth: true))
        .disabled(isExporting)
    }

    private var completedActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("PDF готов!")
                    .font(.headline)
            }
            .padding(.bottom, 4)

            Button {
                if let pdfData { onShare(pdfData) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Поделиться")
                }
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: true))

            Button {
                if let pdfData { onSave(pdfData) }
            } label: {
                Text("Сохранить в документы")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    @MainActor
    private func exportPDF() async {
        isExporting = true
        errorMessage = nil

        let doc = document
        let opts = options

        let result: Result<Data, Error> = await Task.detached {
            do {
                return .success(try PDFExportService.createPDF(from: doc, options: opts))
            } catch {
                return .failure(error)
            }
        }.value

        isExporting = false

        switch result {
        case .success(let data):
            pdfData = data
            exportComplete = true
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
