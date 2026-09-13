//
//  LocalScanHistoryRepository.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 08/09/26.
//

import Foundation

final class LocalScanHistoryRepository: ScanHistoryRepository {
    
    func save(_ scan: ScanRecord) async throws {
        // persist scan
    }
    
    func fetchHistory() async throws -> [ScanRecord] {
        // fetch persisted scan
        return []
    }
    
    func fetchLatest() async throws -> ScanRecord? {
        // fetch latest persisted scan
        return nil
    }
    
    func fetch(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [ScanRecord] {
        // fetch scans in date range
        return []
    }
}
