import Foundation

/// Counts requests to each unique test URL under a lock for deterministic retry fixtures.
final class ReleaseRequestCounts: @unchecked Sendable {
    private let lock = NSLock()
    /// Access is protected by `lock`, including increments from URLSession worker threads.
    private var counts: [URL: Int] = [:]

    /// Returns the next attempt number, starting at one, for the supplied test URL.
    func next(for url: URL) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let count = counts[url, default: 0] + 1
        counts[url] = count
        return count
    }
}
