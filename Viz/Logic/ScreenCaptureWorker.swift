import Foundation

/// Owns each capture's file and subprocess. Queue confinement covers operation state
/// and process lifecycle; only immutable encoded data or typed outcomes leave it.
final class ScreenCaptureWorker: Sendable {
    private let queue = DispatchQueue(label: "Viz.screenCapture", qos: .userInitiated)
    private let executable: URL
    private let arguments: @Sendable (URL) -> [String]
    private let temporaryDirectory: URL

    init(executable: URL = URL(fileURLWithPath: "/usr/sbin/screencapture"),
         temporaryDirectory: URL = FileManager.default.temporaryDirectory,
         arguments: @escaping @Sendable (URL) -> [String] = { ["-ix", "-t", "png", $0.path] }) {
        self.executable = executable
        self.arguments = arguments
        self.temporaryDirectory = temporaryDirectory
    }

    func capture() async -> ScreenCaptureOutcome {
        let state = ScreenCaptureOperationState()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                queue.async {
                    guard !state.cancelled else {
                        state.finished = true
                        continuation.resume(returning: .cancelled)
                        return
                    }
                    let directory = self.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                    let imageURL = directory.appendingPathComponent("capture.png")
                    let diagnosticsURL = directory.appendingPathComponent("diagnostics.txt")
                    var output: FileHandle?
                    do {
                        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                        guard FileManager.default.createFile(atPath: diagnosticsURL.path, contents: nil) else {
                            throw CocoaError(.fileWriteUnknown)
                        }
                        let handle = try FileHandle(forWritingTo: diagnosticsURL)
                        output = handle
                        let process = Process()
                        state.process = process
                        process.executableURL = self.executable
                        process.arguments = self.arguments(imageURL)
                        // A file avoids a full diagnostic pipe blocking completion/cancellation.
                        process.standardOutput = handle
                        process.standardError = handle
                        process.terminationHandler = { process in
                            self.queue.async {
                                try? handle.close()
                                state.finished = true
                                state.process = nil
                                process.terminationHandler = nil
                                guard !state.cancelled else {
                                    try? FileManager.default.removeItem(at: directory)
                                    continuation.resume(returning: .cancelled)
                                    return
                                }
                                let diagnostics = (try? String(contentsOf: diagnosticsURL, encoding: .utf8))?
                                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                                let outcome: ScreenCaptureOutcome
                                if process.terminationReason == .exit, process.terminationStatus == 0,
                                   let data = try? Data(contentsOf: imageURL), !data.isEmpty {
                                    outcome = .image(data)
                                } else if process.terminationReason == .exit,
                                          [0, 1].contains(process.terminationStatus), diagnostics.isEmpty,
                                          !FileManager.default.fileExists(atPath: imageURL.path) {
                                    // Escape (or Control directing capture to clipboard) produced no owned file.
                                    outcome = .cancelled
                                } else {
                                    let detail = diagnostics.isEmpty ? String(localized: "Process exited with status \(process.terminationStatus).") : diagnostics
                                    outcome = .failure(.screenCapture(detail))
                                }
                                try? FileManager.default.removeItem(at: directory)
                                continuation.resume(returning: outcome)
                            }
                        }
                        try process.run()
                    } catch {
                        state.finished = true
                        state.process?.terminationHandler = nil
                        state.process = nil
                        try? output?.close()
                        try? FileManager.default.removeItem(at: directory)
                        continuation.resume(returning: .failure(.screenCapture(error.localizedDescription)))
                    }
                }
            }
        } onCancel: {
            self.queue.async {
                guard !state.finished else { return }
                state.cancelled = true
                state.process?.terminate()
            }
        }
    }
}
