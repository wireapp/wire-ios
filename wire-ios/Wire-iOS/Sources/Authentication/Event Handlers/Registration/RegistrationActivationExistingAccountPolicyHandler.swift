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
import WireDataModel

private typealias AlertStrings = L10n.Localizable.Registration.Alert

/// Handles the case that the user tries to register an account with a phone/e-mail that is already registered.

final class RegistrationActivationExistingAccountPolicyHandler: AuthenticationEventHandler {
    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: NSError) -> [AuthenticationCoordinatorAction]? {
        let error = context

        // Only handle phoneNumberIsAlreadyRegistered and emailIsAlreadyRegistered errors
        switch error.userSessionErrorCode {
        case .emailIsAlreadyRegistered:
            break
        default:
            return nil
        }

        // Only handle errors during activation requests
        let unverifiedEmail: String
        switch currentStep {
        case let .sendActivationCode(email, _, _):
            unverifiedEmail = email
        default:
            return nil
        }

        var actions: [AuthenticationCoordinatorAction] = [.hideLoadingView]
        let alert = AuthenticationCoordinatorAlert(
            title: AlertStrings.AccountExists.title,
            message: AlertStrings.AccountExists.messageEmail,
            actions: [.changeEmail, .login(email: unverifiedEmail)]
        )
        actions.append(.presentAlert(alert))

        return actions
    }
}

extension AuthenticationCoordinatorAlertAction {
    fileprivate static var changeEmail: Self {
        Self(
            title: AlertStrings.changeEmailAction,
            coordinatorActions: [.unwindState(withInterface: false), .executeFeedbackAction(.clearInputFields)]
        )
    }

    fileprivate static func login(email: String) -> Self {
        let credentials = LoginCredentials(
            emailAddress: email,
            hasPassword: true,
            usesCompanyLogin: false
        )
        let prefilledCredentials = AuthenticationPrefilledCredentials(
            credentials: credentials,
            isExpired: false
        )
        return Self(
            title: AlertStrings.changeSigninAction,
            coordinatorActions: [.transition(.provideCredentials(prefilledCredentials), mode: .replace)]
        )
    }
}
