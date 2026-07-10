//
//  ShareSheetView.swift
//  DocDoc
//

import SwiftUI
import UIKit

struct ShareSheetView: View {
    let fileName: String
    let fileSize: String
    let pdfData: Data
    var onDone: () -> Void

    @State private var showSystemShare = false

    private let options: [ShareOption] = [
        ShareOption(icon: "envelope.fill", label: "Почта", color: Color(red: 0.29, green: 0.56, blue: 0.85)),
        ShareOption(icon: "message.fill", label: "Сообщения", color: Color(red: 0.20, green: 0.78, blue: 0.35)),
        ShareOption(icon: "icloud.fill", label: "iCloud", color: Color(red: 0.35, green: 0.78, blue: 0.98)),
        ShareOption(icon: "doc.on.doc", label: "Копировать", color: Color(red: 0.55, green: 0.55, blue: 0.58)),
        ShareOption(icon: "square.and.arrow.up", label: "Ещё...", color: Color(red: 0.39, green: 0.39, blue: 0.40)),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDone)

            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)

                HStack(spacing: 14) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(DocDocTheme.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(fileName)
                            .font(.subheadline.weight(.semibold))
                        Text(fileSize)
                            .font(.caption)
                            .foregroundStyle(DocDocTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(options) { option in
                        Button {
                            handleShare(option)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: option.icon)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .frame(width: 52, height: 52)
                                    .background(option.color, in: RoundedRectangle(cornerRadius: 14))

                                Text(option.label)
                                    .font(.caption2)
                                    .foregroundStyle(DocDocTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Button("Готово", action: onDone)
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
            .padding(.bottom, 8)
            .background(DocDocTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .sheet(isPresented: $showSystemShare) {
            ActivityView(items: [temporaryFileURL()])
        }
    }

    private func handleShare(_ option: ShareOption) {
        switch option.label {
        case "Копировать":
            UIPasteboard.general.setData(pdfData, forPasteboardType: "com.adobe.pdf")
        default:
            showSystemShare = true
        }
    }

    private func temporaryFileURL() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pdfData.write(to: url)
        return url
    }
}

private struct ShareOption: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let color: Color
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
