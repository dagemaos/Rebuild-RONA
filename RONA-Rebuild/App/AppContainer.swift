//
//  AppContainer.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

final class AppContainer {
    
    let scanHistoryRepository: any ScanHistoryRepository
    let faceAnalyzer: any FaceAnalyzing
    let scanService: any ScanServicing
    
    init() {
        let repository = FileSystemScanHistoryRepository()
        let analyzer = CoreMLFaceAnalyzer()
        let scanService = ScanService(
            analyzer: analyzer,
            historyRepository: repository
        )
        
        self.scanHistoryRepository = repository
        self.faceAnalyzer = analyzer
        self.scanService = scanService
    }
    
    func makeScanView(onDismiss: @escaping () -> Void) -> ScanView {
        let viewModel = ScanViewModel(scanService: scanService)
        return ScanView(
            viewModel: viewModel,
            onScanSaved: { _, _ in }, // Mock for now
            onDismiss: onDismiss
        )
    }
}

