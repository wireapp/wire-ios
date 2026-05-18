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

public protocol SharedAuthLoginFlowObservation {
    func cancel()
}

public protocol SharedAuthLoginFlowManaging: AnyObject {

    @MainActor var currentState: SharedAuthLoginFlowState { get }

    @MainActor
    func observeState(
        _ observer: @escaping @MainActor (SharedAuthLoginFlowState) -> Void
    ) -> any SharedAuthLoginFlowObservation

    @MainActor
    func observeEffect(
        _ observer: @escaping @MainActor (SharedAuthLoginFlowEffect) -> Void
    ) -> any SharedAuthLoginFlowObservation

    @MainActor
    func send(_ intent: SharedAuthLoginFlowIntent)

    @MainActor
    func close()

}

public protocol SharedAuthLoginFlowFactory {
    @MainActor var sharedAuthLoginFlow: (any SharedAuthLoginFlowManaging)? { get }
}

public struct SharedAuthLoginFlowState: Equatable, Sendable {

    public var step: SharedAuthLoginFlowStep
    public var identifier: String
    public var password: String
    public var secondFactorCode: String
    public var secondFactorEmail: String?
    public var ssoCode: String
    public var canSubmitIdentifier: Bool
    public var canSubmitCredentials: Bool
    public var canSubmitSecondFactor: Bool
    public var canSubmitSsoCode: Bool
    public var isLoading: Bool
    public var error: SharedAuthLoginFlowError?

    public init(
        step: SharedAuthLoginFlowStep,
        identifier: String,
        password: String,
        secondFactorCode: String,
        secondFactorEmail: String?,
        ssoCode: String,
        canSubmitIdentifier: Bool,
        canSubmitCredentials: Bool,
        canSubmitSecondFactor: Bool,
        canSubmitSsoCode: Bool,
        isLoading: Bool,
        error: SharedAuthLoginFlowError?
    ) {
        self.step = step
        self.identifier = identifier
        self.password = password
        self.secondFactorCode = secondFactorCode
        self.secondFactorEmail = secondFactorEmail
        self.ssoCode = ssoCode
        self.canSubmitIdentifier = canSubmitIdentifier
        self.canSubmitCredentials = canSubmitCredentials
        self.canSubmitSecondFactor = canSubmitSecondFactor
        self.canSubmitSsoCode = canSubmitSsoCode
        self.isLoading = isLoading
        self.error = error
    }
}

public enum SharedAuthLoginFlowStep: Equatable, Sendable {
    case identifierEntry
    case emailCredentialsEntry
    case secondFactorEntry
    case success(initialSyncCompleted: Bool, isE2EIRequired: Bool)
}

public enum SharedAuthLoginFlowError: Equatable, Sendable {
    case invalidIdentifier
    case invalidCredentials
    case invalidSecondFactorCode
    case tooManyDevices
    case generic(message: String?)
}

public enum SharedAuthLoginFlowEffect: Equatable, Sendable {
    case openSsoURL(url: URL, userIdentifier: String?)
    case loginSucceeded(payload: SharedAuthLoginSuccessPayload)
}

public enum SharedAuthLoginFlowIntent: Equatable, Sendable {
    case identifierChanged(String)
    case passwordChanged(String)
    case secondFactorCodeChanged(String)
    case ssoCodeChanged(String)
    case submitIdentifier
    case submitCredentials(usernameAllowed: Bool)
    case submitSecondFactor(usernameAllowed: Bool)
    case submitSsoCode
    case back
    case cancel
    case clearError
}

public struct SharedAuthLoginSuccessPayload: Equatable, Sendable {

    public var userIdValue: String
    public var userIdDomain: String?
    public var accessTokenValue: String
    public var accessTokenType: String
    public var accessTokenExpiresInSeconds: Int?
    public var refreshTokenValue: String
    public var refreshTokenCookieName: String
    public var refreshTokenCookieDomain: String?
    public var refreshTokenCookiePath: String
    public var refreshTokenCookieSecure: Bool
    public var refreshTokenCookieHttpOnly: Bool
    public var email: String?
    public var password: String?
    public var secondFactorCode: String?
    public var initialSyncCompleted: Bool
    public var isE2EIRequired: Bool
    public var clientId: String?

    public init(
        userIdValue: String,
        userIdDomain: String?,
        accessTokenValue: String,
        accessTokenType: String,
        accessTokenExpiresInSeconds: Int?,
        refreshTokenValue: String,
        refreshTokenCookieName: String,
        refreshTokenCookieDomain: String?,
        refreshTokenCookiePath: String,
        refreshTokenCookieSecure: Bool,
        refreshTokenCookieHttpOnly: Bool,
        email: String?,
        password: String?,
        secondFactorCode: String?,
        initialSyncCompleted: Bool,
        isE2EIRequired: Bool,
        clientId: String?
    ) {
        self.userIdValue = userIdValue
        self.userIdDomain = userIdDomain
        self.accessTokenValue = accessTokenValue
        self.accessTokenType = accessTokenType
        self.accessTokenExpiresInSeconds = accessTokenExpiresInSeconds
        self.refreshTokenValue = refreshTokenValue
        self.refreshTokenCookieName = refreshTokenCookieName
        self.refreshTokenCookieDomain = refreshTokenCookieDomain
        self.refreshTokenCookiePath = refreshTokenCookiePath
        self.refreshTokenCookieSecure = refreshTokenCookieSecure
        self.refreshTokenCookieHttpOnly = refreshTokenCookieHttpOnly
        self.email = email
        self.password = password
        self.secondFactorCode = secondFactorCode
        self.initialSyncCompleted = initialSyncCompleted
        self.isE2EIRequired = isE2EIRequired
        self.clientId = clientId
    }
}
