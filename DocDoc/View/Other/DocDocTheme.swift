//
//  DocDocTheme.swift
//  DocDoc
//

import SwiftUI

enum AppTab: Hashable {
    case home
    case documents
    case settings
}

enum DocDocTheme {
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let surfaceSecondary = Color("SurfaceSecondary")
    static let stroke = Color("Stroke")
    static let accent = Color("AccentBrand")
    static let accentSoft = Color("AccentSoft")
    static let textSecondary = Color("TextSecondary")

    static let radius: CGFloat = 16
    static let radiusSmall: CGFloat = 10
}

struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(DocDocTheme.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(DocDocTheme.surfaceSecondary.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DocDocCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DocDocTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: DocDocTheme.radiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: DocDocTheme.radiusSmall)
                    .stroke(DocDocTheme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func docDocCard() -> some View {
        modifier(DocDocCardModifier())
    }
}
