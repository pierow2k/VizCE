import Foundation

/// An asynchronous shell runner that drains combined output on a private queue.
struct PostProcessingRunner: Sendable {
    /// The shell executable used to evaluate templates with `-c`, defaulting to `/bin/zsh`.
    var executableURL = URL(fileURLWithPath: "/bin/zsh")

    /// Runs a template with captured text passed through the environment and returns combined
    /// output.
    ///
    /// A nonzero exit status is reported in the returned text. Canceling the calling task
    /// does not terminate the subprocess.
    ///
    /// - Parameters:
    ///   - template: Shell commands accepted by `ShellTemplate.compile(_:)`.
    ///   - content: Captured text supplied as `VIZCE_OCR_TEXT`, without shell interpolation.
    /// - Returns: Standard output and standard error, prefixed by status text on an unsuccessful
    ///   exit.
    /// - Throws: Template validation, NUL encoding, or process launch errors.
    func run(template: String, content: String) async throws -> String {
        guard !content.contains("\0") else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        let command = try ShellTemplate.compile(template)
        let executableURL = executableURL
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue(label: "VizCE.postProcessing", qos: .userInitiated)
                .async {
                    let process = Process()
                    let pipe = Pipe()
                    process.executableURL = executableURL
                    process.arguments = ["-c", command]
                    process.environment = ProcessInfo.processInfo.environment.merging(
                        ["VIZCE_OCR_TEXT": content]
                    ) { _, new in new }
                    process.standardOutput = pipe
                    process.standardError = pipe
                    do {
                        try process.run()
                        // Reading concurrently with the child avoids filling its stdout/stderr
                        // pipe.
                        try pipe.fileHandleForWriting.close()
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        process.waitUntilExit()
                        // Preserve readable output by replacing malformed UTF-8 bytes with
                        // replacement characters.
                        // swiftlint:disable:next optional_data_string_conversion
                        let output = String(decoding: data, as: UTF8.self)
                        continuation.resume(
                            returning: process.terminationStatus == 0
                                ? output
                                : """
                                Command exited with status \(process.terminationStatus).\n\
                                \(output)
                                """
                        )
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}
