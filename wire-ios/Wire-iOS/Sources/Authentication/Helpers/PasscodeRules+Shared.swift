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

import Foundation
import WireUtilities

extension PasswordRuleSet {

    static let passwordRuleSetLogger = WireLogger(tag: "password-rule-set")

    /// The shared rule set.
    static let shared: PasswordRuleSet = {
        let fileURL = Bundle.main.url(forResource: "password_rules", withExtension: "json")!
        let fileData = try! Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try! decoder.decode(PasswordRuleSet.self, from: fileData)
    }()

    static let accountRegistration = PasswordRuleSet.shared
    static let applockPasscode = PasswordRuleSet.shared

    static let nonEmpty = PasswordRuleSet(
        minimumLength: 1,
        maximumLength: .max,
        allowedCharacters: [.unicode],
        requiredCharacters: []
    )

    /// The guestLinkWithPassword rule set.
    /// This rule set is hardcoded, if you end up changing this ruleSet
    /// don't forget to update this string: **secured_guest_link_with_password.textfield.footer**
    /// in Localizable.strings file to reflect the changes in the ruleSet.
    static let guestLinkPassword = PasswordRuleSet(
        minimumLength: 15,
        maximumLength: 20,
        allowedCharacters: [.unicode],
        requiredCharacters: [
            .lowercase,
            .uppercase,
            .digits,
            .special
        ]
    )

    // MARK: - Localized Description

    /// The localized error message for the shared rule set.
    static let localizedErrorMessage: String = {
        let ruleSet = PasswordRuleSet.shared
        let minLengthRule = L10n.Localizable.Registration.Password.Rules.minLength(Int(ruleSet.minimumLength))

        if ruleSet.requiredCharacters.isEmpty {
            return L10n.Localizable.Registration.Password.Rules.noRequirements(minLengthRule)
        }

        let localizedRules: [String] = ruleSet.requiredCharacters.compactMap { requiredClass in
            switch requiredClass {
            case .digits:
                return L10n.Localizable.Registration.Password.Rules.number(1)
            case .lowercase:
                return L10n.Localizable.Registration.Password.Rules.lowercase(1)
            case .uppercase:
                return L10n.Localizable.Registration.Password.Rules.uppercase(1)
            case .special:
                return L10n.Localizable.Registration.Password.Rules.special(1)
            default:
                return nil
            }
        }

        let formattedRulesList = ListFormatter.localizedString(byJoining: localizedRules)

        return L10n.Localizable.Registration.Password.Rules.withRequirements(minLengthRule, formattedRulesList)
    }()

}
