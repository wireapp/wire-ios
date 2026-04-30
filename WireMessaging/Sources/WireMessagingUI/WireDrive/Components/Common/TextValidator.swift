//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

struct TextValidator {
    enum Rule: Hashable {
        case notEmptyOrWhitespace
        case maxLength(Int)
        case doesntContain([Character])
        case doesntStartWithDot
    }
    
    enum Kind: Hashable {
        case fileName
        case folderName
        case fileTag
    }
    
    enum ValidationResult: Hashable {
        case valid
        case invalid(violatedRules: [Rule])
    }
    
    func validate(_ text: String, for kind: Kind) -> ValidationResult {
        let violatedRules = kind.rules.filter { rule in !isTextValid(text, for: rule) }
        return if violatedRules.isEmpty {
            .valid
        } else {
            .invalid(violatedRules: violatedRules)
        }
    }
    
    private func isTextValid(_ text: String, for rule: Rule) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return switch rule {
        case .notEmptyOrWhitespace:
            !trimmed.isEmpty
        case let .maxLength(length):
            trimmed.count <= length
        case let .doesntContain(characters):
            !trimmed.contains { characters.contains($0) }
        case .doesntStartWithDot:
            !trimmed.hasPrefix(".")
        }
    }
}

extension TextValidator.Kind {
    var rules: [TextValidator.Rule] {
        switch self {
        case .fileName, .folderName:
            [
                .notEmptyOrWhitespace,
                .doesntStartWithDot,
                .maxLength(64),
                .doesntContain(["/", "\\", "\""]),
            ]
        case .fileTag:
            [
                .notEmptyOrWhitespace,
                .maxLength(30),
                .doesntContain([",", ";", "/", "\\", "\"", "'", "<", ">"]),
            ]
        }
    }
}

extension TextValidator.Rule {
    func localizedViolationMessage(for kind: TextValidator.Kind) -> String? {
        typealias Strings = L10n.Localizable.Conversation.WireCells
        
        switch self {
        case .notEmptyOrWhitespace:
            return nil
        case .maxLength(_):
            switch kind {
            case .fileTag:
                return Strings.Tags.Error.nameTooLong
            case .fileName:
                return Strings.Files.RenameFile.filenameTooLongError
            case .folderName:
                return Strings.Files.RenameFolder.folderNameTooLongError
            }
        case let .doesntContain(invalidCharacters):
            switch kind {
            case .fileTag:
                return Strings.Tags.Error.specialCharacters.replacing(
                    "{0}",
                    with: formattedInvalidCharacters(invalidCharacters)
                )
            case .fileName, .folderName:
                return Strings.Files.RenameFile.wrongCharacterError.replacingOccurrences(
                    of: "{0}",
                    with: formattedInvalidCharacters(invalidCharacters)
                )
            }
        case .doesntStartWithDot:
            switch kind {
            case .fileTag:
                return nil
            case .fileName, .folderName:
                return Strings.Files.RenameFile.wrongCharacterError.replacingOccurrences(
                    of: "{0}",
                    with: formattedInvalidCharacters(invalidCharactersForFileName())
                )
            }
        }
    }
    
    private func invalidCharactersForFileName() -> [Character] {
        // find the rules for file name validation:
        let fileNameRules = TextValidator.Kind.fileName.rules
        
        // find the rule about the invalid characters:
        let invalidCharactersRule = fileNameRules.first { rule in
            if case .doesntContain = rule { true } else { false }
        }
        
        // extract the invalid characters from the rule:
        let invalidCharacters: [Character] = invalidCharactersRule.map { rule in
            switch rule {
            case let .doesntContain(characters):
                characters
            default:
                fatalError()
            }
        } ?? []
        
        return invalidCharacters
    }
    
    private func formattedInvalidCharacters(_ characters: [Character]) -> String {
        let nonBreakingSpace = "\u{A0}"
        return characters.map { String($0) }.joined(separator: nonBreakingSpace)
    }
}

extension Collection<TextValidator.Rule> {
    func localizedViolationMessages(for kind: TextValidator.Kind) -> [String] {
        compactMap { $0.localizedViolationMessage(for: kind) }
    }
}

extension TextValidator.ValidationResult {
    func firstLocalizedViolationMessage(for kind: TextValidator.Kind) -> String? {
        switch self {
        case .valid:
            nil
        case let .invalid(violatedRules):
            violatedRules.compactMap(\.self).first?.localizedViolationMessage(for: kind)
        }
    }
}
