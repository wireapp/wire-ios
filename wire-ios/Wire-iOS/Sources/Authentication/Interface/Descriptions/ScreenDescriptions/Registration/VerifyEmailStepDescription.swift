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

// MARK: - VerifyEmailStepSecondaryView

final class VerifyEmailStepSecondaryView: AuthenticationFooterViewDescription {
    // MARK: Lifecycle

    init(canResend: Bool = true, canChangeEmail: Bool = true) {
        let resendCode = SecondaryButtonDescription(
            title: TeamActivationCode.resend.capitalized,
            accessibilityIdentifier: "resend_button"
        )
        let changeEmail = SecondaryButtonDescription(
            title: TeamActivationCode.changeEmail.capitalized,
            accessibilityIdentifier: "change_email_button"
        )
        var views: [SecondaryButtonDescription] = []

        if canResend {
            views.append(resendCode)
        }

        if canChangeEmail {
            views.append(changeEmail)
        }

        self.views = views

        changeEmail.buttonTapped = { [weak self] in
            self?.actioner?.executeAction(.unwindState(withInterface: true))
        }

        resendCode.buttonTapped = { [weak self] in
            self?.actioner?.repeatAction()
        }
    }

    // MARK: Internal

    typealias TeamActivationCode = L10n.Localizable.Team.ActivationCode.Button

    let views: [ViewDescriptor]
    weak var actioner: AuthenticationActioner?
}

// MARK: - VerifyEmailStepDescription

final class VerifyEmailStepDescription: AuthenticationStepDescription {
    // MARK: Lifecycle

    init(email: String, canChangeEmail: Bool = true) {
        self.email = email
        self.backButton = nil
        self.mainView = VerificationCodeFieldDescription()
        self.headline = L10n.Localizable.Team.ActivationCode.headline
        self.subtext = .markdown(from: L10n.Localizable.Team.ActivationCode.subheadline(email), style: .login)
        self.secondaryView = nil
        self.footerView = VerifyEmailStepSecondaryView(canChangeEmail: canChangeEmail)
    }

    // MARK: Internal

    let email: String
    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: NSAttributedString?
    let secondaryView: AuthenticationSecondaryViewDescription?
    let footerView: AuthenticationFooterViewDescription?
}
