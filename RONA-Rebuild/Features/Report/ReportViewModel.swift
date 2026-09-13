//
//  ReportViewModel.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

import Foundation
import Observation

@Observable
final class ReportViewModel {
    
    private(set) var reportData: ReportData?
    
    private(set) var isLoading = false
    private(set) var error: Error?
    
    private let repository: any ScanHistoryRepository
    
    init(repository: any ScanHistoryRepository) {
        self.repository = repository
    }
    
    func loadReport() async {
        isLoading = true
        error = nil
        
        do {
            let scans = try await repository.fetchHistory()
            
            reportData = buildReportData(from: scans)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func buildReportData(
        from scans: [ScanRecord]
    ) -> ReportData {
        
        // report spesific transformation
        return ReportData(scans: scans)
    }
}
