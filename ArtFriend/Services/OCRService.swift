import Foundation
import Vision
import UIKit

struct RecognizedTextBlock {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}

actor OCRService {
    static let shared = OCRService()

    private init() {}

    func recognizeText(from image: UIImage) async throws -> [RecognizedTextBlock] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let textBlocks = observations.compactMap { observation -> RecognizedTextBlock? in
                    guard let topCandidate = observation.topCandidates(1).first else {
                        return nil
                    }
                    return RecognizedTextBlock(
                        text: topCandidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: topCandidate.confidence
                    )
                }

                continuation.resume(returning: textBlocks)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func extractFullText(from image: UIImage) async throws -> String {
        let blocks = try await recognizeText(from: image)
        let sortedBlocks = blocks.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
        return sortedBlocks.map { $0.text }.joined(separator: "\n")
    }
}

enum OCRError: Error, LocalizedError {
    case invalidImage
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image could not be processed"
        case .recognitionFailed:
            return "Text recognition failed"
        }
    }
}
