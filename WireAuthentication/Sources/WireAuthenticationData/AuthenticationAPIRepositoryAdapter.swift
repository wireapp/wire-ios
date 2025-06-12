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

import WireAPI
import Foundation
import WireAPI
import WireAuthenticationDomain

public final class AuthenticationAPIRepositoryAdapter: AuthenticationAPIRepository {

    private let api: AuthenticationAPI

    public init(api: AuthenticationAPI) {
        self.api = api
    }

    public func login(
        email: String,
        password: String,
        verificationCode: String?,
        label: String?
    ) async throws -> ([HTTPCookie], WireAuthenticationDomain.AccessToken) {
        do {
            let (cookies, accessToken) = try await api.login(
                email: email,
                password: password,
                verificationCode: verificationCode,
                label: label
            )
            return (cookies, WireAuthenticationDomain
                .AccessToken(
                    userID: accessToken.userID,
                    token: accessToken.token,
                    type: accessToken.type,
                    expirationDate: accessToken.expirationDate
                ))
        } catch let error as AuthenticationAPIError {
            throw error.toDomain()
        }
    }

    public func getOnPremConfigURL(forDomain domain: String) async throws -> DomainInfo {
        do {
            return try await api.getOnPremConfigURL(forDomain: domain).toDomain()
        } catch let error as AuthenticationAPIError {
            throw error.toDomain()
        }
    }

    public func getDomainRegistration(forEmail email: String) async throws -> DomainRegistrationConfiguration {
        do {
            return try await api.getDomainRegistration(forEmail: email).toDomain()
        } catch let error as AuthenticationAPIError {
            throw error.toDomain()
        }
    }

    public func validateLoginToken(ssoCode: UUID) async throws {
        do {
            return try await api.validateLoginToken(ssoCode: ssoCode)
        } catch let error as AuthenticationAPIError {
            throw error.toDomain()
        }
    }

    public func getSSOCode() async throws -> UUID? {
        try await api.getSSOCode()
    }

    public func requestVerificationCode(for email: String) async throws {
        try await api.requestVerificationCode(for: email)
    }

    public func requestEmailVerificationCode(for email: String) async throws {
        try await api.requestEmailVerificationCode(for: email)
    }

    public func registerAccount(
        email: String,
        emailCode: String,
        name: String,
        password: String
    ) async throws {
        try await api.registerAccount(
            email: email,
            emailCode: emailCode,
            name: name,
            password: password
        )
    }
}


// MARK: - Domain to Data
extension DomainInfo {
    public func toNetwork() -> NetworkDomainInfo {
        NetworkDomainInfo(configurationURL: self.configurationURL)
    }
}

// MARK: - Data to Domain
extension NetworkDomainInfo {
    public func toDomain() -> DomainInfo {
        DomainInfo(configurationURL: self.configurationURL)
    }
}


// MARK: - Network → Domain
extension NetworkDomainRegistrationConfiguration {
    public func toDomain() -> DomainRegistrationConfiguration {
        DomainRegistrationConfiguration(
            backendURL: backendURL,
            domainRedirect: domainRedirect.toDomain(),
            isCloudAccountAlreadyRegistered: isCloudAccountAlreadyRegistered,
            ssoCode: ssoCode
        )
    }
}

// MARK: - Domain → Network
extension DomainRegistrationConfiguration {
    public func toNetwork() -> NetworkDomainRegistrationConfiguration {
        NetworkDomainRegistrationConfiguration(
            backendURLString: backendURL?.absoluteString,
            domainRedirect: domainRedirect.toNetwork(),
            isCloudAccountAlreadyRegistered: isCloudAccountAlreadyRegistered,
            ssoCodeString: ssoCode?.uuidString
        )
    }
}

extension NetworkDomainRedirect {
    func toDomain() -> DomainRedirect {
        switch self {
        case .locked: return .locked
        case .sso: return .sso
        case .backend: return .backend
        case .noRegistration: return .noRegistration
        case .preAuthorized: return .preAuthorized
        case .none: return .none
        }
    }
}

// MARK: - Domain → Network
extension DomainRedirect {
    func toNetwork() -> NetworkDomainRedirect {
        switch self {
        case .locked: return .locked
        case .sso: return .sso
        case .backend: return .backend
        case .noRegistration: return .noRegistration
        case .preAuthorized: return .preAuthorized
        case .none: return .none
        }
    }
}

extension AuthenticationAPIError {
    func toDomain() -> DomainAuthenticationAPIError {
        switch self {
        case .unsupportedEndpointForAPIVersion:
            return .unsupportedEndpointForAPIVersion
        case .invalidDomain:
            return .invalidDomain
        case .invalidRequestBody:
            return .invalidRequestBody
        case .invalidResponse:
            return .invalidResponse
        case .configNotFound:
            return .configNotFound
        case .domainNotFound:
            return .domainNotFound
        case .twoFactorAuthenticationRequired:
            return .twoFactorAuthenticationRequired
        case .twoFactorAuthenticationFailed:
            return .twoFactorAuthenticationFailed
        case .accountPendingActivation:
            return .accountPendingActivation
        case .accountSuspended:
            return .accountSuspended
        case .invalidCredentials:
            return .invalidCredentials
        case .serviceUnavailable:
            return .serviceUnavailable
        case .invalidEmail:
            return .invalidEmail
        }
    }
}

extension AuthenticationAPIError.SSOLoginError {
    func toDomain() -> DomainAuthenticationAPIError.DomainSSOLoginError {
        switch self {
        case .invalidSSOCode:
            return .invalidSSOCode
        case .invalidStatus(let code):
            return .invalidStatus(code)
        }
    }
}
