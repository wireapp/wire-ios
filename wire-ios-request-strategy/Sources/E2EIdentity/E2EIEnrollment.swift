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
import WireCoreCrypto

// MARK: - E2EIEnrollmentInterface

public protocol E2EIEnrollmentInterface {
    /// Get a nonce for creating an account.
    func getACMENonce() async throws -> String

    /// Create a new account.
    func createNewAccount(prevNonce: String) async throws -> String

    /// Create a new order.
    func createNewOrder(prevNonce: String) async throws -> (
        acmeOrder: NewAcmeOrder,
        nonce: String,
        location: String
    )

    /// Fetch challenges.
    func createAuthorization(
        prevNonce: String,
        authzEndpoint: String
    ) async throws -> AcmeAuthorization

    /// Get authorizations
    func getAuthorizations(
        prevNonce: String,
        authorizationsEndpoints: [String]
    ) async throws -> AuthorizationResult

    /// Fetch a nonce from the Wire server.
    func getWireNonce(clientId: String) async throws -> String

    /// Create client DPoP token.
    func getDPoPToken(_ nonce: String) async throws -> String

    /// Fetch a DPoP access token from the Wire server.
    func getWireAccessToken(clientId: String, dpopToken: String) async throws -> AccessTokenResponse

    /// Validate DPoP challenge.
    func validateDPoPChallenge(
        accessToken: String,
        prevNonce: String,
        acmeChallenge: AcmeChallenge
    ) async throws -> ChallengeResponse

    /// Validate OIDC challenge.
    func validateOIDCChallenge(
        idToken: String,
        refreshToken: String,
        prevNonce: String,
        acmeChallenge: AcmeChallenge
    ) async throws -> ChallengeResponse

    /// Set DPoP challenge response.
    func setDPoPChallengeResponse(challengeResponse: ChallengeResponse) async throws

    /// Set OIDC challenge response.
    func setOIDCChallengeResponse(challengeResponse: ChallengeResponse) async throws

    /// Verify the status of the order.
    func checkOrderRequest(location: String, prevNonce: String) async throws -> (
        acmeResponse: ACMEResponse,
        location: String
    )

    /// Create a CSR(Certificate Signing Request) and call finalize url.
    func finalize(location: String, prevNonce: String) async throws -> (
        acmeResponse: ACMEResponse,
        location: String
    )

    /// Fetch certificate.
    func certificateRequest(location: String, prevNonce: String) async throws -> ACMEResponse

    /// Rotate KeyPackages and migrate conversations.
    func rotateKeysAndMigrateConversations(certificateChain: String) async throws

    /// Create new MLS client with e2e identity
    func createMLSClient(certificateChain: String) async throws

    /// Fetch the OIDC refresh token.
    func getOAuthRefreshToken()  async throws -> String?
}

// MARK: - E2EIEnrollment

/// This class implements the steps of the E2EI certificate enrollment process.
public final class E2EIEnrollment: E2EIEnrollmentInterface {
    private let acmeApi: AcmeAPIInterface
    private let acmeDirectory: AcmeDirectory
    private let apiProvider: APIProviderInterface
    private let e2eiService: E2EIServiceInterface
    private let keyRotator: E2EIKeyPackageRotating

    private let logger = WireLogger.e2ei

    public init(
        acmeApi: AcmeAPIInterface,
        apiProvider: APIProviderInterface,
        e2eiService: E2EIServiceInterface,
        acmeDirectory: AcmeDirectory,
        keyRotator: E2EIKeyPackageRotating
    ) {
        self.acmeApi = acmeApi
        self.apiProvider = apiProvider
        self.e2eiService = e2eiService
        self.acmeDirectory = acmeDirectory
        self.keyRotator = keyRotator
    }

    public func getACMENonce() async throws -> String {
        logger.info("get ACME nonce from \(acmeDirectory.newNonce)")

        do {
            return try await acmeApi.getACMENonce(path: acmeDirectory.newNonce)
        } catch {
            logger.error("failed to get ACME nonce: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.missingNonce(error)
        }
    }

    public func createNewAccount(prevNonce: String) async throws -> String {
        logger.info("create new account at \(acmeDirectory.newAccount)")

        do {
            let accountRequest = try await e2eiService.getNewAccountRequest(nonce: prevNonce)
            let apiResponse = try await acmeApi.sendACMERequest(
                path: acmeDirectory.newAccount,
                requestBody: accountRequest
            )
            try await e2eiService.setAccountResponse(accountData: apiResponse.response)
            return apiResponse.nonce
        } catch {
            logger.error("failed to create new account: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToCreateAcmeAccount(error)
        }
    }

    public func createNewOrder(prevNonce: String) async throws -> (
        acmeOrder: NewAcmeOrder,
        nonce: String,
        location: String
    ) {
        logger.info("create new order at  \(acmeDirectory.newOrder)")

        do {
            let newOrderRequest = try await e2eiService.getNewOrderRequest(nonce: prevNonce)
            let apiResponse = try await acmeApi.sendACMERequest(
                path: acmeDirectory.newOrder,
                requestBody: newOrderRequest
            )
            let orderResponse = try await e2eiService.setOrderResponse(order: apiResponse.response)

            return (acmeOrder: orderResponse, nonce: apiResponse.nonce, location: apiResponse.location)
        } catch {
            logger.error("failed to create new order: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToCreateNewOrder(error)
        }
    }

    public func createAuthorization(
        prevNonce: String,
        authzEndpoint: String
    ) async throws -> AcmeAuthorization {
        logger.info("create authz at \(authzEndpoint)")

        do {
            let authzRequest = try await e2eiService.getNewAuthzRequest(url: authzEndpoint, previousNonce: prevNonce)
            let apiResponse = try await acmeApi.sendAuthorizationRequest(path: authzEndpoint, requestBody: authzRequest)
            let challenge = try await e2eiService.setAuthzResponse(authz: apiResponse.response)

            return AcmeAuthorization(
                nonce: apiResponse.nonce,
                location: apiResponse.location,
                response: apiResponse.response,
                challengeType: apiResponse.challengeType,
                newAcmeAuthz: challenge
            )
        } catch {
            logger.error("failed to create authz: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToCreateAuthz(error)
        }
    }

    public func getAuthorizations(
        prevNonce: String,
        authorizationsEndpoints: [String]
    ) async throws -> AuthorizationResult {
        logger.info("get authorizations")

        var challenges: [AuthorizationChallengeType: NewAcmeAuthz] = [:]
        var nonce = prevNonce
        for endpoint in authorizationsEndpoints {
            let auth = try await createAuthorization(prevNonce: nonce, authzEndpoint: endpoint)
            challenges[auth.challengeType] = auth.newAcmeAuthz
            nonce = auth.nonce
        }

        guard let oidcChallenge = challenges[.OIDC],
              let dpopChallenge = challenges[.DPoP] else {
            throw E2EIRepositoryFailure.failedToGetChallenges
        }

        return AuthorizationResult(oidcAuthorization: oidcChallenge, dpopAuthorization: dpopChallenge, nonce: nonce)
    }

    public func getWireNonce(clientId: String) async throws -> String {
        logger.info("get wire nonce")

        guard let apiVersion = BackendInfo.apiVersion,
              let e2eIAPI = apiProvider.e2eIAPI(apiVersion: apiVersion)
        else {
            throw MessageSendError.unresolvedApiVersion
        }

        do {
            return try await e2eIAPI.getWireNonce(clientId: clientId)
        } catch {
            logger.error("failed to get wire nonce: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToGetWireNonce(error)
        }
    }

    public func getDPoPToken(_ nonce: String) async throws -> String {
        logger.info("get DPoP token")

        do {
            return try await e2eiService.createDpopToken(nonce: nonce)
        } catch {
            logger.error("failed to get DPoP token: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToGetDPoPToken(error)
        }
    }

    public func getWireAccessToken(clientId: String, dpopToken: String) async throws -> AccessTokenResponse {
        logger.info("get Wire access token")

        guard let apiVersion = BackendInfo.apiVersion,
              let e2eIAPI = apiProvider.e2eIAPI(apiVersion: apiVersion)
        else {
            throw MessageSendError.unresolvedApiVersion
        }

        do {
            return try await e2eIAPI.getAccessToken(
                clientId: clientId,
                dpopToken: dpopToken
            )
        } catch {
            logger.error("failed to get Wire access token: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToGetAccessToken(error)
        }
    }

    public func validateDPoPChallenge(
        accessToken: String,
        prevNonce: String,
        acmeChallenge: AcmeChallenge
    ) async throws -> ChallengeResponse {
        logger.info("validate DPoP challenge")

        do {
            let challengeRequest = try await e2eiService.getNewDpopChallengeRequest(
                accessToken: accessToken,
                nonce: prevNonce
            )
            let apiResponse = try await acmeApi.sendChallengeRequest(
                path: acmeChallenge.url,
                requestBody: challengeRequest
            )
            try await setDPoPChallengeResponse(challengeResponse: apiResponse)
            return apiResponse

        } catch {
            logger.error("failed to get Wire access token: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToValidateDPoPChallenge(error)
        }
    }

    public func validateOIDCChallenge(
        idToken: String,
        refreshToken: String,
        prevNonce: String,
        acmeChallenge: AcmeChallenge
    ) async throws -> ChallengeResponse {
        logger.info("validate OIDC challenge")

        do {
            let challengeRequest = try await e2eiService.getNewOidcChallengeRequest(
                idToken: idToken,
                refreshToken: refreshToken,
                nonce: prevNonce
            )
            let apiResponse = try await acmeApi.sendChallengeRequest(
                path: acmeChallenge.url,
                requestBody: challengeRequest
            )

            try await setOIDCChallengeResponse(challengeResponse: apiResponse)

            return apiResponse
        } catch {
            logger.error("failed to validate OIDC challenge: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToValidateOIDCChallenge(error)
        }
    }

    public func setDPoPChallengeResponse(challengeResponse: ChallengeResponse) async throws {
        logger.info("set DPoP challenge response")

        let encoder: JSONEncoder = .defaultEncoder
        do {
            let data = try encoder.encode(challengeResponse)
            try await e2eiService.setDPoPChallengeResponse(challenge: data)
        } catch {
            logger.error("failed to set DPoP challenge response: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToSetDPoPChallengeResponse(error)
        }
    }

    public func setOIDCChallengeResponse(challengeResponse: ChallengeResponse) async throws {
        logger.info("set OIDC challenge response")

        let encoder: JSONEncoder = .defaultEncoder
        do {
            let data = try encoder.encode(challengeResponse)
            try await e2eiService.setOIDCChallengeResponse(challenge: data)
        } catch {
            logger.error("failed to set OIDC challenge response: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToSetOIDCChallengeResponse(error)
        }
    }

    public func checkOrderRequest(location: String, prevNonce: String) async throws -> (
        acmeResponse: ACMEResponse,
        location: String
    ) {
        logger.info("check order request")

        do {
            let checkOrderRequest = try await e2eiService.checkOrderRequest(orderUrl: location, nonce: prevNonce)
            let apiResponse = try await acmeApi.sendACMERequest(path: location, requestBody: checkOrderRequest)
            let finalizeOrderUrl = try await e2eiService.checkOrderResponse(order: apiResponse.response)
            return (apiResponse, finalizeOrderUrl)
        } catch {
            logger.error("failed to check order request: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToCheckOrderRequest(error)
        }
    }

    public func finalize(location: String, prevNonce: String) async throws -> (
        acmeResponse: ACMEResponse,
        location: String
    ) {
        logger.info("finalize")

        do {
            let finalizeRequest = try await e2eiService.finalizeRequest(nonce: prevNonce)
            let apiResponse = try await acmeApi.sendACMERequest(path: location, requestBody: finalizeRequest)
            let certificateChain = try await e2eiService.finalizeResponse(finalize: apiResponse.response)
            return (apiResponse, certificateChain)
        } catch {
            logger.error("failed to finalize: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToFinalize(error)
        }
    }

    public func certificateRequest(location: String, prevNonce: String) async throws -> ACMEResponse {
        logger.info("send certificate request")

        do {
            let finalizeRequest = try await e2eiService.certificateRequest(nonce: prevNonce)
            return try await acmeApi.sendACMERequest(path: location, requestBody: finalizeRequest)
        } catch {
            logger.error("failed to send certificate request: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToFinalize(error)
        }
    }

    public func rotateKeysAndMigrateConversations(certificateChain: String) async throws {
        do {
            try await keyRotator.rotateKeysAndMigrateConversations(
                enrollment: e2eiService.e2eIdentity,
                certificateChain: certificateChain
            )
        } catch {
            logger.warn("failed to rotate keys: \(error.localizedDescription)")
            throw E2EIRepositoryFailure.failedToRotateKeys(error)
        }
    }

    public func createMLSClient(certificateChain: String) async throws {
        try await e2eiService.createNewClient(certificateChain: certificateChain)
    }

    public func getOAuthRefreshToken()  async throws -> String? {
        logger.info("get OAuth refresh token")

        do {
            return try await e2eiService.getOAuthRefreshToken()
        } catch {
            logger.error("failed to get OAuth refresh token: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToGetOAuthRefreshToken(error)
        }
    }
}

// MARK: - E2EIRepositoryFailure

enum E2EIRepositoryFailure: Error {
    case missingNonce(_ underlyingError: Error)
    case failedToCreateAcmeAccount(_ underlyingError: Error)
    case failedToCreateNewOrder(_ underlyingError: Error)
    case failedToCreateAuthz(_ underlyingError: Error)
    case failedToGetChallenges
    case failedToGetWireNonce(_ underlyingError: Error)
    case failedToGetDPoPToken(_ underlyingError: Error)
    case failedToGetAccessToken(_ underlyingError: Error)
    case failedToValidateDPoPChallenge(_ underlyingError: Error)
    case failedToValidateOIDCChallenge(_ underlyingError: Error)
    case failedToSetDPoPChallengeResponse(_ underlyingError: Error)
    case failedToSetOIDCChallengeResponse(_ underlyingError: Error)
    case failedToCheckOrderRequest(_ underlyingError: Error)
    case failedToFinalize(_ underlyingError: Error)
    case failedToSendCertificateRequest(_ underlyingError: Error)
    case failedToRotateKeys(_ underlyingError: Error)
    case failedToGetOAuthRefreshToken(_ underlyingError: Error)
}

// MARK: - ChallengeResponse

public struct ChallengeResponse: Codable, Equatable {
    var type: String
    var url: String
    var status: String
    var token: String
    var target: String
    var nonce: String
}

// MARK: - AccessTokenResponse

public struct AccessTokenResponse: Decodable, Equatable {
    var expiresIn: Int
    var token: String
    var type: String

    public enum CodingKeys: String, CodingKey {
        case expiresIn = "expires_in"
        case token
        case type
    }
}

// MARK: - AuthorizationResult

public struct AuthorizationResult {
    var oidcAuthorization: NewAcmeAuthz
    var dpopAuthorization: NewAcmeAuthz
    var nonce: String
}

// MARK: - AcmeAuthorization

public struct AcmeAuthorization {
    var nonce: String
    var location: String?
    var response: Data
    var challengeType: AuthorizationChallengeType
    var newAcmeAuthz: NewAcmeAuthz
}
