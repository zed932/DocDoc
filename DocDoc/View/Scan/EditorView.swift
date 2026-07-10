//
//  EditorView.swift
//  DocDoc
//

import SwiftUI

struct EditorView: View {
    @Binding var document: ScannedDocument
    var onAddPage: () -> Void
    var onNext: () -> Void
    var onClose: () -> Void

    @State private var activeTab: EditorTab = .enhance
    @State private var adjustments = ImageAdjustments.default
    @State private var selectedPageIndex = 0
    @State private var enhancedImage: UIImage?

    private var currentPage: ScannedPage {
        document.pages[selectedPageIndex]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                canvas
                    .frame(maxHeight: .infinity)

                pageStrip

                toolbar
            }
        }
        .onAppear { applyAdjustments() }
        .onChange(of: adjustments) { _, _ in applyAdjustments() }
        .onChange(of: selectedPageIndex) { _, _ in
            adjustments = .default
            applyAdjustments()
        }
    }

    private var header: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }

            Spacer()

            Text("Редактор")
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Button("Далее", action: onNext)
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var canvas: some View {
        ZStack(alignment: .bottomTrailing) {
            if let enhancedImage {
                Image(uiImage: enhancedImage)
                    .resizable()
                    .aspectRatio(enhancedImage.pixelAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
            }

            Text("\(selectedPageIndex + 1) / \(document.pages.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.5), in: Capsule())
                .padding(20)
        }
    }

    private var pageStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(document.pages.indices, id: \.self) { index in
                    Button {
                        selectedPageIndex = index
                    } label: {
                        Image(uiImage: document.pages[index].displayImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedPageIndex == index ? DocDocTheme.accent : .clear, lineWidth: 2)
                            )
                    }
                }

                Button(action: onAddPage) {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DocDocTheme.stroke, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(width: 52, height: 68)
                        .overlay {
                            Image(systemName: "plus")
                                .foregroundStyle(DocDocTheme.textSecondary)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(white: 0.12))
    }

    private var toolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(EditorTab.allCases, id: \.self) { tab in
                    Button {
                        activeTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.body)
                            Text(tab.title)
                                .font(.caption2)
                        }
                        .foregroundStyle(activeTab == tab ? DocDocTheme.accent : DocDocTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
            .background(Color(white: 0.15))

            Group {
                switch activeTab {
                case .enhance:
                    enhancePanel
                case .crop:
                    cropPanel
                case .rotate:
                    rotatePanel
                }
            }
            .padding(16)
            .background(Color(white: 0.1))
        }
    }

    private var enhancePanel: some View {
        VStack(spacing: 14) {
            AdjustmentSlider(icon: "sun.max", title: "Яркость", value: $adjustments.brightness)
            AdjustmentSlider(icon: "circle.lefthalf.filled", title: "Контраст", value: $adjustments.contrast)
            AdjustmentSlider(icon: "square.fill", title: "Отбеливание", value: $adjustments.whiten)

            Button {
                adjustments = .default
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("Авто-улучшение")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(DocDocTheme.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var cropPanel: some View {
        VStack(spacing: 12) {
            Text("Перетащите углы для обрезки документа")
                .font(.subheadline)
                .foregroundStyle(DocDocTheme.textSecondary)
                .multilineTextAlignment(.center)

            RoundedRectangle(cornerRadius: 12)
                .stroke(DocDocTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [6]))
                .frame(height: 120)
                .overlay {
                    Text("Скоро")
                        .font(.caption)
                        .foregroundStyle(DocDocTheme.textSecondary)
                }
        }
    }

    private var rotatePanel: some View {
        HStack(spacing: 12) {
            RotateButton(title: "↺ −90°") { rotate(by: -90) }
            RotateButton(title: "↻ +90°") { rotate(by: 90) }
            RotateButton(title: "⟳ 180°") { rotate(by: 180) }
        }
    }

    private func applyAdjustments() {
        let base = currentPage.processedImage.rotated(degrees: currentPage.rotation)
        enhancedImage = ImageEnhancementService.apply(adjustments, to: base)
    }

    private func rotate(by degrees: Int) {
        document.pages[selectedPageIndex].rotation += degrees
        applyAdjustments()
    }
}

private enum EditorTab: CaseIterable {
    case enhance, crop, rotate

    var title: String {
        switch self {
        case .enhance: return "Улучшение"
        case .crop: return "Обрезка"
        case .rotate: return "Поворот"
        }
    }

    var icon: String {
        switch self {
        case .enhance: return "wand.and.stars"
        case .crop: return "crop"
        case .rotate: return "rotate.right"
        }
    }
}

private struct AdjustmentSlider: View {
    let icon: String
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(DocDocTheme.textSecondary)
            Text(title)
                .font(.subheadline)
                .frame(width: 90, alignment: .leading)
            Slider(value: $value, in: 0...1)
                .tint(DocDocTheme.accent)
        }
        .foregroundStyle(.white)
    }
}

private struct RotateButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(DocDocTheme.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
