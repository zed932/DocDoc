//
//  DocPreviewPlaceholder.swift
//  DocDoc
//

import SwiftUI

enum DocPreviewStyle {
    case raw
    case clean
}

struct DocPreviewPlaceholder: View {
    var style: DocPreviewStyle = .clean

    var body: some View {
        ZStack {
            DocDocTheme.surfaceSecondary

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(DocDocTheme.accent.opacity(0.7))
                    .frame(width: 42, height: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 6)

                ForEach([0.9, 0.75, 0.85, 0.6, 0.8, 0.7], id: \.self) { width in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: style == .clean ? 0.82 : 0.78))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: width, anchor: .leading)
                        .padding(.bottom, 3)
                }

                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 18, height: 2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
            }
            .padding(6)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
            .padding(4)
            .rotationEffect(style == .raw ? .degrees(-2) : .zero)
            .opacity(style == .raw ? 0.92 : 1)
        }
    }
}

#Preview {
    HStack {
        DocPreviewPlaceholder(style: .raw)
        DocPreviewPlaceholder(style: .clean)
    }
    .frame(height: 80)
    .padding()
}
