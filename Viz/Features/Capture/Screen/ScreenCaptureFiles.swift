import Foundation

/// Temporary files owned by one screen capture, accessed on the worker queue.
struct ScreenCaptureFiles: Sendable {
    private let directory: URL
    var imageURL: URL { directory.appendingPathComponent("capture.png") }
    var diagnosticsURL: URL { directory.appendingPathComponent("diagnostics.txt") }

    init(temporaryDirectory: URL) {
        directory = temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    func prepareDiagnosticOutput() throws -> FileHandle {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard FileManager.default.createFile(atPath: diagnosticsURL.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return try FileHandle(forWritingTo: diagnosticsURL)
    }

    func remove() { try? FileManager.default.removeItem(at: directory) }
}
