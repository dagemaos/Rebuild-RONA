//
//  ScanHistoryRepository.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

protocol ScanHistoryRepository {
    func save(_ scan: ScanRecord) async throws
    
    func fetchHistory() async throws -> [ScanRecord]
    
    func fetchLatest() async throws -> ScanRecord?
    
    func fetch(from startDate: Date, to endDate: Date) async throws -> [ScanRecord]
}
