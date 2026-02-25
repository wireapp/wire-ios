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

public import Foundation

// sourcery: AutoMockable
public protocol AuthenticationAPI: Sendable {

    /// Login via email
    ///
    /// - Parameters:
    ///   - email: Email address of the account
    ///   - password: Password
    ///   - verificationCode: The verification code is sent to the given user’s email address,
    ///   this is an optional field and depends on the team/server settings.
    ///   - label: An optional label to associate with the access token.
    /// - Returns: HTTP cookie, a valid access token.

    func login(
        email: String,
        password: String,
        verificationCode: String?,
        label: String?
    ) async throws -> ([HTTPCookie], AccessToken)

    /// Get on-prem config `URL` for domain

    func getOnPremConfigURL(forDomain domain: String) async throws -> DomainInfo

    /// Get domain registration configuration by email

    func getDomainRegistration(forEmail email: String) async throws -> DomainRegistrationConfiguration

    /// Validated a company login token (SSO code).
    /// This method will verify a company login token with the backend
    ///
    /// - Parameters:
    ///   - ssoCode: Company login token (SSO code)

    func validateLoginToken(ssoCode: UUID) async throws

    /// Get the default SSO code associated with the backend
    /// - Returns: user UUID

    func getSSOCode() async throws -> UUID?

    /// Get the SSO code associated with the given email address.
    ///
    /// Available from API version 15 onwards.
    ///
    /// - Parameter email: The email address to look up.
    /// - Returns: The SSO code UUID associated with the email's domain.
    /// - Throws: `AuthenticationAPIError.ssoCodeNotFound` if no SSO code exists
    ///   for the email or the SSO feature is disabled.
    ///   `AuthenticationAPIError.unsupportedEndpointForAPIVersion` if called on a version below v15.

    func getSSOCode(forEmail email: String) async throws -> UUID

    /// Request a 2FA verification code sent to the given email address.
    ///
    /// - Parameter email: Email address of the account.
    /// - Throws: `AuthenticationAPIError.invalidEmail` if the email address is malformed.

    func requestVerificationCode(for email: String) async throws

    /// Get Activation key & code for email
    /// - Parameters:
    ///   - email: email of user
    ///   - basicAuth: basicAuth value
    /// - Returns: Code & Key
    #if DEBUG
        func getActivationCode(forEmail email: String, basicAuth: String) async throws -> (code: String, key: String)
    #endif

    /// Register Personal Account
    /// - Parameters:
    ///   - name: name of the user
    ///   - email: email of the user
    ///   - password: password to authenticate the account
    /// - Returns: HTTP cookie for access token
    #if DEBUG
        func registerPersonalAccount(name: String, email: String, password: String) async throws -> [HTTPCookie]
    #endif
    /// Activate user
    /// - Parameters:
    ///   - email: user email address
    ///   - key: key to activate user
    ///   - code: code to activate user
    #if DEBUG
        func activateUser(email: String, key: String, code: String) async throws
    #endif
    /// Send (or resend) an email activation code
    /// - Parameters:
    ///   - email: Email address of the account
    func requestEmailVerificationCode(for email: String) async throws

    /// Register a new user.
    /// - Parameters:
    ///   - email: Email address of the account
    ///   - emailCode: Activation code
    ///   - name: Full user name
    ///   - password: Password
    ///   - label: Label
    /// - Returns: HTTP cookie and user ID.
    func registerAccount(
        email: String,
        emailCode: String,
        name: String,
        password: String,
        label: String
    ) async throws -> (cookie: [HTTPCookie], userId: UUID?)

    /// Register user as team owner
    /// - Parameters:
    ///   - email: Owner email
    ///   - password: Owner password
    ///   - name: Owner name
    ///   - teamName: team name
    /// - Returns: teamID
    #if DEBUG
        func registerTeamOwner(
            email: String,
            password: String,
            name: String,
            teamName: String
        ) async throws -> (teamId: UUID?, qualifiedId: QualifiedID)
    #endif

    /// Get invitation code from invitation ID
    /// - Parameters:
    ///   - teamID: teamID for invitation code required
    ///   - invitationID: invitationID
    /// - Returns: Invitation code
    #if DEBUG
        func getInvitationCode(teamID: UUID, invitationID: UUID) async throws -> String
    #endif

    /// Register member to team
    /// - Parameters:
    ///   - email: member email
    ///   - password: member password
    ///   - name: member name
    ///   - invitationCode: invitation Code to register in team
    /// - Returns: registered user-id
    #if DEBUG
        func registerTeamMember(
            email: String,
            password: String,
            name: String,
            invitationCode: String
        ) async throws -> QualifiedID
    #endif
}
