//
//  AppContainer.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

final class AppContainer {
    
    let scanHistoryRepository: any ScanHistoryRepository
    let faceAnalyzer: FaceAnalyzer
    
    init() {
        let repository = LocalScanHistoryStore()
        let analyzer = CoreMLFaceAnalyzer()
        
        self.scanHistoryRepository = repository
        self.faceAnalyzer = analyzer
    }
}

