//
//  AVCaptureScanCameraService.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 13/09/26.
//

import Foundation
import AVFoundation

final class AVCaptureScanCameraService: NSObject, ScanCameraServicing {
    
    let captureSession: AVCaptureSession
    weak var delegate: ScanCameraServiceDelegate?
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoProcessingQueue = DispatchQueue(
        label: "rona.camera.video",
        qos: .userInteractive
    )
    private var isSessionConfigured = false
    
    override init() {
        self.captureSession = AVCaptureSession()
        super.init()
    }
    
    func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    func start() {
        configureCaptureSession()
        videoProcessingQueue.async { [weak self] in
            guard let self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stop() {
        videoProcessingQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    private func configureCaptureSession() {
        guard !isSessionConfigured else { return }
        isSessionConfigured = true

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .high

        guard let frontCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            return
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoProcessingQueue)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
    }
}

extension AVCaptureScanCameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        delegate?.cameraService(self, didOutput: sampleBuffer)
    }
}
