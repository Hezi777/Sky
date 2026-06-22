import Foundation

struct EnvFileParseResult: Equatable {
    let values: [String: String]
    let ignoredKeyNames: Set<String>
    let invalidLineNumbers: [Int]
}

struct EnvFileParser {
    let allowedKeyNames: Set<String>

    init(allowedKeyNames: Set<String>) {
        self.allowedKeyNames = allowedKeyNames
    }

    func parse(_ contents: String) -> EnvFileParseResult {
        var values: [String: String] = [:]
        var ignoredKeyNames: Set<String> = []
        var invalidLineNumbers: [Int] = []

        for (offset, sourceLine) in contents.split(
            omittingEmptySubsequences: false,
            whereSeparator: \Character.isNewline
        ).enumerated() {
            let line = sourceLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }

            guard let assignment = parseAssignment(line) else {
                invalidLineNumbers.append(offset + 1)
                continue
            }

            guard allowedKeyNames.contains(assignment.key) else {
                ignoredKeyNames.insert(assignment.key)
                continue
            }
            values[assignment.key] = assignment.value
        }

        return EnvFileParseResult(
            values: values,
            ignoredKeyNames: ignoredKeyNames,
            invalidLineNumbers: invalidLineNumbers
        )
    }

    private func parseAssignment(_ line: String) -> (key: String, value: String)? {
        var assignment = line
        if assignment.hasPrefix("export ") {
            assignment.removeFirst("export ".count)
            assignment = assignment.trimmingCharacters(in: .whitespaces)
        }

        guard let separator = assignment.firstIndex(of: "=") else { return nil }
        let key = assignment[..<separator].trimmingCharacters(in: .whitespaces)
        guard isValidKey(key) else { return nil }

        let valueStart = assignment.index(after: separator)
        let rawValue = assignment[valueStart...].trimmingCharacters(in: .whitespaces)
        guard let value = parseValue(rawValue) else { return nil }
        return (String(key), value)
    }

    private func isValidKey(_ key: String) -> Bool {
        guard let first = key.first, first == "_" || first.isLetter else { return false }
        return key.dropFirst().allSatisfy { $0 == "_" || $0.isLetter || $0.isNumber }
    }

    private func parseValue(_ rawValue: String) -> String? {
        guard let quote = rawValue.first, quote == "\"" || quote == "'" else {
            return stripInlineComment(from: rawValue)
        }

        var value = ""
        var isEscaped = false
        var index = rawValue.index(after: rawValue.startIndex)
        while index < rawValue.endIndex {
            let character = rawValue[index]
            if quote == "\"", isEscaped {
                value.append(character)
                isEscaped = false
            } else if quote == "\"", character == "\\" {
                isEscaped = true
            } else if character == quote {
                let remainderStart = rawValue.index(after: index)
                let remainder = rawValue[remainderStart...].trimmingCharacters(in: .whitespaces)
                guard remainder.isEmpty || remainder.hasPrefix("#") else { return nil }
                return value
            } else {
                value.append(character)
            }
            index = rawValue.index(after: index)
        }
        return nil
    }

    private func stripInlineComment(from rawValue: String) -> String {
        var previousWasWhitespace = false
        for index in rawValue.indices {
            let character = rawValue[index]
            if character == "#", previousWasWhitespace {
                return rawValue[..<index].trimmingCharacters(in: .whitespaces)
            }
            previousWasWhitespace = character.isWhitespace
        }
        return rawValue.trimmingCharacters(in: .whitespaces)
    }
}
