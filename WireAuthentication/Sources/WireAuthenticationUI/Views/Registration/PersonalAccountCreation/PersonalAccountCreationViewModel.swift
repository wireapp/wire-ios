//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import SwiftUI
import WireAuthenticationAPI
import WireLogging
import WireNetwork
import WireReusableUIComponents

@MainActor
package final class PersonalAccountCreationViewModel: ObservableObject {

    package typealias Factory =
        PersonalAccountCreationFactory &
        RegisterPersonalAccountUseCaseFactory &
        RequestEmailVerificationCodeUseCaseFactory &
        ValidateEmailUseCaseFactory

    @Published var alert: Alert?
    @Published var isCreateTeamAccountPresented = false
    @Published var isDataUsageAgreementAccepted = false
    @Published var name: String = ""
    @Published var email: String
    @Published var password: String = ""
    @Published var confirmedPassword: String = ""

    var trackingConsent: RegistrationAnalyticsTrackingConsent {
        if let trackingID = analyticsEventTracker?.trackingID.flatMap(UUID.init(uuidString:)) {
            .agreed(trackingID: trackingID)
        } else {
            .declined
        }
    }

    // MARK: - Dependencies

    var localizedPasswordRules: String {
        passwordValidator.localizedRulesDescription ?? ""
    }

    var isAnalyticsTrackingAvailable: Bool {
        // `analyticsEventTracker` will be nil if the app is not shipped with Countly credentials.
        // If credentials are available, we only want to enable Countly for prod and staging backends.
        analyticsEventTracker?.isAnalyticsTrackingAvailable(for: environment) ?? false
    }

    package let factory: any Factory
    private let router: any Router
    package let environment: BackendEnvironment2
    package let privacyPolicyURL: URL
    private let termsOfUseURL: URL
    package let teamAccountCreationLink: URL?
    private let passwordValidator: any PasswordValidator
    private let analyticsEventTracker: (any RegistrationAnalyticsTrackerProtocol)?

    package init(
        factory: any Factory,
        router: any Router,
        email: String,
        environment: BackendEnvironment2,
        privacyPolicyURL: URL,
        termsOfUseURL: URL,
        teamAccountCreationLink: URL?,
        passwordValidator: any PasswordValidator,
        analyticsEventTracker: (any RegistrationAnalyticsTrackerProtocol)?
    ) {
        self.factory = factory
        self.router = router
        self.email = email
        self.environment = environment
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfUseURL = termsOfUseURL
        self.teamAccountCreationLink = teamAccountCreationLink
        self.passwordValidator = passwordValidator
        self.analyticsEventTracker = analyticsEventTracker
    }

    // MARK: - Validations

    var isEmailValid: Bool {
        factory.validateEmailUseCase().invoke(email: email) == .isValid
    }

    var isNameValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > 2 && trimmed.count < 64
    }

    var isPasswordValid: Bool {
        passwordValidator.isPasswordValid(password)
    }

    var isPasswordMatchConfirmedPassword: Bool {
        password == confirmedPassword
    }

    var canRequestVerificationCode: Bool {
        isNameValid && isEmailValid && isPasswordValid && isPasswordMatchConfirmedPassword
    }

    func requestEmailVerificationCode() async throws {
        guard canRequestVerificationCode else {
            return
        }
        do {
            let requestEmailVerificationCodeUseCase = try await factory.requestEmailVerificationCodeUseCase()
            try await requestEmailVerificationCodeUseCase.invoke(email: email)

            if isDataUsageAgreementAccepted {
                analyticsEventTracker?.setUp()
                analyticsEventTracker?.trackPersonalAccountCreationStart()
                analyticsEventTracker?.trackPersonalAccountCreationReachedTermsOfUseConfirmation()
            } else {
                analyticsEventTracker?.tearDown()
            }

            router.navigate(to: PersonalAccountCreationDestination.verifyEmail(
                email: email,
                password: password,
                name: name
            ))
        } catch {
            WireLogger.authentication.error("request email verification code failed: \(error)")

            switch error {
            case RequestEmailVerificationCodeUseCaseFailure.invalidEmail:
                alert = .invalidEmailForRegistration
            case RequestEmailVerificationCodeUseCaseFailure.blacklistedEmail:
                alert = .blacklistedEmail
            case RequestEmailVerificationCodeUseCaseFailure.emailExists:
                alert = .emailExists
            case RequestEmailVerificationCodeUseCaseFailure.domainBlockedForRegistration:
                alert = .domainBlockedForRegistration
            default:
                router.presentAlert(for: error)
            }
        }
    }

    func showTermsOfUse() {
        UIApplication.shared.open(
            termsOfUseURL
        )
    }

}

extension Alert {

    private typealias Title = L10n.Localizable.CreatePersonalAccount.Error.Title
    private typealias Message = L10n.Localizable.CreatePersonalAccount.Error.Message

    static let invalidEmailForRegistration = Alert(
        title: Title.invalidEmail,
        message: Message.invalidEmail
    )

    static let blacklistedEmail = Alert(
        title: Title.blacklistedEmail,
        message: Message.blacklistedEmail
    )

    static let emailExists = Alert(
        title: Title.emailExists,
        message: Message.emailExists
    )

    static let domainBlockedForRegistration = Alert(
        title: Title.domainBlocked,
        message: Message.domainBlocked
    )

    static let tooManyTeamMembers = Alert(
        title: Title.tooManyTeamMembers,
        message: Message.tooManyTeamMembers
    )

    static let userCreationRestricted = Alert(
        title: Title.userCreationRestricted,
        message: Message.userCreationRestricted
    )

    static let invalidCode = Alert(
        title: Title.invalidCode,
        message: Message.invalidCode
    )

}
