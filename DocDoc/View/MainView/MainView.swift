//
//  MainView.swift
//  DocDoc
//

import PhotosUI
import SwiftUI

struct MainView: View {
    @Binding var selectedTab: AppTab
    let documents: [Document]
    var onScan: () -> Void
    var onImagePicked: (UIImage) -> Void

    private var recentDocuments: [Document] {
        Array(documents.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    heroSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    recentSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .background(DocDocTheme.background)
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(DocDocTheme.textSecondary)
                Text("DocDoc")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {
                selectedTab = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(DocDocTheme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            Button(action: onScan) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 64, height: 64)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                    Text("Сканировать")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(DocDocTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: DocDocTheme.radius))
                .shadow(color: DocDocTheme.accent.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                GalleryQuickAction(onImagePicked: onImagePicked)
                QuickActionButton(icon: "folder.fill", title: "Документы") {
                    selectedTab = .documents
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Недавние")
                    .font(.headline)
                Spacer()
                Button("Все") {
                    selectedTab = .documents
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DocDocTheme.accent)
            }

            VStack(spacing: 8) {
                ForEach(recentDocuments) { document in
                    DocumentCardView(document: document)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброе утро"
        case 12..<17: return "Добрый день"
        case 17..<23: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }
}

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(DocDocTheme.accent)
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .docDocCard()
        }
        .buttonStyle(.plain)
    }
}

private struct GalleryQuickAction: View {
    var onImagePicked: (UIImage) -> Void
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle")
                    .font(.body)
                    .foregroundStyle(DocDocTheme.accent)
                Text("Галерея")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .docDocCard()
        }
        .buttonStyle(.plain)
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        onImagePicked(image)
                        selectedItem = nil
                    }
                }
            }
        }
    }
}

#Preview {
    MainView(
        selectedTab: .constant(.home),
        documents: Document.mockDocuments,
        onScan: {},
        onImagePicked: { _ in }
    )
}
