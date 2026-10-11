import XCTest

final class PostProcessingTests: XCTestCase {
    func testCommentsPreserveCommandPositionAndLiteralPlaceholders() throws {
        let variable = "\"${VIZCE_OCR_TEXT}\""
        XCTAssertEqual(
            try ShellTemplate.compile("# [ocr]\nprintf '%s' [ocr]"),
            "# [ocr]\nprintf '%s' \(variable)"
        )
        XCTAssertEqual(
            try ShellTemplate.compile("printf '%s' [ocr] # literal [ocr]\nprintf '%s' '[ocr]'"),
            "printf '%s' \(variable) # literal [ocr]\nprintf '%s' \(variable)"
        )
        XCTAssertEqual(
            try ShellTemplate.compile("printf '%s' [ocr] # literal [ocr]"),
            "printf '%s' \(variable) # literal [ocr]"
        )
        XCTAssertThrowsError(try ShellTemplate.compile("# [ocr]\n[ocr]"))
    }

    func testQuotedBoundariesStayWithinTheirOriginalArguments() throws {
        for literal in ["'a;|&<>#'", "\"a;|&<>#\"", "'a(b)`c'", "a\\ b"] {
            XCTAssertEqual(
                try ShellTemplate.compile("printf '%s' \(literal) [ocr]"),
                "printf '%s' \(literal) \"${VIZCE_OCR_TEXT}\""
            )
        }
        for template in ["echo 'unterminated [ocr]", "echo \"unterminated [ocr]", "echo [ocr] \\"] {
            XCTAssertThrowsError(try ShellTemplate.compile(template), template)
        }
    }

    func testDanglingRedirectionsAndCommandPlaceholdersRemainRejected() throws {
        for template in [
            "printf '%s' [ocr] >", "printf '%s' [ocr] >   ", "printf '%s' [ocr] >; echo done",
            "[ocr] argument", "X=1 [ocr]", "echo ok | [ocr]"
        ] {
            XCTAssertThrowsError(try ShellTemplate.compile(template), template)
        }
        XCTAssertEqual(
            try ShellTemplate.compile("> [ocr] printf '%s' '[ocr]'"),
            "> \"${VIZCE_OCR_TEXT}\" printf '%s' \"${VIZCE_OCR_TEXT}\""
        )
        XCTAssertEqual(
            try ShellTemplate.compile("2>/dev/null printf '%s' [ocr]"),
            "2>/dev/null printf '%s' \"${VIZCE_OCR_TEXT}\""
        )
        // Preserve the existing boundary handling for a final newline after a redirection comment.
        XCTAssertEqual(
            try ShellTemplate.compile("printf '%s' [ocr] > # missing target\n"),
            "printf '%s' \"${VIZCE_OCR_TEXT}\" > # missing target\n"
        )
    }

    func testRenamedEnvironmentVariablePreservesPayloadWithoutPlaceholder() async throws {
        let payloads = [
            "", "spaces and café", "line 1\nline 2\n", "'\"\\;|&<>*", "$(printf unexpected) `printf unexpected`"
        ]
        for payload in payloads {
            let output = try await PostProcessingRunner()
                .run(
                    template: "printf '%s' \"$VIZCE_OCR_TEXT\"",
                    content: payload
                )
            XCTAssertEqual(output, payload)
        }
    }

    func testLiteralArgumentsAndNoCommandExecution() async throws {
        let sentinel = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let payloads = [
            "", "spaces and café", "line 1\nline 2\n", "'\"\\;|&<>*",
            "$(touch \(sentinel.path)) `touch \(sentinel.path)`"
        ]
        for form in ["[ocr]", "\"[ocr]\"", "'[ocr]'"] {
            for payload in payloads {
                let output = try await PostProcessingRunner().run(template: "printf '%s' \(form)", content: payload)
                XCTAssertEqual(output, payload)
            }
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: sentinel.path))
    }

    func testMultipleArgumentsAndPipeline() async throws {
        let output = try await PostProcessingRunner()
            .run(template: "printf '%s%s' [ocr] '[ocr]' | cat; printf done", content: "A\n")
        XCTAssertEqual(output, "A\nA\ndone")
    }

    func testUnsupportedContexts() {
        for template in [
            "[ocr]", "X=1 [ocr]", "echo ok; [ocr]", "echo prefix[ocr]", "echo \"prefix [ocr]\"", "echo $(echo [ocr])",
            "echo `[ocr]`", "cat <<EOF\n[ocr]\nEOF", "echo \\[ocr]", "echo $'[ocr]'", "echo '[ocr] suffix'",
            "if [ocr]; then echo yes; fi", "for item in [ocr]; do echo ok; done", "echo ${value:- [ocr] }",
            "> /dev/null [ocr]", "> /dev/null if [ocr]; then echo yes; fi"
        ] {
            XCTAssertThrowsError(try ShellTemplate.compile(template), template)
        }
        XCTAssertEqual(try ShellTemplate.compile("printf unchanged"), "printf unchanged")
        XCTAssertEqual(
            try ShellTemplate.compile("if true; then echo unchanged; fi"),
            "if true; then echo unchanged; fi"
        )
    }

    func testRedirectionsPreserveCommandAndArgumentPositions() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let payload = "exact ' \" $() café\n"
        let output = try await PostProcessingRunner()
            .run(template: "> \(file.path) printf '%s' [ocr]; cat \(file.path)", content: payload)
        XCTAssertEqual(output, payload)
        let combined = try await PostProcessingRunner().run(template: "printf '%s' [ocr] >&2", content: payload)
        XCTAssertEqual(combined, payload)
        let leadingFD = try await PostProcessingRunner()
            .run(template: "2>/dev/null printf '%s' '[ocr]'", content: payload)
        XCTAssertEqual(leadingFD, payload)
    }

    func testLargeOutputAndExitError() async throws {
        let output = try await PostProcessingRunner().run(template: "head -c 1048576 /dev/zero", content: "")
        XCTAssertEqual(output.utf8.count, 1_048_576)
        let failure = try await PostProcessingRunner().run(template: "printf failure >&2; exit 7", content: "")
        XCTAssertTrue(failure.contains("status 7"))
        XCTAssertTrue(failure.contains("failure"))
    }

    func testLaunchAndNulFailures() async {
        do {
            _ = try await PostProcessingRunner(executableURL: URL(fileURLWithPath: "/nonexistent/vizce-shell"))
                .run(template: "echo [ocr]", content: "x")
            XCTFail("Expected a launch failure for the nonexistent shell")
        } catch {
            // Rejection is the expected result for invalid process input.
        }
        do {
            _ = try await PostProcessingRunner().run(template: "echo [ocr]", content: "\0")
            XCTFail("Expected rejection of NUL-containing captured text")
        } catch {
            // Rejection is the expected result for invalid process input.
        }
        do {
            _ = try await PostProcessingRunner()
                .run(template: "echo [ocr]", content: String(repeating: "x", count: 8_000_000))
            XCTFail("Expected a launch failure for an oversized environment payload")
        } catch {
            // Rejection is the expected result for invalid process input.
        }
    }
}
