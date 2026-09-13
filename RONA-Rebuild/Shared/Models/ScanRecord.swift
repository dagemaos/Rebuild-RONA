import Foundation

struct ScanRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let photo: URL
    let result: ScanResult
}
