//
//  ScanService.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

protocol ScanServicing {
    func scan() async throws -> ScanResult
}

final class ScanService: ScanServicing {
    
    private let analyzer: any FaceAnalyzing
    private let historyRepository: any ScanHistoryRepository
    
    init(
        analyzer: any FaceAnalyzing,
        historyRepository: any ScanHistoryRepository
    ) {
        self.analyzer = analyzer
        self.historyRepository = historyRepository
    }
    
    func performScan() async throws -> ScanResult {
        
        let result = try await analyzer.analyze(/* image */)
        
        let record = ScanRecord(
            /* construct from result */
        )
        
        try await historyRepository.save(record)
        
        return result
    }
}
