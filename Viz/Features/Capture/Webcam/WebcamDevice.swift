import Foundation

/// A camera identifier and display name that can cross the device discovery boundary.
struct WebcamDevice: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
}
