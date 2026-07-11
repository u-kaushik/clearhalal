import UIKit
import Vision

enum LabelTextRecognitionError: LocalizedError {
    case imageNotReadable
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .imageNotReadable:
            return "We could not read that image. Try a clearer photo of the ingredient list."
        case .noTextFound:
            return "No label text was found. Try cropping closer to the ingredients."
        }
    }
}

struct LabelTextRecognizer {
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw LabelTextRecognitionError.imageNotReadable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let text = lines
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !text.isEmpty else {
                    continuation.resume(throwing: LabelTextRecognitionError.noTextFound)
                    return
                }

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
