import Foundation
import CoreMedia
import Vision
import CoreImage
import UIKit

protocol LiveFaceTrackingDelegate: AnyObject {
    func faceTracker(_ tracker: LiveFaceTracker, didDetectFace frameData: FaceFrameData, sampleBuffer: CMSampleBuffer)
    func faceTracker(_ tracker: LiveFaceTracker, didLoseFaceWith condition: LightingCondition)
}

final class LiveFaceTracker {
    
    weak var delegate: LiveFaceTrackingDelegate?
    
    func process(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let brightness = getBrightness(from: sampleBuffer)
        let condition: LightingCondition
        if brightness < -1.0 {
            condition = .tooDark
        } else if brightness > 5.0 {
            condition = .tooBright
        } else {
            condition = .good
        }
        
        do {
            try handler.perform([request])
        } catch {
            delegate?.faceTracker(self, didLoseFaceWith: condition)
            return
        }
        
        guard let faceObservation = request.results?.first else {
            delegate?.faceTracker(self, didLoseFaceWith: condition)
            return
        }
        
        let boundingBox = faceObservation.boundingBox
        let yaw = faceObservation.yaw?.doubleValue
        let pitch = faceObservation.pitch?.doubleValue
        let frameData = FaceFrameData(boundingBox: boundingBox, yaw: yaw, pitch: pitch)
        
        delegate?.faceTracker(self, didDetectFace: frameData, sampleBuffer: sampleBuffer)
    }
    
    private func getBrightness(from sampleBuffer: CMSampleBuffer) -> Double {
        guard let metadata = CMCopyDictionaryOfAttachments(
            allocator: kCFAllocatorDefault,
            target: sampleBuffer,
            attachmentMode: kCMAttachmentMode_ShouldPropagate
        ) as? [String: Any],
              let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let brightnessValue = exif[kCGImagePropertyExifBrightnessValue as String] as? Double else {
            return 0.0
        }
        return brightnessValue
    }
    
    func extractJPEGData(from sampleBuffer: CMSampleBuffer, jpegCompressionQuality: CGFloat = 0.82) -> Data? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        return uiImage.jpegData(compressionQuality: jpegCompressionQuality)
    }
    
    func cropImage(from jpegData: Data, normalizedRect rect: CGRect, jpegCompressionQuality: CGFloat = 0.82) -> Data? {
        guard !jpegData.isEmpty,
              let rawImage = UIImage(data: jpegData) else { return nil }

        let normalised: UIImage
        if rawImage.imageOrientation == .up {
            normalised = rawImage
        } else {
            let renderer = UIGraphicsImageRenderer(size: rawImage.size)
            normalised = renderer.image { _ in
                rawImage.draw(in: CGRect(origin: .zero, size: rawImage.size))
            }
        }

        guard let cgImage = normalised.cgImage else { return nil }

        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)

        let cropRect = CGRect(
            x: rect.origin.x * imgW,
            y: rect.origin.y * imgH,
            width: rect.width  * imgW,
            height: rect.height * imgH
        ).integral

        guard let cropped = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cropped).jpegData(compressionQuality: jpegCompressionQuality)
    }
}
