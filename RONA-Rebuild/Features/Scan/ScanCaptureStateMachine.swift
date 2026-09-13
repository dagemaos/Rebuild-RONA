import Foundation
import CoreMedia

protocol ScanCaptureStateMachineDelegate: AnyObject {
    func stateMachine(_ machine: ScanCaptureStateMachine, didUpdateReadiness readiness: FaceScanReadiness)
    func stateMachine(_ machine: ScanCaptureStateMachine, didUpdateHoldProgress progress: Double)
    func stateMachine(_ machine: ScanCaptureStateMachine, didCompleteAngle angle: FaceZone, with image: Data)
    func stateMachineDidCompleteAllAngles(_ machine: ScanCaptureStateMachine)
    func stateMachine(_ machine: ScanCaptureStateMachine, didFailWithError error: Error)
}

final class ScanCaptureStateMachine {
    
    weak var delegate: ScanCaptureStateMachineDelegate?
    
    private(set) var currentAngleTarget: FaceZone = .front
    private(set) var holdProgress: Double = 0.0
    private(set) var completedAngles: Int = 0
    private(set) var readiness: FaceScanReadiness = .searchingFace
    
    private var previousFrameData: FaceFrameData?
    private var holdStartTime: Date?
    private var lastSampleBuffer: CMSampleBuffer?
    
    private let holdDuration: TimeInterval = 0.5
    private let angleSequence: [FaceZone] = [.front, .leftAngle, .rightAngle]
    
    private let faceTracker = LiveFaceTracker()
    private var capturedImages: [FaceZone: Data] = [:]
    
    init() {
        faceTracker.delegate = self
    }
    
    func reset() {
        currentAngleTarget = .front
        holdProgress = 0.0
        completedAngles = 0
        previousFrameData = nil
        capturedImages = [:]
        holdStartTime = nil
        lastSampleBuffer = nil
        readiness = .searchingFace
        delegate?.stateMachine(self, didUpdateReadiness: readiness)
        delegate?.stateMachine(self, didUpdateHoldProgress: holdProgress)
    }
    
    func process(sampleBuffer: CMSampleBuffer) {
        faceTracker.process(sampleBuffer: sampleBuffer)
    }
    
    private func computeReadiness(frameData: FaceFrameData) -> FaceScanReadiness {
        guard FaceValidation.isPositionValid(boundingBox: frameData.boundingBox) else {
            return .faceOutOfGuide
        }
        guard FaceValidation.isProximityValid(faceWidth: frameData.boundingBox.width) else {
            return .tooFar
        }
        
        let yaw = frameData.yaw ?? 0.0
        let pitch = frameData.pitch ?? 0.0
        guard FaceValidation.isPoseMatched(
            yaw: yaw,
            pitch: pitch,
            target: currentAngleTarget
        ) else {
            let direction: String
            switch currentAngleTarget {
            case .front: direction = "Front"
            case .leftAngle: direction = "Right"
            case .rightAngle: direction = "Left"
            }
            return .wrongAngle(direction)
        }
        
        if let previous = previousFrameData {
            guard FaceValidation.isStable(current: frameData, previous: previous) else {
                return .unstable
            }
        }
        return .ready
    }
    
    private func updateHoldProgress() {
        if holdStartTime == nil {
            holdStartTime = Date()
        }
        guard let startTime = holdStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        holdProgress = min(elapsed / holdDuration, 1.0)
        delegate?.stateMachine(self, didUpdateHoldProgress: holdProgress)
        
        if holdProgress >= 1.0 {
            captureCurrentFrame()
        }
    }
    
    private func resetHoldState() {
        if holdProgress != 0.0 || holdStartTime != nil {
            holdStartTime = nil
            holdProgress = 0.0
            delegate?.stateMachine(self, didUpdateHoldProgress: holdProgress)
        }
    }
    
    private func captureCurrentFrame() {
        guard let sampleBuffer = lastSampleBuffer else { return }
        guard let jpegData = faceTracker.extractJPEGData(from: sampleBuffer) else {
            delegate?.stateMachine(self, didFailWithError: ScanError.unknown("Gagal mengambil gambar"))
            return
        }
        
        capturedImages[currentAngleTarget] = jpegData
        completedAngles = capturedImages.count
        let capturedAngle = currentAngleTarget
        
        delegate?.stateMachine(self, didCompleteAngle: capturedAngle, with: jpegData)
        
        resetHoldState()
        
        if completedAngles < angleSequence.count {
            currentAngleTarget = angleSequence[completedAngles]
            readiness = .searchingFace
            delegate?.stateMachine(self, didUpdateReadiness: readiness)
        } else {
            delegate?.stateMachineDidCompleteAllAngles(self)
        }
    }
}

extension ScanCaptureStateMachine: LiveFaceTrackingDelegate {
    func faceTracker(_ tracker: LiveFaceTracker, didDetectFace frameData: FaceFrameData, sampleBuffer: CMSampleBuffer) {
        let newReadiness = computeReadiness(frameData: frameData)
        
        if readiness != newReadiness {
            readiness = newReadiness
            delegate?.stateMachine(self, didUpdateReadiness: readiness)
        }
        
        previousFrameData = frameData
        
        if newReadiness == .ready {
            lastSampleBuffer = sampleBuffer
            updateHoldProgress()
        } else {
            resetHoldState()
        }
    }
    
    func faceTracker(_ tracker: LiveFaceTracker, didLoseFaceWith condition: LightingCondition) {
        if readiness != .searchingFace {
            readiness = .searchingFace
            delegate?.stateMachine(self, didUpdateReadiness: readiness)
        }
        resetHoldState()
        previousFrameData = nil
    }
}
