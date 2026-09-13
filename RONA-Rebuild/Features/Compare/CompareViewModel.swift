//
//  CompareViewModel.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

import Foundation
import Observation

@Observable
final class CompareViewModel {
    
    private(set) var comparison: ComparisonResult?
    
    private let repository: any ScanHistoryRepository
    
    init(repository: any ScanHistoryRepository) {
        self.repository = repository
    }
    
    func compare(
        previousID: UUID,
        latestID: UUID
    ) async {
        // fetch records
        // find requested records
        // calculate differences
        // update comparison
    }
}
