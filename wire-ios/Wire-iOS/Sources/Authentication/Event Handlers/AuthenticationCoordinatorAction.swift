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
import WireSyncEngine

// MARK: - AuthenticationCoordinatorAction

/// Valid response actions for authentication events.
enum AuthenticationCoordinatorAction {
    case showLoadingView
    case hideLoadingView
    case unwindState(withInterface: Bool)
    case executeFeedbackAction(AuthenticationErrorFeedbackAction)
    case presentAlert(AuthenticationCoordinatorAlert)
    case presentErrorAlert(AuthenticationCoordinatorErrorAlert)
    case completeBackupStep
    case completeLoginFlow
    case startPostLoginFlow
    case transition(AuthenticationFlowStep, mode: AuthenticationStateController.StateChangeMode)
    case requestEmailVerificationCode(email: String, password: String)
    case configureNotifications
    case startIncrementalUserCreation(UnregisteredUser)
    case setMarketingConsent(Bool)
    case completeUserRegistration
    case openURL(URL)
    case repeatAction
    case displayInlineError(NSError)
    case continueFlowWithLoginCode(String)
    case startRegistrationFlow(unverifiedEmail: String)
    case startLoginFlow(AuthenticationLoginRequest, AuthenticationProxyCredentialsInput?)
    case setFullName(String)
    case setUsername(String)
    case setUserPassword(String)
    case updateBackendEnvironment(url: URL)
    case startCompanyLogin(code: UUID?)
    case startSSOFlow
    case startBackupFlow
    case signOut(warn: Bool)
    case addEmailAndPassword(UserEmailCredentials)
    case configureDevicePermissions
    case startE2EIEnrollment
    case completeE2EIEnrollment

    var retainsModal: Bool {
        switch self {
        case .openURL:
            true
        default:
            false
        }
    }
}

// MARK: - AuthenticationCoordinatorAlert

/// A customizable alert to display inside the coordinator's presenter.
struct AuthenticationCoordinatorAlert {
    let title: String?
    let message: String?
    let actions: [AuthenticationCoordinatorAlertAction]
}

// MARK: - AuthenticationCoordinatorAlertAction

/// An action that is part of an authentication coordinator alert.
struct AuthenticationCoordinatorAlertAction {
    let title: String
    let coordinatorActions: [AuthenticationCoordinatorAction]
    let style: UIAlertAction.Style

    init(title: String, coordinatorActions: [AuthenticationCoordinatorAction], style: UIAlertAction.Style = .default) {
        self.title = title
        self.coordinatorActions = coordinatorActions
        self.style = style
    }
}

extension AuthenticationCoordinatorAlertAction {
    static let ok = AuthenticationCoordinatorAlertAction(title: L10n.Localizable.General.ok, coordinatorActions: [])
    static let cancel = AuthenticationCoordinatorAlertAction(
        title: L10n.Localizable.General.cancel,
        coordinatorActions: [],
        style: .cancel
    )
}

// MARK: - AuthenticationCoordinatorErrorAlert

/// A customizable alert to display inside the coordinator's presenter.
struct AuthenticationCoordinatorErrorAlert {
    let error: NSError
    let completionActions: [AuthenticationCoordinatorAction]
}

// MARK: - AuthenticationLoginRequest

enum AuthenticationLoginRequest {
    case email(address: String, password: String)
}

// MARK: - AuthenticationProxyCredentialsInput

struct AuthenticationProxyCredentialsInput {
    var username: String
    var password: String
}

extension AuthenticationCoordinatorAction {
    static var presentCustomBackendAlert: Self {
        typealias Alert = L10n.Localizable.Landing.CustomBackend.Alert

        let env = BackendEnvironment.shared
        let info = [
            Alert.Message.backendName,
            env.title,
            Alert.Message.backendUrl,
            env.backendURL.absoluteString,
        ].joined(separator: "\n")

        return .presentAlert(
            .init(
                title: Alert.title,
                message: info,
                actions: [.ok]
            )
        )
    }
}
