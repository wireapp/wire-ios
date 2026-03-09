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

public enum AuthenticationAPIError: Error {

    case unsupportedEndpointForAPIVersion

    case invalidDomain

    case invalidRequestBody

    case invalidResponse

    case configNotFound

    case domainNotFound

    case twoFactorAuthenticationRequired

    case twoFactorAuthenticationFailed

    case accountPendingActivation

    case accountSuspended

    case invalidCredentials

    case serviceUnavailable

    case tooManyRequests(_ message: String, retyAfter: TimeInterval?)

    /// Thrown by `requestVerificationCode(for:)`.

    case invalidEmail

    /// Thrown by `getSSOCode(forEmail:)` when no SSO code exists for the given email
    /// or the SSO feature is disabled.

    case ssoCodeNotFound

}

public extension AuthenticationAPIError {

    enum RegistrationError: Equatable, Error {

        case invalidEmail

        case invalidCode

        case invalidInvitationCode

        case blacklistedEmail

        case keyExists

        case domainBlocked

        case missingIdentity

        case tooManyTeamMembers

        case userCreationRestricted

        case unauthorized
    }

}

public extension AuthenticationAPIError {

    enum SSOLoginError: Equatable, Error {

        case invalidSSOCode

        case invalidStatus(Int)

        init?(responseCode: Int) {
            switch responseCode {
            case HTTPStatusCode.notFound.rawValue:
                self = .invalidSSOCode
            case 400 ... 599:
                self = .invalidStatus(responseCode)
            default:
                return nil
            }
        }
    }

}

extension AuthenticationAPIError: Equatable {
    public static func == (lhs: AuthenticationAPIError, rhs: AuthenticationAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.unsupportedEndpointForAPIVersion, .unsupportedEndpointForAPIVersion): true

        case (.invalidDomain, .invalidDomain): true

        case (.invalidRequestBody, .invalidRequestBody): true

        case (.invalidResponse, .invalidResponse): true

        case (.configNotFound, .configNotFound): true

        case (.domainNotFound, .domainNotFound): true

        case (.twoFactorAuthenticationRequired, .twoFactorAuthenticationRequired): true

        case (.twoFactorAuthenticationFailed, .twoFactorAuthenticationFailed): true

        case (.accountPendingActivation, .accountPendingActivation): true

        case (.accountSuspended, .accountSuspended): true

        case (.invalidCredentials, .invalidCredentials): true

        case (.serviceUnavailable, .serviceUnavailable): true

        case let (.tooManyRequests(lhsMessage, lhsRetyAfter), .tooManyRequests(rhsMessage, rhsRetyAfter)):
            lhsMessage == rhsMessage && lhsRetyAfter == rhsRetyAfter

        case (.invalidEmail, .invalidEmail): true

        case (.ssoCodeNotFound, .ssoCodeNotFound): true

        default: false
        }
    }
}
