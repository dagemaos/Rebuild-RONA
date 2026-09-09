//
//  ScanHistoryRepository.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

protocol ScanHistoryRepository {
    func fetchAll() async throws -> [ScanRecord]
    func fetchLatest() async throws -> ScanRecord?
    func save(_ record: ScanRecord) async throws
}
