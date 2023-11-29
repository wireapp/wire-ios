//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public protocol E2eIEnrollmentInterface {

    /// Get a nonce for creating an account.
    func getACMENonce() async throws -> String

    /// Create a new account.
    func createNewAccount(prevNonce: String) async throws -> String

    /// Create a new order.
    func createNewOrder(prevNonce: String) async throws -> (acmeOrder: NewAcmeOrder,
                                                            nonce: String,
                                                            location: String)

    /// Fetch challenges.
    func createAuthz(prevNonce: String, authzEndpoint: String) async throws -> (authzResponse: NewAcmeAuthz,
                                                                                nonce: String,
                                                                                location: String)

}

/// This class implements the steps of the E2EI certificate enrollment process.
public final class E2eIEnrollment: E2eIEnrollmentInterface {

    private var acmeClient: AcmeClientInterface
    private var e2eiService: E2eIServiceInterface
    private let logger = WireLogger.e2ei
    private let acmeDirectory: AcmeDirectory

    public init(acmeClient: AcmeClientInterface, e2eiService: E2eIServiceInterface, acmeDirectory: AcmeDirectory) {
        self.acmeClient = acmeClient
        self.e2eiService = e2eiService
        self.acmeDirectory = acmeDirectory
    }

    public func getACMENonce() async throws -> String {
        logger.info("get ACME nonce from \(acmeDirectory.newNonce)")

        do {
            return try await acmeClient.getACMENonce(path: acmeDirectory.newNonce)
        } catch {
            logger.error("failed to get ACME nonce: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.missingNonce(error)
        }
    }

    public func createNewAccount(prevNonce: String) async throws -> String {
        logger.info("create new account at \(acmeDirectory.newAccount)")

        do {
            let accountRequest = try await e2eiService.getNewAccountRequest(nonce: prevNonce)
            let apiResponse = try await acmeClient.sendACMERequest(path: acmeDirectory.newAccount, requestBody: accountRequest)
            try await e2eiService.setAccountResponse(accountData: apiResponse.response)
            return apiResponse.nonce
        } catch {
            logger.error("failed to create new account: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToCreateAcmeAccount(error)
        }
    }

    public func createNewOrder(prevNonce: String) async throws -> (acmeOrder: NewAcmeOrder,
                                                                   nonce: String,
                                                                   location: String) {
        logger.info("create new order at  \(acmeDirectory.newOrder)")

        do {
            let newOrderRequest = try await e2eiService.getNewOrderRequest(nonce: prevNonce)
            let apiResponse = try await acmeClient.sendACMERequest(path: acmeDirectory.newOrder, requestBody: newOrderRequest)
            let orderResponse = try await e2eiService.setOrderResponse(order: apiResponse.response)

            return (acmeOrder: orderResponse, nonce: apiResponse.nonce, location: apiResponse.location)
        } catch {
            logger.error("failed to create new order: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToCreateNewOrder(error)
        }
    }

    public func createAuthz(prevNonce: String, authzEndpoint: String) async throws -> (authzResponse: NewAcmeAuthz,
                                                                                       nonce: String,
                                                                                       location: String) {
        logger.info("create authz at  \(authzEndpoint)")

        do {
            let authzRequest = try await e2eiService.getNewAuthzRequest(url: authzEndpoint, previousNonce: prevNonce)
            let apiResponse = try await acmeClient.sendACMERequest(path: authzEndpoint, requestBody: authzRequest)
            let authzResponse = try await e2eiService.setAuthzResponse(authz: apiResponse.response)

            return (authzResponse: authzResponse, nonce: apiResponse.nonce, location: apiResponse.location)
        } catch {
            logger.error("failed to create authz: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToCreateAuthz(error)
        }

    }

}

enum E2EIRepositoryFailure: Error {

    case missingNonce(_ underlyingError: Error)
    case failedToCreateAcmeAccount(_ underlyingError: Error)
    case failedToCreateNewOrder(_ underlyingError: Error)
    case failedToCreateAuthz(_ underlyingError: Error)

}
