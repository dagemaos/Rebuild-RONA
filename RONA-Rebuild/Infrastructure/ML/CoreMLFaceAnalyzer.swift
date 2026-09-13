import Foundation
import CoreGraphics
import Vision
import CoreML

final class CoreMLFaceAnalyzer: FaceAnalyzing {
    
    private let inferenceQueue = DispatchQueue(
        label: "rona.ml.acneDetection",
        qos: .userInitiated
    )
    
    private var visionModel: VNCoreMLModel?
    private var modelLoadError: Error?
    
    init () {
        setupModel()
    }
    
    private func setupModel() {
        do {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all
            
            // Note: Update model name if changed
            let model = try v26_fp16(configuration: configuration)
            visionModel = try VNCoreMLModel(for: model.model)
        } catch {
            modelLoadError = error
        }
    }
    
    func analyze(image: CGImage) async throws -> [AcneDetection] {
        guard let visionModel = visionModel else {
            let message = modelLoadError?.localizedDescription ?? "Model tidak dimuat."
            throw ScanError.unknown(message)
        }

        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async {
                do {
                    let request = VNCoreMLRequest(model: visionModel)
                    request.imageCropAndScaleOption = .scaleFill

                    let handler = VNImageRequestHandler(cgImage: image, options: [:])
                    try handler.perform([request])

                    let detections = Self.parseDetections(from: request.results ?? [])
                    continuation.resume(returning: detections)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Output Parsing

    private static func parseDetections(from results: [Any]) -> [AcneDetection] {
        if let objectObservations = results as? [VNRecognizedObjectObservation] {
            return objectObservations.compactMap { observation -> AcneDetection? in
                guard let topLabel = observation.labels.first else { return nil }
                let classId = classIdFromLabel(topLabel.identifier)
                guard classId >= 0, classId <= 5 else { return nil }

                return AcneDetection(
                    acneType: AcneType(classId: classId),
                    confidence: Double(topLabel.confidence),
                    normalizedBoundingBox: observation.boundingBox
                )
            }
        }

        if let featureObservations = results as? [VNCoreMLFeatureValueObservation] {
            return parseEnd2EndOutput(featureObservations)
        }

        return []
    }

    private static func parseEnd2EndOutput(
        _ observations: [VNCoreMLFeatureValueObservation]
    ) -> [AcneDetection] {
        let confidenceThreshold: Float = 0.05
        var detections: [AcneDetection] = []

        for observation in observations {
            guard let multiArray = observation.featureValue.multiArrayValue else { continue }

            let shape = multiArray.shape.map { $0.intValue }
            let numDetections: Int
            let numAttributes: Int

            if shape.count == 3 {
                numDetections = shape[1]
                numAttributes = shape[2]
            } else if shape.count == 2 {
                numDetections = shape[0]
                numAttributes = shape[1]
            } else {
                continue
            }

            guard numAttributes == 6 else { continue }

            let pointer = multiArray.dataPointer.assumingMemoryBound(to: Float.self)

            for d in 0..<numDetections {
                let baseIdx = d * numAttributes
                let x1 = pointer[baseIdx + 0]
                let y1 = pointer[baseIdx + 1]
                let x2 = pointer[baseIdx + 2]
                let y2 = pointer[baseIdx + 3]
                let conf = pointer[baseIdx + 4]
                let classId = Int(pointer[baseIdx + 5])

                guard conf >= confidenceThreshold else { continue }
                guard classId >= 0, classId <= 5 else { continue }

                let midpoint = CoordinateNormalizer.normalize(
                    x1: CGFloat(x1),
                    y1: CGFloat(y1),
                    x2: CGFloat(x2),
                    y2: CGFloat(y2)
                )

                let modelSize = CoordinateNormalizer.modelInputSize
                let normWidth = CGFloat(x2 - x1) / modelSize
                let normHeight = CGFloat(y2 - y1) / modelSize
                let normX = midpoint.x - normWidth / 2.0
                let normY = midpoint.y - normHeight / 2.0

                let normalizedBBox = CGRect(
                    x: CoordinateNormalizer.clamp(normX),
                    y: CoordinateNormalizer.clamp(normY),
                    width: CoordinateNormalizer.clamp(normWidth),
                    height: CoordinateNormalizer.clamp(normHeight)
                )

                detections.append(AcneDetection(
                    acneType: AcneType(classId: classId),
                    confidence: Double(conf),
                    normalizedBoundingBox: normalizedBBox
                ))
            }
        }

        return detections
    }

    private static func classIdFromLabel(_ label: String) -> Int {
        switch label.lowercased() {
        case "blackhead": return 0
        case "cyst": return 1
        case "nodule": return 2
        case "papule": return 3
        case "pustule": return 4
        case "whitehead": return 5
        default: return -1
        }
    }
}
