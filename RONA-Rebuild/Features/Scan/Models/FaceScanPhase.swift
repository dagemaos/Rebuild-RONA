import Foundation

/// Represents the current phase of the face scan lifecycle.
enum FaceScanPhase: Equatable {
    case requestingPermission
    case permissionDenied
    case scanning
    case processing
    case completed(ScanResult)
    case error(message: String)
}
