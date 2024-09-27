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

final class SetPasswordStepDescription: DefaultValidatingStepDescription {
    // MARK: Lifecycle

    init() {
        self.backButton = BackButtonDescription()
        let textField = TextFieldDescription(
            placeholder: L10n.Localizable.Password.placeholder.capitalized,
            actionDescription: L10n.Localizable.General.next,
            kind: .password(.accountRegistration, isNew: true)
        )
        textField.useDeferredValidation = true
        self.mainView = textField
        self.headline = L10n.Localizable.Team.Password.headline
        self.subtext = nil
        self.secondaryView = nil
        self.initialValidation = .info(PasswordRuleSet.localizedErrorMessage)
        self.footerView = nil
    }

    // MARK: Internal

    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: NSAttributedString?
    let secondaryView: AuthenticationSecondaryViewDescription?
    let initialValidation: ValueValidation
    let footerView: AuthenticationFooterViewDescription?
}
