import Observation
import AVFoundation
import _Concurrency

@Observable
@MainActor
final class ScanViewModel {
    
    private(set) var state: ScanState = .idle
    private(set) var readiness: FaceScanReadiness = .searchingFace
    private(set) var holdProgress: Double = 0
    private(set) var currentAngle: FaceZone = .front
    private(set) var completedAngles = 0
    
    let scanService: any ScanServicing
    private var eventTask: Task<Void, Never>?
    
    var captureSession: AVCaptureSession {
        scanService.captureSession
    }
    
    init(scanService: any ScanServicing) {
        self.scanService = scanService
    }
    
    func onViewAppear() {
        startListening()
        scanService.startScan()
    }
    
    func onViewDisappear() {
        scanService.stopScan()
        eventTask?.cancel()
        eventTask = nil
    }
    
    func retry() {
        completedAngles = 0
        currentAngle = .front
        holdProgress = 0
        readiness = .searchingFace
        state = .scanning
        scanService.retry()
    }
    
    private func startListening() {
        eventTask?.cancel()
        eventTask = Task {
            for await event in scanService.events {
                guard !Task.isCancelled else { break }
                await handleEvent(event)
            }
        }
    }
    
    private func handleEvent(_ event: ScanEvent) async {
        switch event {
        case .state(let newState):
            self.state = newState
        case .readiness(let readiness):
            self.readiness = readiness
        case .holdProgress(let progress):
            self.holdProgress = progress
        case .angleCompleted(let angle):
            self.completedAngles += 1
            switch angle {
            case .front: self.currentAngle = .leftAngle
            case .leftAngle: self.currentAngle = .rightAngle
            case .rightAngle: break
            }
        }
    }
}
