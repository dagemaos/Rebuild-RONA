//
//  ScanViewModel.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

import Observation

@Observable
final class ScanViewModel {
    private(set) var state: ScanState = .idle
    
    private let scanService: ScanService
    
    init(scanService: ScanService) {
        self.scanService = scanService
    }
    
    func startScan() {
        state = .preparing
        
        Task {
            do {
                state = .scanning
                
                let result = try await scanService.perfomScan()
                
                state = .showingResult(result)
            } catch {
                state = .failed(.unknown)
            }
        }
    }
}
