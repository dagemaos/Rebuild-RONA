import Foundation
import UIKit
import AVFoundation

enum ScanEvent {
    case state(ScanState)
    case readiness(FaceScanReadiness)
    case holdProgress(Double)
    case angleCompleted(FaceZone)
}

protocol ScanServicing {
    var captureSession: AVCaptureSession { get }
    var events: AsyncStream<ScanEvent> { get }
    
    func startScan()
    func stopScan()
    func retry()
}

final class ScanService: ScanServicing, ScanCaptureStateMachineDelegate, ScanCameraServiceDelegate {
    
    private let analyzer: any FaceAnalyzing
    private let historyRepository: any ScanHistoryRepository
    private var cameraService: any ScanCameraServicing
    
    private let stateMachine = ScanCaptureStateMachine()
    private var continuation: AsyncStream<ScanEvent>.Continuation?
    
    var captureSession: AVCaptureSession {
        cameraService.captureSession
    }
    
    lazy var events: AsyncStream<ScanEvent> = {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }()
    
    private var capturedData: [FaceZone: Data] = [:]
    
    init(
        analyzer: any FaceAnalyzing,
        historyRepository: any ScanHistoryRepository,
        cameraService: any ScanCameraServicing = AVCaptureScanCameraService()
    ) {
        self.analyzer = analyzer
        self.historyRepository = historyRepository
        self.cameraService = cameraService
        self.stateMachine.delegate = self
        self.cameraService.delegate = self
    }
    
    func startScan() {
        Task {
            let granted = await cameraService.requestPermission()
            if granted {
                continuation?.yield(.state(.scanning))
                cameraService.start()
                stateMachine.reset()
            } else {
                continuation?.yield(.state(.idle)) // Equivalent to permissionDenied
            }
        }
    }
    
    func stopScan() {
        cameraService.stop()
    }
    
    func retry() {
        capturedData.removeAll()
        stateMachine.reset()
        continuation?.yield(.state(.scanning))
    }
    
    // MARK: - ScanCameraServiceDelegate
    func cameraService(_ service: ScanCameraServicing, didOutput sampleBuffer: CMSampleBuffer) {
        stateMachine.process(sampleBuffer: sampleBuffer)
    }
    
    // MARK: - ScanCaptureStateMachineDelegate
    func stateMachine(_ machine: ScanCaptureStateMachine, didUpdateReadiness readiness: FaceScanReadiness) {
        continuation?.yield(.readiness(readiness))
    }
    
    func stateMachine(_ machine: ScanCaptureStateMachine, didUpdateHoldProgress progress: Double) {
        continuation?.yield(.holdProgress(progress))
    }
    
    func stateMachine(_ machine: ScanCaptureStateMachine, didCompleteAngle angle: FaceZone, with image: Data) {
        capturedData[angle] = image
        continuation?.yield(.angleCompleted(angle))
    }
    
    func stateMachineDidCompleteAllAngles(_ machine: ScanCaptureStateMachine) {
        continuation?.yield(.state(.processing))
        cameraService.stop()
        
        Task {
            await processCapturedImages()
        }
    }
    
    func stateMachine(_ machine: ScanCaptureStateMachine, didFailWithError error: Error) {
        continuation?.yield(.state(.failed(ScanError.unknown(error.localizedDescription))))
    }
    
    // MARK: - ML Processing
    private func processCapturedImages() async {
        do {
            let result = try await buildScanResult()
            
            let record = ScanRecord(
                id: UUID(),
                date: Date(),
                photo: URL(fileURLWithPath: ""), // Mock for now
                result: result
            )
            try await historyRepository.save(record)
            
            continuation?.yield(.state(.showingResult(result)))
        } catch {
            continuation?.yield(.state(.failed(ScanError.unknown(error.localizedDescription))))
        }
    }
    
    private func buildScanResult() async throws -> ScanResult {
        let frontData = capturedData[.front] ?? Data()
        let leftData = capturedData[.leftAngle] ?? Data()
        let rightData = capturedData[.rightAngle] ?? Data()
        
        let frontDetections = try await analyze(data: frontData)
        let leftDetections = try await analyze(data: leftData)
        let rightDetections = try await analyze(data: rightData)
        
        let allDetections = frontDetections + leftDetections + rightDetections
        let totalAcneCount = allDetections.count
        
        // Zone summaries
        let zoneSummaries = [
            buildZoneSummary(zone: .front, detections: frontDetections, imageData: frontData),
            buildZoneSummary(zone: .leftAngle, detections: leftDetections, imageData: leftData),
            buildZoneSummary(zone: .rightAngle, detections: rightDetections, imageData: rightData)
        ]
        
        // Sub-zone summaries
        let subZoneSummaries = buildSubZoneSummaries(
            frontDetections: frontDetections, frontData: frontData,
            leftDetections: leftDetections, leftData: leftData,
            rightDetections: rightDetections, rightData: rightData
        )
        
        // Acne Type summaries
        var typeCounts: [AcneType: Int] = [:]
        for detection in allDetections {
            typeCounts[detection.acneType, default: 0] += 1
        }
        let acneTypeSummaries = typeCounts.map { type, count in
            AcneTypeSummaryModel(acneType: type, count: count)
        }.sorted { $0.count > $1.count }
        
        // Mock severity based on count for now
        let severity: AcneSeverity = totalAcneCount > 20 ? .severe : (totalAcneCount > 5 ? .moderate : .mild)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "id_ID")
        
        return ScanResult(
            id: UUID(),
            dateText: dateFormatter.string(from: Date()),
            overallSeverity: severity,
            totalAcneCount: totalAcneCount,
            zoneSummaries: zoneSummaries,
            subZoneSummaries: subZoneSummaries,
            acneTypeSummaries: acneTypeSummaries
        )
    }
    
    private func analyze(data: Data) async throws -> [AcneDetection] {
        guard let image = UIImage(data: data)?.cgImage else { return [] }
        return try await analyzer.analyze(image: image)
    }
    
    private func buildZoneSummary(zone: FaceZone, detections: [AcneDetection], imageData: Data) -> ZoneSummaryModel {
        let markers = detections.map { detection in
            MarkerModel(
                id: UUID(),
                acneType: detection.acneType,
                confidence: detection.confidence,
                normalizedBoundingBox: detection.normalizedBoundingBox
            )
        }
        
        return ZoneSummaryModel(
            id: UUID(),
            zone: zone,
            zoneName: zone.displayName,
            acneCount: detections.count,
            detailText: "\(detections.count) jerawat terdeteksi",
            imageData: imageData,
            markers: markers
        )
    }
    
    // MARK: - Sub-Zone Summary Builder
    private var foreheadCrop: CGRect { CGRect(x: 0.15, y: 0.10, width: 0.70, height: 0.25) }
    private var noseCrop: CGRect     { CGRect(x: 0.25, y: 0.35, width: 0.50, height: 0.30) }
    private var chinCrop: CGRect     { CGRect(x: 0.25, y: 0.65, width: 0.50, height: 0.25) }
    private var cheekCrop: CGRect    { CGRect(x: 0.15, y: 0.25, width: 0.70, height: 0.50) }
    
    private func buildSubZoneSummaries(
        frontDetections: [AcneDetection], frontData: Data,
        leftDetections: [AcneDetection], leftData: Data,
        rightDetections: [AcneDetection], rightData: Data
    ) -> [SubZoneSummaryModel] {
        let foreheadDetections = frontDetections.filter { $0.normalizedBoundingBox.midY < 0.35 }
        let noseDetections     = frontDetections.filter { $0.normalizedBoundingBox.midY >= 0.35 && $0.normalizedBoundingBox.midY < 0.65 }
        let chinDetections     = frontDetections.filter { $0.normalizedBoundingBox.midY >= 0.65 }
        
        return [
            SubZoneSummaryModel(
                id: UUID(),
                label: "Forehead",
                imageData: cropImage(from: frontData, normalizedRect: foreheadCrop),
                acneCount: foreheadDetections.count,
                markers: remapMarkers(foreheadDetections, cropRect: foreheadCrop)
            ),
            SubZoneSummaryModel(
                id: UUID(),
                label: "Nose",
                imageData: cropImage(from: frontData, normalizedRect: noseCrop),
                acneCount: noseDetections.count,
                markers: remapMarkers(noseDetections, cropRect: noseCrop)
            ),
            SubZoneSummaryModel(
                id: UUID(),
                label: "Chin",
                imageData: cropImage(from: frontData, normalizedRect: chinCrop),
                acneCount: chinDetections.count,
                markers: remapMarkers(chinDetections, cropRect: chinCrop)
            ),
            SubZoneSummaryModel(
                id: UUID(),
                label: "Right Cheek",
                imageData: cropImage(from: rightData, normalizedRect: cheekCrop),
                acneCount: rightDetections.count,
                markers: remapMarkers(rightDetections, cropRect: cheekCrop)
            ),
            SubZoneSummaryModel(
                id: UUID(),
                label: "Left Cheek",
                imageData: cropImage(from: leftData, normalizedRect: cheekCrop),
                acneCount: leftDetections.count,
                markers: remapMarkers(leftDetections, cropRect: cheekCrop)
            ),
        ]
    }
    
    private func remapMarkers(_ detections: [AcneDetection], cropRect: CGRect) -> [MarkerModel] {
        detections.compactMap { detection in
            let box = detection.normalizedBoundingBox
            let localX = (box.origin.x - cropRect.origin.x) / cropRect.width
            let localY = (box.origin.y - cropRect.origin.y) / cropRect.height
            let localW = box.width  / cropRect.width
            let localH = box.height / cropRect.height
            let localBox = CGRect(x: localX, y: localY, width: localW, height: localH)
            return MarkerModel(
                id: UUID(),
                acneType: detection.acneType,
                confidence: detection.confidence,
                normalizedBoundingBox: localBox
            )
        }
    }
    
    private func cropImage(from jpegData: Data, normalizedRect rect: CGRect) -> Data? {
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
        return UIImage(cgImage: cropped).jpegData(compressionQuality: 0.8)
    }
}
