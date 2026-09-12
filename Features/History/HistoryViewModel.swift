//
//  HistoryViewModel.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

@Observable
final class HistoryViewModel {
    
    private(set) var scans: [ScanRecord] = []
    
    private(set) var isLoading = false
    
    private(set) var error: Error?
    
    private let repository: any ScanHistoryRepository
    
    init(repository: any ScanHistoryRepository) {
        self.repository = repository
    }
    
    func loadHistory() async {
        isLoading = true
        error = nil
        
        do {
            scans = try await repository.fetchHistory()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}
