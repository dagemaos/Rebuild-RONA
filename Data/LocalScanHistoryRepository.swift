//
//  LocalScanHistoryRepository.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 08/09/26.
//

final class LocalScanHistoryRepository: ScanHistoryRepository {
    
    func save(_ scan: ScanRecord) async throws {
        // persist scan
    }
    
    func fetchHistory() async throws -> [ScanRecord] {
        // fetch persisted scan
    }
    
    func fetchLatest() async throws -> ScanRecord? {
        // fetch latest persisted scan
    }
    
    func fetch(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [ScanRecord] {
        // fetch scans in date range
    }
    )
}
