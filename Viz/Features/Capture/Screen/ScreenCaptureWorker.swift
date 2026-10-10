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
                queue.async { self.launch(state: state, continuation: continuation) }
            }
        } onCancel: {
            self.queue.async {
                guard !state.finished else { return }
                state.cancelled = true
                state.process?.terminate()
            }
        }
    }

    private func launch(state: ScreenCaptureOperationState,
                        continuation: CheckedContinuation<ScreenCaptureOutcome, Never>) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard !state.cancelled else {
            state.finished = true
            continuation.resume(returning: .cancelled)
            return
        }
        let files = ScreenCaptureFiles(temporaryDirectory: temporaryDirectory)
        var output: FileHandle?
        do {
            let handle = try files.prepareDiagnosticOutput()
            output = handle
            let process = Process()
            state.process = process
            process.executableURL = executable
            process.arguments = arguments(files.imageURL)
            // A file avoids a full diagnostic pipe blocking completion/cancellation.
            process.standardOutput = handle
            process.standardError = handle
            process.terminationHandler = { process in
                self.queue.async {
                    let result = self.finish(state: state, files: files, output: handle) {
                        state.cancelled ? .cancelled : self.outcome(for: process, files: files)
                    }
                    continuation.resume(returning: result)
                }
            }
            try process.run()
        } catch {
            let result = finish(state: state, files: files, output: output) {
                .failure(.screenCapture(error.localizedDescription))
            }
            continuation.resume(returning: result)
        }
    }

    private func outcome(for process: Process, files: ScreenCaptureFiles) -> ScreenCaptureOutcome {
        let diagnostics = (try? String(contentsOf: files.diagnosticsURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if process.terminationReason == .exit, process.terminationStatus == 0,
           let data = try? Data(contentsOf: files.imageURL), !data.isEmpty {
            return .image(data)
        }
        if process.terminationReason == .exit, [0, 1].contains(process.terminationStatus),
           diagnostics.isEmpty, !FileManager.default.fileExists(atPath: files.imageURL.path) {
            // Escape (or Control directing capture to clipboard) produced no owned file.
            return .cancelled
        }
        let detail = diagnostics.isEmpty
            ? String(localized: "Process exited with status \(process.terminationStatus).") : diagnostics
        return .failure(.screenCapture(detail))
    }

    private func finish(state: ScreenCaptureOperationState, files: ScreenCaptureFiles,
                        output: FileHandle?, outcome: () -> ScreenCaptureOutcome) -> ScreenCaptureOutcome {
        dispatchPrecondition(condition: .onQueue(queue))
        try? output?.close()
        state.finished = true
        let process = state.process
        state.process = nil
        process?.terminationHandler = nil
        let result = outcome()
        files.remove()
        return result
    }

}
