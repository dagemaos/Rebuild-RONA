//
//  FaceAnalyzer.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

protocol FaceAnalyzer {
    func analyze(/* input */) async throws -> FaceScanResult
}
