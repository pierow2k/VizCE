import Foundation

enum WebcamState: Sendable, Equatable {
    case idle, authorizing, starting, previewing, capturing, captured, permissionDenied
    case failed(String)

    var isStarting: Bool { self == .authorizing || self == .starting }
}
