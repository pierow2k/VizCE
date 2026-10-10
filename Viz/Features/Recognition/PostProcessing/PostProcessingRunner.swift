import Foundation

/// A blocking process and its output drain stay on a private queue, behind an async interface.
struct PostProcessingRunner: Sendable {
    var executableURL = URL(fileURLWithPath: "/bin/zsh")

    func run(template: String, content: String) async throws -> String {
        guard !content.contains("\0") else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        let command = try ShellTemplate.compile(template)
        let executableURL = executableURL
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue(label: "Viz.postProcessing", qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                process.executableURL = executableURL
                process.arguments = ["-c", command]
                process.environment = ProcessInfo.processInfo.environment.merging(["VIZ_OCR_TEXT": content]) { _, new in new }
                process.standardOutput = pipe
                process.standardError = pipe
                do {
                    try process.run()
                    // Reading concurrently with the child avoids filling its stdout/stderr pipe.
                    try pipe.fileHandleForWriting.close()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    let output = String(decoding: data, as: UTF8.self)
                    continuation.resume(returning: process.terminationStatus == 0 ? output :
                        "Command exited with status \(process.terminationStatus).\n\(output)")
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
