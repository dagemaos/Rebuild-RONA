//
//  ScanCameraService.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 13/09/26.
//

import AVFoundation
import CoreMedia

protocol ScanCameraServiceDelegate: AnyObject {
    func cameraService(_ service: ScanCameraServicing, didOutput sampleBuffer: CMSampleBuffer)
}

protocol ScanCameraServicing: AnyObject {
    var captureSession: AVCaptureSession { get }
    var delegate: ScanCameraServiceDelegate? { get set }
    
    func requestPermission() async -> Bool
    func start()
    func stop()
}
