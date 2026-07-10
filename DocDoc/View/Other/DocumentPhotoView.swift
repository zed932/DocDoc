//
//  DocumentPhotoView.swift
//  DocDoc
//

import SwiftUI

struct DocumentPhotoView: View {
    let image: UIImage
    var maxHeight: CGFloat = 360

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(image.pixelAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: maxHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DocDocTheme.stroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            .padding(.horizontal)
    }
}
