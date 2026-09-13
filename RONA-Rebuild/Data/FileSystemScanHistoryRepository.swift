import Foundation

final class FileSystemScanHistoryRepository: ScanHistoryRepository {
    private let fileURL: URL
    
    init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.fileURL = paths[0].appendingPathComponent("scan_history.json")
    }
    
    func save(_ scan: ScanRecord) async throws {
        var current = try? await fetchHistory()
        if current == nil { current = [] }
        current?.append(scan)
        
        let data = try JSONEncoder().encode(current)
        try data.write(to: fileURL)
    }
    
    func fetchHistory() async throws -> [ScanRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([ScanRecord].self, from: data)
    }
    
    func fetchLatest() async throws -> ScanRecord? {
        let history = try await fetchHistory()
        return history.max(by: { $0.date < $1.date })
    }
    
    func fetch(from startDate: Date, to endDate: Date) async throws -> [ScanRecord] {
        let history = try await fetchHistory()
        return history.filter { $0.date >= startDate && $0.date <= endDate }
    }
}
