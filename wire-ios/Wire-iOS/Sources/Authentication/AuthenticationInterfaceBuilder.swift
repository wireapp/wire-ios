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
import WireDataModel

/// A type of view controller that can be managed by an authentication coordinator.

typealias AuthenticationStepViewController = AuthenticationCoordinatedViewController & UIViewController

// MARK: - AuthenticationInterfaceBuilder

/// An object that builds view controllers for authentication steps.

final class AuthenticationInterfaceBuilder {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Creates an interface builder with the specified set of features.
    /// - parameter featureProvider: The object to use when checking for features

    init(
        featureProvider: AuthenticationFeatureProvider,
        backendEnvironmentProvider: @escaping () -> BackendEnvironmentProvider = { BackendEnvironment.shared }
    ) {
        self.featureProvider = featureProvider
        self.backendEnvironmentProvider = backendEnvironmentProvider
    }

    // MARK: Internal

    /// The object to use when checking for features.
    let featureProvider: AuthenticationFeatureProvider

    var backendEnvironmentProvider: () -> BackendEnvironmentProvider

    var backendEnvironment: BackendEnvironmentProvider {
        backendEnvironmentProvider()
    }

    // MARK: - Interface Building

    /// Returns the view controller that displays the interface of the authentication step.
    ///
    /// - note: When new steps are added to the `AuthenticationFlowStep` enum, you need to
    /// add a case to handle them here, otherwise the method will return `nil`.
    ///
    /// - parameter step: The step to create an interface for.
    /// - returns: The view controller to use for this step, or `nil` if the interface builder
    /// does not support this step.

    func makeViewController(for step: AuthenticationFlowStep) -> AuthenticationStepViewController? {
        switch step {
        case .landingScreen:
            let landingViewController = LandingViewController(backendEnvironmentProvider: backendEnvironmentProvider)
            landingViewController.configure(with: featureProvider)
            return landingViewController

        case let .reauthenticate(credentials, _, isSignedOut):
            let viewController: AuthenticationStepController

            if credentials?.usesCompanyLogin == true, credentials?.hasPassword == false {
                // Is the user has SSO enabled, show the screen to log in with SSO
                let companyLoginStep = ReauthenticateWithCompanyLoginStepDescription()
                viewController = makeViewController(for: companyLoginStep)

            } else {
                let prefill: AuthenticationPrefilledCredentials? = if let credentials, credentials.emailAddress != nil {
                    AuthenticationPrefilledCredentials(credentials: credentials, isExpired: isSignedOut)
                } else {
                    nil
                }

                viewController = makeCredentialsViewController(for: .reauthentication(prefill))
            }

            // Add the bar button item to sign out
            viewController.setRightItem(
                L10n.Localizable.Registration.Signin.TooManyDevices.SignOutButton.title,
                withAction: .signOut(warn: true),
                accessibilityID: "signOutButton"
            )
            return viewController

        case let .provideCredentials(prefill):
            return makeCredentialsViewController(for: .login(prefill))

        case .createCredentials:
            return makeCredentialsViewController(for: .registration)

        case .clientManagement:
            let manageClientsInvitation = ClientUnregisterInvitationStepDescription()
            let viewController = makeViewController(for: manageClientsInvitation)
            viewController.setRightItem(
                L10n.Localizable.Registration.Signin.TooManyDevices.SignOutButton.title,
                withAction: .signOut(warn: true),
                accessibilityID: "signOutButton"
            )
            return viewController

        case let .deleteClient(clients):
            return RemoveClientStepViewController(clients: clients)

        case let .noHistory(_, context):
            let backupStep = BackupRestoreStepDescription(context: context)
            return makeViewController(for: backupStep)

        case let .enterEmailVerificationCode(email, _, _):
            let verifyEmailStep = VerifyEmailStepDescription(email: email, canChangeEmail: false)
            return makeViewController(for: verifyEmailStep)

        case .addEmailAndPassword:
            let addCredentialsStep = AddEmailPasswordStepDescription()
            let viewController = makeViewController(for: addCredentialsStep)
            viewController.setRightItem(
                L10n.Localizable.Registration.Signin.TooManyDevices.SignOutButton.title,
                withAction: .signOut(warn: true),
                accessibilityID: "signOutButton"
            )
            return viewController

        case .addUsername:
            let addUsernameStep = AddUsernameStepDescription()
            let viewController = makeViewController(for: addUsernameStep)
            return viewController

        case let .enterActivationCode(unverifiedEmail, _):
            let step = VerifyEmailStepDescription(email: unverifiedEmail)
            return makeViewController(for: step)

        case let .pendingEmailLinkVerification(emailCredentials):
            let verifyEmailStep = EmailLinkVerificationStepDescription(emailAddress: emailCredentials.email!)

            let viewController = makeViewController(for: verifyEmailStep)
            viewController.setRightItem(
                L10n.Localizable.Registration.Signin.TooManyDevices.SignOutButton.title,
                withAction: .signOut(warn: true),
                accessibilityID: "signOutButton"
            )
            return viewController

        case let .incrementalUserCreation(user, registrationStep):
            return makeRegistrationStepViewController(for: registrationStep, user: user)

        case let .switchBackend(url):
            let viewController = PreBackendSwitchViewController()
            viewController.backendURL = url
            return viewController

        case .enrollE2EIdentity:
            let viewController = EnrollE2EIdentityStepDescription()
            return makeViewController(for: viewController)

        case let .enrollE2EIdentitySuccess(certificateDetails):
            let viewController = SuccessfulCertificateEnrollmentViewController()
            viewController.certificateDetails = certificateDetails
            viewController.onOkTapped = { viewController in
                viewController.authenticationCoordinator?.executeAction(.completeE2EIEnrollment)
            }
            return viewController

        default:
            return nil
        }
    }

    // MARK: Private

    /// Returns the view controller that displays the interface for the given intermediate
    /// registration step.
    ///
    /// - parameter step: The step to create an interface for.
    /// - parameter user: The unregistered user that is being created.
    /// - returns: The view controller to use for this step, or `nil` if the interface builder
    /// does not support this step.

    private func makeRegistrationStepViewController(
        for step: IntermediateRegistrationStep,
        user: UnregisteredUser
    ) -> AuthenticationStepViewController? {
        switch step {
        case .setName:
            let nameStep = SetFullNameStepDescription()
            return makeViewController(for: nameStep)

        case .setPassword:
            let passwordStep = SetPasswordStepDescription()
            return makeViewController(for: passwordStep)

        default:
            return nil
        }
    }

    /// Creates a view controller for a step view description.
    ///
    /// - parameter description: The step to create an interface for.
    /// - returns: The view controller to use for this step, or `nil` if the interface builder
    /// does not support this step.

    private func makeViewController(for description: AuthenticationStepDescription) -> AuthenticationStepController {
        let controller = AuthenticationStepController(description: description)

        let mainView = description.mainView

        mainView.valueSubmitted = { [weak controller] value in
            controller?.valueSubmitted(value)
        }

        mainView.valueValidated = { [weak controller] validation in
            controller?.valueValidated(validation)
        }

        return controller
    }

    /// Creates and configures an authentication credentials view controller for the specified flow type.
    /// - parameter flowType: The type of flow to use in the view controller.
    /// - returns: A credentials input view controller configured with the feature provider.

    private func makeCredentialsViewController(
        for flowType: AuthenticationCredentialsViewController
            .FlowType
    ) -> AuthenticationCredentialsViewController {
        .init(flowType: flowType, backendEnvironmentProvider: backendEnvironmentProvider)
    }
}
