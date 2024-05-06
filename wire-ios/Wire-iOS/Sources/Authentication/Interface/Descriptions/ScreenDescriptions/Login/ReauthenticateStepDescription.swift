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

/**
 * An authentication step to ask the user to log in again.
 */

final class ReauthenticateStepDescription: AuthenticationStepDescription {

    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: NSAttributedString?
    let secondaryView: AuthenticationSecondaryViewDescription?
    let footerView: AuthenticationFooterViewDescription?

    init(prefilledCredentials: AuthenticationPrefilledCredentials?) {
        backButton = BackButtonDescription()
        mainView = EmptyViewDescription()
        headline = L10n.Localizable.Registration.Signin.title

        switch prefilledCredentials?.primaryCredentialsType {
        case .email?:
            if prefilledCredentials?.isExpired == true {
                subtext = .markdown(from: L10n.Localizable.SigninLogout.Email.subheadline, style: .login)
            } else {
                subtext = .markdown(from: L10n.Localizable.Signin.Email.MissingPassword.subtitle, style: .login)
            }
        case .phone?:
            if prefilledCredentials?.isExpired == true {
                subtext = .markdown(from: L10n.Localizable.SigninLogout.Phone.subheadline, style: .login)
            } else {
                subtext = .markdown(from: L10n.Localizable.Signin.Phone.MissingPassword.subtitle, style: .login)
            }
        case .none:
            subtext = .markdown(from: L10n.Localizable.SigninLogout.subheadline, style: .login)
        }

        secondaryView = nil
        footerView = nil
    }

}
