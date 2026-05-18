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

import Foundation
import UIKit
import WireAuthenticationAPI
import WireLogging
import WireNetwork
import WireReusableUIComponents

@MainActor
package final class LoginViaEmailViewModel: ObservableObject {

    package typealias Factory =
        CreateAuthenticationResultUseCaseFactory &
        LoginViaEmailFactory &
        LoginViaEmailUseCaseFactory &
        SubmitProxyCredentialsUseCaseFactory &
        ValidateEmailUseCaseFactory

    // MARK: - View state

    @Published var email: String {
        didSet {
            guard !isApplyingSharedState, oldValue != email else { return }
            sharedAuthLoginFlow?.send(.identifierChanged(email))
        }
    }

    @Published var password: String = "" {
        didSet {
            guard !isApplyingSharedState, oldValue != password else { return }
            sharedAuthLoginFlow?.send(.passwordChanged(password))
        }
    }

    @Published var proxyUsername: String = ""
    @Published var proxyPassword: String = ""

    @Published private(set) var isLoading = false
    @Published var alert: Alert?
    @Published var modalDestination: LoginViaEmailSheet?
    @Published var onSheetDismissAction: (() -> Void)?

    let environment: BackendEnvironment2
    let isEmailPrefilled: Bool
    let canCreateAccount: Bool

    var areProxyCredentialsRequired: Bool {
        environment.config.proxyConfig?.needsAuthentication == true
    }

    var proxyServer: String? {
        environment.config.proxyConfig?.host
    }

    func isPasswordValid(_ password: String) -> Bool {
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isOnPremiseBackend: Bool {
        environment.environmentType != .default
    }

    var canSubmitCredentials: Bool {
        if let sharedAuthLoginFlow {
            return sharedAuthLoginFlow.currentState.canSubmitCredentials
        }

        return if areProxyCredentialsRequired {
            areAccountCredentialsValid && areProxyCredentialsValid
        } else {
            areAccountCredentialsValid
        }
    }

    lazy var teamAccountCreationLink: URL? = {
        let teamsURL = environment.config.endpoints.teamsURL
        guard var components = URLComponents(url: teamsURL, resolvingAgainstBaseURL: false) else {
            WireLogger.authentication
                .warn("Unable to generate team account creation link. Invalid teamsURL: \(teamsURL.absoluteString)")
            return nil
        }

        let appendedPath = components.path.appending("/signup/account")
        components.path = appendedPath

        components.queryItems = (components.queryItems ?? []) + [
            URLQueryItem(name: "origin", value: "ios")
        ]

        return components.url
    }()

    // MARK: - Dependencies

    package let factory: any Factory
    private let router: any Router
    private let sharedAuthLoginFlow: (any SharedAuthLoginFlowManaging)?
    private let didDetectDomainConflict: Bool
    private var sharedStateObservation: (any SharedAuthLoginFlowObservation)?
    private var sharedEffectObservation: (any SharedAuthLoginFlowObservation)?
    private var lastSharedStep: SharedAuthLoginFlowStep?
    private var isApplyingSharedState = false

    // MARK: - Life cycle

    package init(
        factory: any Factory,
        router: any Router,
        sharedAuthLoginFlow: (any SharedAuthLoginFlowManaging)?,
        email: String?,
        environment: BackendEnvironment2,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool
    ) {
        self.factory = factory
        self.router = router
        self.sharedAuthLoginFlow = sharedAuthLoginFlow
        self.email = email ?? ""
        self.environment = environment
        self.canCreateAccount = canCreateAccount
        self.didDetectDomainConflict = didDetectDomainConflict
        self.isEmailPrefilled = email != nil
        observeSharedAuthLoginFlow()
    }

    deinit {
        sharedStateObservation?.cancel()
        sharedEffectObservation?.cancel()
    }

    // MARK: - Actions

    func submitCredentials() async {
        if let sharedAuthLoginFlow {
            sharedAuthLoginFlow.send(.identifierChanged(email))
            sharedAuthLoginFlow.send(.passwordChanged(password))
            sharedAuthLoginFlow.send(.submitCredentials(usernameAllowed: true))
            return
        }

        isLoading = true

        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let proxyCredentials {
                try await submitProxyCredentials(proxyCredentials)
            }

            let (cookies, accessToken) = try await logIn(
                email: sanitizedEmail,
                password: sanitizedPassword
            )

            WireLogger.authentication.info("Login via email succeeded")

            let emailCredentials = EmailCredentials(
                email: sanitizedEmail,
                password: sanitizedPassword,
                verificationCode: nil
            )

            let authenticationResult = try await createAuthenticationResult(
                cookies: cookies,
                accessToken: accessToken,
                emailCredentials: emailCredentials
            )

            router.navigate(
                to: LoginViaEmailDestination.noHistory(authenticationResult: authenticationResult)
            )

        } catch {
            WireLogger.authentication.error("Login via email failed: \(error)")

            switch error {
            case LoginViaEmailUseCaseFailure.invalidCredentials:
                alert = .invalidCredentials
            case LoginViaEmailUseCaseFailure.twoFactorAuthenticationRequired:
                router.navigate(
                    to: LoginViaEmailDestination
                        .verifyLogin(
                            email: sanitizedEmail,
                            password: sanitizedPassword,
                            proxyCredentials: proxyCredentials
                        )
                )
            case LoginViaEmailUseCaseFailure.accountPendingActivation:
                alert = .accountPendingActivation
            case LoginViaEmailUseCaseFailure.accountSuspended:
                alert = .accountSuspended
            default:
                router.presentAlert(for: error)
            }
        }

        isLoading = false
    }

    func recoverPassword() {
        UIApplication.shared.open(
            environment.config.endpoints.accountsURL.appendingPathComponent("forgot")
        )
    }

    func createAccount() {
        router.navigate(
            to: LoginViaEmailDestination.createPersonalAccount
        )
    }

    func handleTeamAccountCreation() {
        onSheetDismissAction = { [weak self] in
            guard let self else { return }
            onSheetDismissAction = nil

            if let teamAccountCreationLink {
                modalDestination = .teamAccountCreation(url: teamAccountCreationLink)
            }
        }
    }

    func handlePersonalAccountCreation() {
        onSheetDismissAction = { [weak self] in
            guard let self else { return }
            onSheetDismissAction = nil

            router.navigate(
                to: LoginViaEmailDestination.createPersonalAccount
            )
        }
    }

    // MARK: - Private

    private func observeSharedAuthLoginFlow() {
        guard let sharedAuthLoginFlow else { return }

        applySharedState(sharedAuthLoginFlow.currentState)

        sharedStateObservation = sharedAuthLoginFlow.observeState { [weak self] state in
            self?.applySharedState(state)
        }

        sharedEffectObservation = sharedAuthLoginFlow.observeEffect { [weak self] effect in
            switch effect {
            case let .loginSucceeded(payload):
                Task {
                    await self?.completeSharedLogin(payload: payload)
                }
            case .openSsoURL:
                break
            }
        }
    }

    private func applySharedState(_ state: SharedAuthLoginFlowState) {
        isApplyingSharedState = true
        email = state.identifier
        password = state.password
        isApplyingSharedState = false
        isLoading = state.isLoading

        switch state.error {
        case .invalidCredentials:
            alert = .invalidCredentials
        case .invalidSecondFactorCode:
            alert = .invalid2FACode
        case .tooManyDevices, .generic:
            alert = .unknownError
        case .invalidIdentifier, nil:
            break
        }

        guard state.step != lastSharedStep else { return }
        lastSharedStep = state.step

        switch state.step {
        case .identifierEntry, .emailCredentialsEntry:
            break
        case .secondFactorEntry:
            router.navigate(
                to: LoginViaEmailDestination.verifyLogin(
                    email: state.identifier,
                    password: state.password,
                    proxyCredentials: proxyCredentials
                )
            )
        case .success:
            break
        }
    }

    private func completeSharedLogin(payload: SharedAuthLoginSuccessPayload) async {
        do {
            WireLogger.authentication.info(
                "Shared Kalium auth login succeeded, handing off to legacy auth",
                attributes: .safePublic
            )

            let userID = try payload.makeUserID()
            let cookies = try payload.makeCookies(
                fallbackDomain: environment.config.endpoints.restAPIURL.host ?? "wire.com"
            )
            let accessToken = payload.makeAccessToken(userID: userID)
            let emailCredentials = payload.makeEmailCredentials(
                fallbackEmail: email,
                fallbackPassword: password
            )

            let authenticationResult = try await createAuthenticationResult(
                cookies: cookies,
                accessToken: accessToken,
                emailCredentials: emailCredentials
            )

            router.navigate(
                to: LoginViaEmailDestination.noHistory(authenticationResult: authenticationResult)
            )
        } catch {
            WireLogger.authentication.error("Shared auth login handoff failed: \(error)")
            alert = .unknownError
        }
    }

    private var proxyCredentials: ProxyCredentials? {
        guard areProxyCredentialsRequired else {
            return nil
        }

        return ProxyCredentials(
            username: proxyUsername.trimmingCharacters(in: .whitespacesAndNewlines),
            password: proxyPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private var areAccountCredentialsValid: Bool {
        let isEmailValid = factory.validateEmailUseCase().invoke(email: email) == .isValid
        let isPasswordValid = isPasswordValid(password)
        return isEmailValid && isPasswordValid
    }

    private var areProxyCredentialsValid: Bool {
        let isUsernameValid = !proxyUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isPasswordValid = isPasswordValid(proxyPassword)
        return isUsernameValid && isPasswordValid
    }

    private func submitProxyCredentials(_ proxyCredentials: ProxyCredentials) async throws {
        let useCase = factory.submitProxyCredentialsUseCase()
        try await useCase.invoke(proxyCredentials: proxyCredentials)
    }

    private func logIn(
        email: String,
        password: String
    ) async throws -> ([HTTPCookie], AccessToken) {
        let useCase = try await factory.loginViaEmailUseCase()
        return try await Task.detached {
            try await useCase.invoke(
                email: email,
                password: password,
                verificationCode: nil
            )
        }.value
    }

    private func createAuthenticationResult(
        cookies: [HTTPCookie],
        accessToken: AccessToken,
        emailCredentials: EmailCredentials?
    ) async throws -> AuthenticationResult {
        let useCase = factory.createAuthenticationResultUseCase()
        return try await Task.detached {
            try await useCase.invoke(
                userID: accessToken.userID,
                cookies: cookies,
                accessToken: accessToken,
                emailCredentials: emailCredentials
            )
        }.value
    }

}

private enum SharedAuthLoginHandoffFailure: Error {
    case invalidUserID(String)
    case invalidRefreshTokenCookie
}

private extension SharedAuthLoginSuccessPayload {

    func makeUserID() throws -> UUID {
        guard let userID = UUID(uuidString: userIdValue) else {
            throw SharedAuthLoginHandoffFailure.invalidUserID(userIdValue)
        }

        return userID
    }

    func makeCookies(fallbackDomain: String) throws -> [HTTPCookie] {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: refreshTokenCookieName,
            .value: refreshTokenValue,
            .domain: refreshTokenCookieDomain ?? fallbackDomain,
            .path: refreshTokenCookiePath,
            // TODO: Remove with the temporary shared auth bridge.
            // Kalium currently exposes the refresh token value but not the original
            // cookie expiry. Legacy client registration treats a session as logged
            // in only when ZMPersistentCookieStorage can read a zuid expiry.
            .expires: Date(timeIntervalSinceNow: 30 * 24 * 60 * 60)
        ]

        if refreshTokenCookieSecure {
            properties[.secure] = "TRUE"
        }

        if refreshTokenCookieHttpOnly {
            properties[HTTPCookiePropertyKey("HttpOnly")] = "TRUE"
        }

        guard let cookie = HTTPCookie(properties: properties) else {
            throw SharedAuthLoginHandoffFailure.invalidRefreshTokenCookie
        }

        return [cookie]
    }

    func makeAccessToken(userID: UUID) -> AccessToken {
        let expiresIn = accessTokenExpiresInSeconds ?? 60

        return AccessToken(
            userID: userID,
            token: accessTokenValue,
            type: accessTokenType,
            expirationDate: Date(timeIntervalSinceNow: TimeInterval(expiresIn))
        )
    }

    func makeEmailCredentials(
        fallbackEmail: String,
        fallbackPassword: String
    ) -> EmailCredentials? {
        let resolvedEmail = email ?? fallbackEmail
        let resolvedPassword = password ?? fallbackPassword

        guard !resolvedEmail.isEmpty, !resolvedPassword.isEmpty else {
            return nil
        }

        return EmailCredentials(
            email: resolvedEmail,
            password: resolvedPassword,
            verificationCode: secondFactorCode
        )
    }
}
