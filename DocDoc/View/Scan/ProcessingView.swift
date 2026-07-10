//
//  ProcessingView.swift
//  DocDoc
//

import SwiftUI

struct ProcessingView: View {
    let sourceImage: UIImage
    let onComplete: (ScannedDocument) -> Void
    let onError: (String) -> Void

    @State private var completedStep = 0
    @State private var isProcessing = true
    @State private var previewImage: UIImage?

    private let steps = [
        "Обнаружение границ",
        "Выравнивание",
        "Удаление теней",
        "Отбеливание фона"
    ]

    var body: some View {
        ZStack {
            DocDocTheme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    if let previewImage {
                        DocumentPhotoView(image: previewImage, maxHeight: 280)
                            .opacity(completedStep < 2 ? 0.85 : completedStep < 4 ? 0.92 : 1)
                    }

                    if isProcessing {
                        ProgressView()
                            .controlSize(.large)
                            .tint(DocDocTheme.accent)
                            .padding(20)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }

                Text("Реставрация...")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(steps.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            stepIcon(for: index)
                            Text(steps[index])
                                .font(.subheadline)
                                .foregroundStyle(stepColor(for: index))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .task {
            previewImage = sourceImage.downsampled(maxDimension: 600)
            await runProcessing()
        }
    }

    @ViewBuilder
    private func stepIcon(for index: Int) -> some View {
        if index < completedStep {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)
        } else if index == completedStep && isProcessing {
            ProgressView()
                .controlSize(.small)
                .tint(DocDocTheme.accent)
        } else {
            Circle()
                .fill(DocDocTheme.stroke)
                .frame(width: 8, height: 8)
                .frame(width: 20, height: 20)
        }
    }

    private func stepColor(for index: Int) -> Color {
        if index < completedStep { return .primary }
        if index == completedStep && isProcessing { return DocDocTheme.accent }
        return DocDocTheme.textSecondary
    }

    @MainActor
    private func runProcessing() async {
        isProcessing = true
        completedStep = 0

        let stepTimer = Task {
            for step in 1...steps.count {
                try? await Task.sleep(for: .milliseconds(700))
                if Task.isCancelled { return }
                completedStep = step
            }
        }

        let image = sourceImage
        let output: Result<DocumentDewarpingResult, Error> = await Task.detached(priority: .utility) {
            autoreleasepool {
                do {
                    let processor = try DocumentDewarpingProcessor()
                    return .success(try processor.process(image))
                } catch {
                    return .failure(error)
                }
            }
        }.value

        stepTimer.cancel()
        isProcessing = false

        switch output {
        case .success(let result):
            completedStep = steps.count
            try? await Task.sleep(for: .milliseconds(500))

            let page = ScannedPage(
                originalImage: result.originalPreview,
                processedImage: result.restoredPreview
            )
            let document = ScannedDocument(
                title: "Документ \(formattedToday())",
                pages: [page],
                inferenceDuration: result.inferenceDuration
            )
            onComplete(document)

        case .failure(let error):
            onError(error.localizedDescription)
        }
    }

    private func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter.string(from: Date())
    }
}

#Preview {
    NavigationStack {
        ProcessingView(
            sourceImage: UIImage(systemName: "doc.text")!,
            onComplete: { _ in },
            onError: { _ in }
        )
    }
}
