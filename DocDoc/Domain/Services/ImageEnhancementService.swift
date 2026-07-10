//
//  ImageEnhancementService.swift
//  DocDoc
//

import CoreImage
import UIKit

struct ImageAdjustments: Equatable {
    var brightness: Double = 0.7
    var contrast: Double = 0.55
    var whiten: Double = 0.8

    static let `default` = ImageAdjustments()
}

enum ImageEnhancementService {
    private static let context = CIContext()

    static func apply(_ adjustments: ImageAdjustments, to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image.normalizedOrientation()) else {
            return image
        }

        var output = ciImage

        let brightness = Float((adjustments.brightness - 0.5) * 0.6)
        let contrast = Float(0.5 + adjustments.contrast * 1.2)
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(output, forKey: kCIInputImageKey)
            filter.setValue(brightness, forKey: kCIInputBrightnessKey)
            filter.setValue(contrast, forKey: kCIInputContrastKey)
            output = filter.outputImage ?? output
        }

        let whitenAmount = Float(adjustments.whiten * 0.35)
        if whitenAmount > 0.01, let filter = CIFilter(name: "CIHighlightShadowAdjust") {
            filter.setValue(output, forKey: kCIInputImageKey)
            filter.setValue(whitenAmount, forKey: "inputHighlightAmount")
            output = filter.outputImage ?? output
        }

        guard let cgImage = context.createCGImage(output, from: output.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
}

extension UIImage {
    func rotated(degrees: Int) -> UIImage {
        let normalized = ((degrees % 360) + 360) % 360
        guard normalized != 0 else { return self }

        let radians = CGFloat(normalized) * .pi / 180
        var newSize = size
        if normalized == 90 || normalized == 270 {
            newSize = CGSize(width: size.height, height: size.width)
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: newSize, format: format).image { ctx in
            let context = ctx.cgContext
            context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            context.rotate(by: radians)
            draw(in: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ))
        }
    }
}
