import Foundation

/// Compiles the supported whole-argument placeholder forms without interpolating captured data.
enum ShellTemplate {
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
                output += "\"${VIZ_OCR_TEXT}\""
            } else {
                guard !word.contains("[ocr]") else { throw unsupported() }
                output += word
            }
            if needsRedirectionTarget { needsRedirectionTarget = false }
            else if !word.contains("=") {
                let isFileDescriptor = word.allSatisfy(\.isNumber) && index < input.count && "<>".contains(input[index])
                if !isFileDescriptor { needsCommand = false }
            }
        }
        guard !needsRedirectionTarget else { throw unsupported() }
        return output
    }

    private static let boundaries = " \t\r\n;|&<>"
    private static let wholeArgumentPlaceholders: Set<String> = ["[ocr]", "\"[ocr]\"", "'[ocr]'"]

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

    private static func unsupported() -> NSError {
        NSError(domain: "Viz.PostProcessing", code: 1, userInfo: [NSLocalizedDescriptionKey:
            "Use [ocr], \"[ocr]\", or '[ocr]' as a whole argument in ordinary commands. Embedded placeholders, substitutions, heredocs, compound statements, and braced parameter expressions are unsupported."])
    }
}
