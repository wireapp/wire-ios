//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import Combine
import SwiftUI
import UIKit
import WireAuthentication
import WireAuthenticationAPI
import WireCommonComponents
import WireCountly
import WireDataModel
import WireFoundation
import WireNetwork
import WireSyncEngine

/// A type of view controller that can be managed by an authentication coordinator.

typealias AuthenticationStepViewController = AuthenticationCoordinatedViewController & UIViewController

/// An object that builds view controllers for authentication steps.

final class AuthenticationInterfaceBuilder {

    /// The object to use when checking for features.
    let featureProvider: AuthenticationFeatureProvider

    var backendEnvironmentProvider: () -> BackendEnvironmentProvider

    var backendEnvironment: BackendEnvironmentProvider {
        backendEnvironmentProvider()
    }

    let defaultEnvironment: BackendEnvironment2

    private var accountSelector: AccountSelector?

    // MARK: - Initialization

    /// Creates an interface builder with the specified set of features.
    /// - parameter featureProvider: The object to use when checking for features

    init(
        featureProvider: AuthenticationFeatureProvider,
        accountSelector: AccountSelector?,
        backendEnvironmentProvider: @escaping () -> BackendEnvironmentProvider = { BackendEnvironment.shared },
        defaultEnvironment: BackendEnvironment2
    ) {
        self.featureProvider = featureProvider
        self.backendEnvironmentProvider = backendEnvironmentProvider
        self.accountSelector = accountSelector
        self.defaultEnvironment = defaultEnvironment
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

    @MainActor
    func makeViewController(
        for step: AuthenticationFlowStep,
        authenticationCoordinator: AuthenticationCoordinator?
    ) -> AuthenticationStepViewController? {
        switch step {
        case .wireAuthenticationModule:
            let environment: BackendEnvironment2 = defaultEnvironment

            let analyticsServiceConfiguration = AnalyticsServiceConfigurationBuilder.build()
            let registrationAnalyticsTracker = analyticsServiceConfiguration.map { analyticsServiceConfiguration in
                RegistrationAnalyticsTracker(
                    analyticsServiceConfiguration: analyticsServiceConfiguration,
                    availabilityChecker: .default,
                    countlyProvider: { CountlyWrapper() },
                    userDefaults: .standard
                )
            }

            let (rootView, bridge) = wireAuthenticationAssembly(
                authenticationType: .new,
                environment: environment,
                registrationAnalyticsTracker: registrationAnalyticsTracker
            )

            authenticationCoordinator?.analyticsEventTracker = registrationAnalyticsTracker
            return AuthenticationHostingController(
                rootView: rootView,
                bridge: bridge,
                authenticationCoordinator: authenticationCoordinator
            )

        case .landingScreen:
            let landingViewController = LandingViewController(backendEnvironmentProvider: backendEnvironmentProvider)
            landingViewController.configure(with: featureProvider)
            return landingViewController

        case let .reauthenticate(credentials, environment, _, _):
            let analyticsServiceConfiguration = AnalyticsServiceConfigurationBuilder.build()
            let registrationAnalyticsTracker = analyticsServiceConfiguration.map { analyticsServiceConfiguration in
                RegistrationAnalyticsTracker(
                    analyticsServiceConfiguration: analyticsServiceConfiguration,
                    availabilityChecker: .default,
                    countlyProvider: { CountlyWrapper() },
                    userDefaults: .standard
                )
            }

            let authenticationType: WireAuthenticationAPI.AuthenticationType
            if credentials?.usesCompanyLogin == true, credentials?.hasPassword == false {
                authenticationType = .reauthSSO
            } else if let email = credentials?.emailAddress {
                authenticationType = .reauthEmail(email)
            } else {
                assertionFailure("invalid state: reauthentication without email credentials")
                authenticationType = .new
            }

            // If there's no environment, then it probably means that the user
            // hasn't yet migrated to multibackend support yet. Fallback to the
            // legacy environment to allow them to reauthenticate.
            let (rootView, bridge) = wireAuthenticationAssembly(
                authenticationType: authenticationType,
                environment: environment ?? BackendEnvironment2(BackendEnvironment.shared),
                registrationAnalyticsTracker: registrationAnalyticsTracker
            )

            authenticationCoordinator?.analyticsEventTracker = registrationAnalyticsTracker
            return AuthenticationHostingController(
                rootView: rootView,
                bridge: bridge,
                authenticationCoordinator: authenticationCoordinator
            )

        case let .provideCredentials(prefill):
            return makeCredentialsViewController(for: .login(prefill))

        case let .createCredentials(user):
            let prefilledCredentials = AuthenticationPrefilledCredentials(
                credentials: LoginCredentials(
                    emailAddress: user.unverifiedEmail,
                    hasPassword: false,
                    usesCompanyLogin: false
                ),
                isExpired: false
            )
            return makeCredentialsViewController(for: .registration(prefilledCredentials))

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
            let backupStep = NoHistoryHintStepDescription(context: context)
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
            return makeViewController(for: addUsernameStep)

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

    @MainActor
    private func wireAuthenticationAssembly(
        authenticationType: WireAuthenticationAPI.AuthenticationType,
        environment: BackendEnvironment2,
        registrationAnalyticsTracker: RegistrationAnalyticsTracker?
    ) -> (view: some View, bridge: WireAuthenticationBridge) {
        let assembly = WireAuthenticationAssembly()
        let accounts = (SessionManager.shared?.accountManager.accounts ?? [])
            .map { account in
                account.toUIModel { [weak self] in
                    self?.accountSelector?.switchTo(account: account)
                }
            }
        let preferredAPIVersion = BackendInfo.preferredAPIVersion.flatMap {
            WireNetwork.APIVersion(rawValue: UInt($0.rawValue))
        }

        return assembly.assemble(
            authenticationType: authenticationType,
            environment: environment,
            minTLSVersion: TLSVersion.minVersionFrom(SecurityFlags.minTLSVersion.stringValue),
            preferredAPIVersion: Bundle.developerModeEnabled ? preferredAPIVersion : nil,
            howToChangeEmailURL: WireURLs.shared.howToChangeEmail,
            howToDeleteAccountURL: WireURLs.shared.howToDeleteAccount,
            privacyPolicyURL: WireURLs.shared.privacyPolicy,
            termsOfUseURL: WireURLs.shared.legal,
            passwordValidator: AuthenticationPasswordValidator(),
            ssoCallbackURLScheme: Bundle.ssoURLScheme ?? "wire-sso",
            appStoreURL: WireURLs.shared.appOnItunes,
            accountsPublisher: CurrentValuePublisher(subject: CurrentValueSubject(accounts)),
            registrationAnalyticsTracker: registrationAnalyticsTracker
        )
    }
}
