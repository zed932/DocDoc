//
//  UIImage+Normalized.swift
//  DocDoc
//

import UIKit

extension UIImage {
    var pixelSize: CGSize {
        guard let cgImage else {
            return CGSize(width: size.width * scale, height: size.height * scale)
        }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }

    var pixelAspectRatio: CGFloat {
        let size = pixelSize
        guard size.height > 0 else { return 1 }
        return size.width / size.height
    }

    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Центральный кроп под целевое соотношение сторон и масштабирование без искажений.
    func preparedForModelInput(targetWidth: Int, targetHeight: Int) -> UIImage {
        let targetSize = CGSize(width: targetWidth, height: targetHeight)
        let normalized = normalizedOrientation()
        guard let cgImage = normalized.cgImage else { return normalized }

        let targetAspect = targetSize.width / targetSize.height
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let imageAspect = imageWidth / imageHeight

        let cropRect: CGRect
        if imageAspect > targetAspect {
            let cropWidth = imageHeight * targetAspect
            cropRect = CGRect(
                x: (imageWidth - cropWidth) / 2,
                y: 0,
                width: cropWidth,
                height: imageHeight
            )
        } else {
            let cropHeight = imageWidth / targetAspect
            cropRect = CGRect(
                x: 0,
                y: (imageHeight - cropHeight) / 2,
                width: imageWidth,
                height: cropHeight
            )
        }

        guard let cropped = cgImage.cropping(to: cropRect.integral) else {
            return normalized
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            UIImage(cgImage: cropped, scale: 1, orientation: .up)
                .draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func downsampled(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(pixelSize.width, pixelSize.height)
        guard longestSide > maxDimension else { return normalizedOrientation() }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(
            width: pixelSize.width * scale,
            height: pixelSize.height * scale
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
