import Foundation

/// An immutable color record for JSON persistence and transfer across concurrency boundaries.
struct StoredColorItem: Codable, Sendable, Equatable {
    let id: String
    let hex: String
    let rgb: String
}
