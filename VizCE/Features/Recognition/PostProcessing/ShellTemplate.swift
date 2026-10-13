import Foundation

/// A compiler for whole-argument OCR placeholders in a restricted shell template syntax.
enum ShellTemplate {
    /// Replaces supported whole-argument placeholders with a quoted environment variable reference.
    ///
    /// Templates without `[ocr]` pass through unchanged after the NUL check. Templates
    /// with placeholders are scanned using the restricted syntax implemented here.
    ///
    /// - Parameter template: Shell text with bare, single-quoted, or double-quoted whole-argument placeholders.
    /// - Throws: An encoding error for NUL characters or a template error for unsupported placeholder syntax.
    static func compile(_ template: String) throws -> String {
        guard !template.contains("\0") else { throw CocoaError(.fileReadInapplicableStringEncoding) }
        guard template.contains("[ocr]") else { return template }
        var scanner = Scanner(input: Array(template))
        return try scanner.compile()
    }

    /// Maintains command and redirection positions while copying the original shell text.
    private struct Scanner {
        let input: [Character]
        var output = ""
        /// The next unconsumed character; each helper advances past exactly the text it copies.
        var index = 0
        /// Whether the next ordinary word must supply the command name after any assignments or redirections.
        var needsCommand = true
        /// Whether a copied redirection still requires its target word before a command separator or end of input.
        var needsRedirectionTarget = false

        /// Scans in grammar precedence order, rejecting incomplete redirections at the end.
        mutating func compile() throws -> String {
            while index < input.count {
                let character = input[index]
                if character == "#" {
                    consumeComment()
                    continue
                }
                try rejectUnsupportedOperator(character)
                if consumeRedirection(character) { continue }
                if try consumeBoundary(character) { continue }
                try consumeWord()
            }
            guard !needsRedirectionTarget else { throw unsupported() }
            return output
        }

        /// Copies a comment verbatim, leaving its terminating newline for the next scan step.
        private mutating func consumeComment() {
            while index < input.count, input[index] != "\n" {
                output.append(input[index])
                index += 1
            }
        }

        /// Rejects substitutions, grouping, and heredocs before ordinary redirection handling.
        private func rejectUnsupportedOperator(_ character: Character) throws {
            if character == "(" || character == ")" || character == "`"
                || (character == "<" && index + 1 < input.count && input[index + 1] == "<") {
                throw unsupported()
            }
        }

        /// Copies a redirection operator and marks the next word as its required target.
        private mutating func consumeRedirection(_ character: Character) -> Bool {
            guard character == "<" || character == ">"
                || (character == "&" && index + 1 < input.count && input[index + 1] == ">") else {
                return false
            }
            needsRedirectionTarget = true
            output.append(character)
            index += 1
            if index < input.count, ">&|".contains(input[index]) {
                output.append(input[index])
                index += 1
            }
            return true
        }

        /// Copies a grammar boundary, resetting command position only for command separators.
        private mutating func consumeBoundary(_ character: Character) throws -> Bool {
            guard boundaries.contains(character) else { return false }
            if ";|&\n".contains(character) {
                guard !needsRedirectionTarget else { throw unsupported() }
                needsCommand = true
            }
            output.append(character)
            index += 1
            return true
        }

        /// Copies or replaces one word, then updates its command or redirection position.
        private mutating func consumeWord() throws {
            let word = try scanWord(input, index: &index)
            try validateCommandWord(word)
            output += try renderedWord(word)
            updatePosition(after: word)
        }

        /// Rejects compound keywords only where an ordinary command name is required.
        private func validateCommandWord(_ word: String) throws {
            if needsCommand, !needsRedirectionTarget, compoundKeywords.contains(word) { throw unsupported() }
        }

        /// Quotes a complete argument placeholder or preserves a literal word, rejecting embedded placeholders.
        ///
        /// A placeholder can supply a redirection target, but cannot supply the command name.
        private func renderedWord(_ word: String) throws -> String {
            if wholeArgumentPlaceholders.contains(word) {
                guard !needsCommand || needsRedirectionTarget else { throw unsupported() }
                // Quoting the environment reference keeps captured text inside one shell argument.
                return "\"${VIZCE_OCR_TEXT}\""
            }
            guard !word.contains("[ocr]") else { throw unsupported() }
            return word
        }

        /// Satisfies a pending redirection target or consumes a command word after assignments and descriptors.
        private mutating func updatePosition(after word: String) {
            if needsRedirectionTarget {
                needsRedirectionTarget = false
            } else if !word.contains("=") {
                if !isFileDescriptor(word) { needsCommand = false }
            }
        }

        /// Recognizes a numeric word immediately followed by a redirection, which cannot supply the command name.
        private func isFileDescriptor(_ word: String) -> Bool {
            word.allSatisfy(\.isNumber) && index < input.count && "<>".contains(input[index])
        }
    }

    /// Compound command words rejected when a template requires an ordinary command name.
    private static let compoundKeywords: Set<String> = [
        "if", "then", "else", "elif", "fi", "for", "while", "until", "do", "done", "case", "esac", "function",
        "repeat", "select", "coproc", "time", "!", "{", "}", "[[", "]]"
    ]

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
            if quote == nil, boundaries.contains(current) { break }
            if try consumeEscape(input, index: &index, quote: quote, word: &word) { continue }
            try validateExpansion(input, index: index, quote: quote)
            updateQuote(current, quote: &quote)
            word.append(current)
            index += 1
        }
        guard quote == nil else { throw unsupported() }
        return word
    }

    /// Copies an escape pair outside single quotes and advances `index` past both characters.
    ///
    /// - Parameters:
    ///   - input: The original shell characters.
    ///   - index: The current character, left unchanged when no escape is consumed.
    ///   - quote: The active quote delimiter, or `nil` outside quotes.
    ///   - word: The shell word receiving the unchanged escape pair.
    /// - Returns: Whether an escape pair was consumed.
    /// - Throws: A template error when an active escape has no following character.
    private static func consumeEscape(
        _ input: [Character], index: inout Int, quote: Character?, word: inout String
    ) throws -> Bool {
        guard input[index] == "\\", quote != "'" else { return false }
        guard index + 1 < input.count else { throw unsupported() }
        word.append(input[index])
        word.append(input[index + 1])
        index += 2
        return true
    }

    /// Rejects braced parameters, command substitutions, and grouping outside single quotes.
    ///
    /// Escapes are consumed before this check so escaped operators remain literal.
    ///
    /// - Parameters:
    ///   - input: The original shell characters.
    ///   - index: The unescaped character being validated.
    ///   - quote: The active quote delimiter, or `nil` outside quotes.
    /// - Throws: A template error for an unsupported expansion or grouping character.
    private static func validateExpansion(_ input: [Character], index: Int, quote: Character?) throws {
        guard quote != "'" else { return }
        let current = input[index]
        if current == "$", index + 1 < input.count, input[index + 1] == "{" { throw unsupported() }
        if "`()".contains(current) { throw unsupported() }
    }

    /// Opens or closes matching quotes, leaving the other quote kind literal inside an active quote.
    private static func updateQuote(_ current: Character, quote: inout Character?) {
        guard current == "'" || current == "\"" else { return }
        if quote == current {
            quote = nil
        } else if quote == nil {
            quote = current
        }
    }

    /// Creates the template-validation error describing the supported placeholder contexts.
    private static func unsupported() -> NSError {
        NSError(
            domain: "VizCE.PostProcessing",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Use [ocr], \"[ocr]\", or '[ocr]' as a whole argument in ordinary commands. "
                    + "Embedded placeholders, substitutions, heredocs, compound statements, "
                    + "and braced parameter expressions are unsupported."
            ]
        )
    }
}
