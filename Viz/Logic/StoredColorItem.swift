import Foundation

struct StoredColorItem: Codable, Sendable, Equatable {
    let id: String
    let hex: String
    let rgb: String
}
