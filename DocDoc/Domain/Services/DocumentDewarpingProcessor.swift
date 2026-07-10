//
//  DocumentDewarpingProcessor.swift
//  DocDoc
//

import CoreML
import os
import UIKit

enum DocumentDewarpingError: LocalizedError {
    case modelNotFound
    case imagePreparationFailed
    case predictionFailed(String)
    case invalidOutput
    case insufficientMemory(availableMB: Int)

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Модель dewarping не найдена в бандле приложения."
        case .imagePreparationFailed:
            return "Не удалось подготовить изображение для модели."
        case .predictionFailed(let details):
            return "Ошибка инференса: \(details)"
        case .invalidOutput:
            return "Модель вернула некорректный результат."
        case .insufficientMemory(let availableMB):
            return "Недостаточно свободной памяти (\(availableMB) МБ). Закройте другие приложения и попробуйте снова. Для стабильной работы нужна модель меньшего разрешения."
        }
    }
}

struct DocumentDewarpingResult {
    let originalPreview: UIImage
    let restoredPreview: UIImage
    let inferenceDuration: TimeInterval
}

/// Тестовый обработчик dewarping-модели (вход `x`, выход `img`).
final class DocumentDewarpingProcessor {
    static let inputHeight = 4032
    static let inputWidth = 3024
    private static let previewMaxDimension: CGFloat = 1200
    private static let minimumAvailableMemoryBytes: UInt64 = 500 * 1024 * 1024

    private let model: MLModel

    init() throws {
        try Self.validateAvailableMemory()

        guard let url = Bundle.main.url(
            forResource: "dewarping_4032_3024",
            withExtension: "mlmodelc"
        ) ?? Bundle.main.url(
            forResource: "dewarping_4032_3024",
            withExtension: "mlpackage"
        ) else {
            throw DocumentDewarpingError.modelNotFound
        }

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuOnly
        model = try MLModel(contentsOf: url, configuration: configuration)
    }

    func process(_ image: UIImage) throws -> DocumentDewarpingResult {
        try Self.validateAvailableMemory()

        let modelInput = image.preparedForModelInput(
            targetWidth: Self.inputWidth,
            targetHeight: Self.inputHeight
        )

        let start = CFAbsoluteTimeGetCurrent()
        let restored: UIImage = try autoreleasepool {
            let input = try makeInputArray(from: modelInput)
            let outputArray: MLMultiArray
            do {
                let provider = try MLDictionaryFeatureProvider(dictionary: ["x": input])
                let options = MLPredictionOptions()
                options.usesCPUOnly = true
                let output = try model.prediction(from: provider, options: options)
                guard let array = output.featureValue(for: "img")?.multiArrayValue else {
                    throw DocumentDewarpingError.invalidOutput
                }
                outputArray = array
            } catch {
                throw DocumentDewarpingError.predictionFailed(error.localizedDescription)
            }

            guard let restored = makeImage(from: outputArray) else {
                throw DocumentDewarpingError.invalidOutput
            }
            return restored
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        return DocumentDewarpingResult(
            originalPreview: modelInput.downsampled(maxDimension: Self.previewMaxDimension),
            restoredPreview: restored.downsampled(maxDimension: Self.previewMaxDimension),
            inferenceDuration: duration
        )
    }

    private static func validateAvailableMemory() throws {
        let available = os_proc_available_memory()
        guard available >= minimumAvailableMemoryBytes else {
            throw DocumentDewarpingError.insufficientMemory(availableMB: Int(available / 1024 / 1024))
        }
    }

    private func makeInputArray(from image: UIImage) throws -> MLMultiArray {
        guard let pixels = rgbPixels(from: image.normalizedOrientation()) else {
            throw DocumentDewarpingError.imagePreparationFailed
        }

        let height = Self.inputHeight
        let width = Self.inputWidth
        let shape: [NSNumber] = [1, 3, height, width] as [NSNumber]
        guard let array = try? MLMultiArray(shape: shape, dataType: .float32) else {
            throw DocumentDewarpingError.imagePreparationFailed
        }

        let pixelCount = height * width
        let channelStride = pixelCount
        let floats = array.dataPointer.bindMemory(to: Float.self, capacity: array.count)
        let scale: Float = 1.0 / 255.0

        pixels.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }

            for index in 0..<pixelCount {
                let offset = index * 4
                floats[index] = Float(base[offset]) * scale
                floats[channelStride + index] = Float(base[offset + 1]) * scale
                floats[(channelStride * 2) + index] = Float(base[offset + 2]) * scale
            }
        }

        return array
    }

    private func makeImage(from array: MLMultiArray) -> UIImage? {
        guard array.shape.count == 4 else { return nil }

        let height = array.shape[2].intValue
        let width = array.shape[3].intValue
        let pixelCount = height * width
        let channelStride = pixelCount
        var pixels = [UInt8](repeating: 255, count: pixelCount * 4)
        let floats = array.dataPointer.bindMemory(to: Float.self, capacity: array.count)

        for index in 0..<pixelCount {
            let offset = index * 4
            pixels[offset] = clampedByte(from: floats[index])
            pixels[offset + 1] = clampedByte(from: floats[channelStride + index])
            pixels[offset + 2] = clampedByte(from: floats[(channelStride * 2) + index])
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        return pixels.withUnsafeMutableBytes { rawBuffer in
            guard let context = CGContext(
                data: rawBuffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ), let cgImage = context.makeImage() else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }
    }

    private func rgbPixels(from image: UIImage) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }

    private func clampedByte(from value: Float) -> UInt8 {
        let scaled = max(0, min(1, value)) * 255
        return UInt8(scaled.rounded())
    }
}
