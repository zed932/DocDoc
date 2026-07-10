//
//  OnboardingView.swift
//  DocDoc
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var slide = 0

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            title: "Сканируйте документы",
            description: "Сфотографируйте или выберите из галереи — DocDoc сделает остальное",
            visual: .camera
        ),
        OnboardingSlide(
            title: "Умная реставрация",
            description: "Убираем тени, выравниваем перспективу и отбеливаем фон автоматически",
            visual: .restoration
        ),
        OnboardingSlide(
            title: "PDF и Share",
            description: "Конвертируйте в PDF и сразу отправьте по почте, в мессенджер или облако",
            visual: .share
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $slide) {
                ForEach(slides.indices, id: \.self) { index in
                    slideContent(for: slides[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)

            pageIndicator
                .padding(.bottom, 16)

            actionBar
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .background(DocDocTheme.surface)
    }

    private func slideContent(for slide: OnboardingSlide) -> some View {
        VStack(spacing: 24) {
            Spacer()

            visual(for: slide.visual)
                .frame(minHeight: 280)

            VStack(spacing: 8) {
                Text(slide.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(slide.description)
                    .font(.subheadline)
                    .foregroundStyle(DocDocTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    @ViewBuilder
    private func visual(for type: OnboardingVisual) -> some View {
        switch type {
        case .camera:
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.16, green: 0.18, blue: 0.20))
                .frame(width: 200, height: 260)
                .overlay {
                    ZStack {
                        DocPreviewPlaceholder(style: .raw)
                            .padding(20)
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(DocDocTheme.accent.opacity(0.8), lineWidth: 2)
                            .padding(20)
                    }
                }

        case .restoration:
            HStack(spacing: 12) {
                compareColumn(title: "До", style: .raw)
                Text("→")
                    .font(.title2)
                    .foregroundStyle(DocDocTheme.textSecondary)
                compareColumn(title: "После", style: .clean)
            }

        case .share:
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(DocDocTheme.accent)
                    Text("Договор_2026.pdf")
                        .font(.subheadline.weight(.semibold))
                    Text("248 KB")
                        .font(.caption)
                        .foregroundStyle(DocDocTheme.textSecondary)
                }
                .padding(24)
                .frame(maxWidth: 260)
                .background(DocDocTheme.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 16) {
                    ForEach(["envelope.fill", "message.fill", "icloud.fill", "square.and.arrow.up"], id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundStyle(DocDocTheme.accent)
                            .frame(width: 44, height: 44)
                            .background(DocDocTheme.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private func compareColumn(title: String, style: DocPreviewStyle) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DocDocTheme.textSecondary)
            DocPreviewPlaceholder(style: style)
                .frame(width: 110, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(slides.indices, id: \.self) { index in
                Capsule()
                    .fill(index == slide ? DocDocTheme.accent : DocDocTheme.stroke)
                    .frame(width: index == slide ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: slide)
            }
        }
    }

    private var actionBar: some View {
        HStack {
            if slide < slides.count - 1 {
                Button("Пропустить", action: onComplete)
                    .foregroundStyle(DocDocTheme.accent)
                    .font(.body.weight(.medium))

                Spacer()

                Button("Далее") {
                    withAnimation { slide += 1 }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Начать", action: onComplete)
                    .buttonStyle(PrimaryButtonStyle(fullWidth: true))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct OnboardingSlide {
    let title: String
    let description: String
    let visual: OnboardingVisual
}

private enum OnboardingVisual {
    case camera
    case restoration
    case share
}

#Preview {
    OnboardingView(onComplete: {})
}
