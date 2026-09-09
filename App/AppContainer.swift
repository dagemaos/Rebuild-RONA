//
//  AppContainer.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

final class AppContainer {
    
    let faceAnalyzer: FaceAnalyzer
    let scanHistoryRepository: ScanHistoryRepository
    
    init() {
        let analyzer = CoreMLFaceAnalyzer()
        let store = LocalScanHistoryStore()
        
        self.faceAnalyzer = analyzer
        self.scanHistoryRepository = LocalScanHistoryRepository(store: store)
    }
}

