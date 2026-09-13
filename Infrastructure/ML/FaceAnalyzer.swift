//
//  FaceAnalyzer.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

import CoreGraphics

protocol FaceAnalyzing {
    func analyze(
        image: CGImage
    ) async throws -> [AcneDetection]
}
