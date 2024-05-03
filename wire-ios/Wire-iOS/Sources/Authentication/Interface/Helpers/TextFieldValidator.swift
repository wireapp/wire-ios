//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import UIKit
import WireUtilities

final class TextFieldValidator {

    var customValidator: ((String) -> ValidationError?)?

    enum ValidationError: Error, Equatable {
        case tooShort(kind: ValidatedTextField.Kind)
        case tooLong(kind: ValidatedTextField.Kind)
        case invalidUsername
        case invalidEmail
        case invalidPhoneNumber
        case invalidPassword([PasswordValidationResult.Violation])
        case custom(String)
    }

    private func validatePasscode(text: String,
                                  kind: ValidatedTextField.Kind,
                                  isNew: Bool) -> TextFieldValidator.ValidationError? {
        if isNew {
            // If the user is registering, enforce the password rules
            let result = PasswordRuleSet.shared.validatePassword(text)
            switch result {
            case .valid:
                return nil
            case .invalid(let violations):
                return .invalidPassword(violations)
            }
        } else {
            // If the user is signing in, we do not require any format
            return text.isEmpty ? .tooShort(kind: kind) : nil
        }
    }

    func validate(text: String?, kind: ValidatedTextField.Kind) -> TextFieldValidator.ValidationError? {
        guard let text = text else {
            return nil
        }

        if let customError = customValidator?(text) {
            return customError
        }

        switch kind {
        case .email:
            if text.count > 254 {
                return .tooLong(kind: kind)
            } else if !text.isEmail {
                return .invalidEmail
            }

        case .password(let isNew):
            return validatePasscode(text: text, kind: kind, isNew: isNew)
        case .passcode(let isNew):
            return validatePasscode(text: text, kind: kind, isNew: isNew)
        case .name:
            // We should ignore leading/trailing whitespace when counting the number of characters in the string
            let stringToValidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if stringToValidate.count > 64 {
                return .tooLong(kind: kind)
            } else if stringToValidate.count < 2 {
                return .tooShort(kind: kind)
            }
        case .username:
            let subset = CharacterSet(charactersIn: text).isSubset(of: HandleValidation.allowedCharacters)
            guard subset && text.isEqualToUnicodeName else { return .invalidUsername }
            guard text.count >= HandleValidation.allowedLength.lowerBound else { return .tooShort(kind: .username) }
            guard text.count <= HandleValidation.allowedLength.upperBound else { return .tooLong(kind: .username) }
        case .phoneNumber, .unknown:
            // phone number is validated with the custom validator
            break
        }

        return .none

    }
}

extension TextFieldValidator {

    var passwordRules: UITextInputPasswordRules {
        return UITextInputPasswordRules(descriptor: PasswordRuleSet.shared.encodeInKeychainFormat())
    }

}

extension TextFieldValidator.ValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .tooShort(kind: let kind):
            switch kind {
            case .name:
                return L10n.Localizable.Name.Guidance.tooshort
            case .email:
                return L10n.Localizable.Email.Guidance.tooshort
            case .password, .passcode:
                return PasswordRuleSet.localizedErrorMessage
            case .unknown:
                // swiftlint:disable todo_requires_jira_link
                // TODO: - [AGIS] This string doesn't exist, replace it
                return "unknown.guidance.tooshort".localized
            case .phoneNumber:
                return L10n.Localizable.Phone.Guidance.tooshort
            case .username:
                return L10n.Localizable.Name.Guidance.tooshort
            }
        case .tooLong(kind: let kind):
            switch kind {
            case .name:
                return L10n.Localizable.Name.Guidance.toolong
            case .email:
                return L10n.Localizable.Email.Guidance.toolong
            case .password, .passcode:
                return L10n.Localizable.Password.Guidance.toolong
            case .unknown:
                // TODO: - [AGIS] This string doesn't exist, replace it
                // swiftlint:enable todo_requires_jira_link
                return "unknown.guidance.toolong".localized
            case .phoneNumber:
                return L10n.Localizable.Phone.Guidance.toolong
            case .username:
                return L10n.Localizable.Name.Guidance.toolong
            }
        case .invalidEmail:
            return L10n.Localizable.Email.Guidance.invalid
        case .invalidPhoneNumber:
            return L10n.Localizable.Phone.Guidance.invalid
        case .custom(let description):
            return description
        case .invalidPassword(let violations):
            return violations.contains(.tooLong)
                ? L10n.Localizable.Password.Guidance.toolong
                : PasswordRuleSet.localizedErrorMessage
        case .invalidUsername:
            return "invalid"
        }
    }

}

// MARK: - Email validator

extension String {
    var isEmail: Bool {
        guard !self.hasPrefix("mailto:") else { return false }

        guard let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return false }

        let stringToMatch = self.trimmingCharacters(in: .whitespacesAndNewlines) // We should ignore leading/trailing whitespace
        let range = NSRange(location: 0, length: stringToMatch.count)
        let firstMatch = dataDetector.firstMatch(in: stringToMatch, options: NSRegularExpression.MatchingOptions.reportCompletion, range: range)

        let numberOfMatches = dataDetector.numberOfMatches(in: stringToMatch, options: NSRegularExpression.MatchingOptions.reportCompletion, range: range)

        if firstMatch?.range.location == NSNotFound { return false }
        if firstMatch?.url?.scheme != "mailto" { return false }
        if firstMatch?.url?.absoluteString.hasSuffix(stringToMatch) == false { return false }
        if numberOfMatches != 1 { return false }

        /// patch the NSDataDetector for its false-positive cases
        if self.contains("..") { return false }

        return true
    }
}
