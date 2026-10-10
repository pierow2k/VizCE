import Foundation

/// Temporary image and diagnostic files owned by one screen capture on the worker queue.
struct ScreenCaptureFiles: Sendable {
    private let directory: URL
    var imageURL: URL { directory.appendingPathComponent("capture.png") }
    var diagnosticsURL: URL { directory.appendingPathComponent("diagnostics.txt") }

    /// Assigns a unique subdirectory under the supplied temporary root without creating it yet.
    init(temporaryDirectory: URL) {
        directory = temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    /// Creates the owned directory and diagnostic file and opens a handle for subprocess output.
    ///
    /// - Throws: Directory creation, file creation, or file handle errors.
    func prepareDiagnosticOutput() throws -> FileHandle {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard FileManager.default.createFile(atPath: diagnosticsURL.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return try FileHandle(forWritingTo: diagnosticsURL)
    }

    /// Attempts to remove the owned directory and its files, ignoring cleanup errors.
    func remove() { try? FileManager.default.removeItem(at: directory) }
}
