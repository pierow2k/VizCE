import Foundation

/// A compiler for whole-argument OCR placeholders in a restricted shell template syntax.
enum ShellTemplate {
    /// Replaces supported whole-argument placeholders with a quoted environment variable reference.
    ///
    /// Templates without `[ocr]` pass through unchanged after the NUL check. Templates
    /// with placeholders are scanned using the restricted syntax implemented here.
    ///
    /// - Parameter template: Shell text whose placeholders may be bare, single-quoted, or double-quoted whole arguments.
    /// - Throws: An encoding error for NUL characters or a template error for unsupported placeholder syntax.
    static func compile(_ template: String) throws -> String {
        guard !template.contains("\0") else { throw CocoaError(.fileReadInapplicableStringEncoding) }
        guard template.contains("[ocr]") else { return template }
        let input = Array(template)
        var output = ""
        var index = 0
        var needsCommand = true
        var needsRedirectionTarget = false
        let compoundKeywords: Set<String> = ["if", "then", "else", "elif", "fi", "for", "while", "until", "do", "done", "case", "esac", "function", "repeat", "select", "coproc", "time", "!", "{", "}", "[[", "]]"]
        while index < input.count {
            let character = input[index]
            if character == "#" {
                while index < input.count, input[index] != "\n" {
                    output.append(input[index])
                    index += 1
                }
                continue
            }
            if character == "(" || character == ")" || character == "`" ||
                (character == "<" && index + 1 < input.count && input[index + 1] == "<") {
                throw unsupported()
            }
            if character == "<" || character == ">" ||
                (character == "&" && index + 1 < input.count && input[index + 1] == ">") {
                needsRedirectionTarget = true
                output.append(character)
                index += 1
                if index < input.count && ">&|".contains(input[index]) {
                    output.append(input[index])
                    index += 1
                }
                continue
            }
            if boundaries.contains(character) {
                if ";|&\n".contains(character) {
                    guard !needsRedirectionTarget else { throw unsupported() }
                    needsCommand = true
                }
                output.append(character)
                index += 1
                continue
            }
            let word = try scanWord(input, index: &index)
            if needsCommand && !needsRedirectionTarget && compoundKeywords.contains(word) { throw unsupported() }
            if wholeArgumentPlaceholders.contains(word) {
                guard !needsCommand || needsRedirectionTarget else { throw unsupported() }
                // Quoting the environment reference keeps captured text inside one shell argument.
                output += "\"${VIZ_OCR_TEXT}\""
            } else {
                guard !word.contains("[ocr]") else { throw unsupported() }
                output += word
            }
            if needsRedirectionTarget { needsRedirectionTarget = false }
            else if !word.contains("=") {
                // A leading file descriptor belongs to a redirection, not the command word.
                let isFileDescriptor = word.allSatisfy(\.isNumber) && index < input.count && "<>".contains(input[index])
                if !isFileDescriptor { needsCommand = false }
            }
        }
        guard !needsRedirectionTarget else { throw unsupported() }
        return output
    }

    /// Unquoted characters that delimit words, commands, or redirections in the supported grammar.
    private static let boundaries = " \t\r\n;|&<>"
    /// The only complete shell words that may be replaced with the captured-text variable.
    private static let wholeArgumentPlaceholders: Set<String> = ["[ocr]", "\"[ocr]\"", "'[ocr]'"]

    /// Scans one shell word while preserving quotes and escapes and rejecting unsupported expansions.
    ///
    /// Advances `index` to the next unquoted boundary or the end of `input`.
    private static func scanWord(_ input: [Character], index: inout Int) throws -> String {
        var word = ""
        var quote: Character?
        while index < input.count {
            let current = input[index]
            if quote == nil && boundaries.contains(current) { break }
            if current == "\\" && quote != "'" {
                guard index + 1 < input.count else { throw unsupported() }
                word.append(current)
                word.append(input[index + 1])
                index += 2
                continue
            }
            if quote != "'", current == "$", index + 1 < input.count, input[index + 1] == "{" {
                throw unsupported()
            }
            if current == "'" || current == "\"" {
                if quote == current { quote = nil }
                else if quote == nil { quote = current }
            } else if quote != "'" && (current == "`" || current == "(" || current == ")") {
                throw unsupported()
            }
            word.append(current)
            index += 1
        }
        guard quote == nil else { throw unsupported() }
        return word
    }

    /// Creates the template-validation error describing the supported placeholder contexts.
    private static func unsupported() -> NSError {
        NSError(domain: "Viz.PostProcessing", code: 1, userInfo: [NSLocalizedDescriptionKey:
            "Use [ocr], \"[ocr]\", or '[ocr]' as a whole argument in ordinary commands. Embedded placeholders, substitutions, heredocs, compound statements, and braced parameter expressions are unsupported."])
    }
}
