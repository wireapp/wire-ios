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

private typealias HandleChange = L10n.Localizable.Self.Settings.AccountSection.Handle.Change
private typealias Username = L10n.Localizable.Registration.Signin.Username

final class AddUsernameStepDescription: DefaultValidatingStepDescription {
    let backButton: BackButtonDescription?
    var mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: NSAttributedString?
    let secondaryView: AuthenticationSecondaryViewDescription? = nil
    let initialValidation: ValueValidation
    let footerView: AuthenticationFooterViewDescription? = nil

    init() {
        let textField = TextFieldDescription(
            placeholder: Username.placeholder,
            actionDescription: L10n.Localizable.General.confirm,
            kind: .username
        )
        textField.acceptInvalidInput = false

        self.mainView = textField
        self.backButton = BackButtonDescription()
        self.headline = Username.title
        self.subtext = .markdown(from: Username.message, style: .login)
        self.initialValidation = .info(HandleChange.footer)
    }
}
