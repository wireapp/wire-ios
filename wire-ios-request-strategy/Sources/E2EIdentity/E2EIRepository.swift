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

public protocol E2EIRepositoryInterface {

    /// Fetch acme directory for hyperlinks.
    func loadACMEDirectory() async throws -> AcmeDirectory

    /// Get a nonce for creating an account.
    func getACMENonce(endpoint: String) async throws -> String

    /// Create a new account.
    func createNewAccount(prevNonce: String, createAccountEndpoint: String) async throws -> String

    /// Create a new order.
    func createNewOrder(prevNonce: String, createOrderEndpoint: String) async throws -> (acmeOrder: NewAcmeOrder?,
                                                                                         nonce: String,
                                                                                         location: String)

}

/// This class implements the steps of the E2EI certificate enrollment process.
public final class E2EIRepository: E2EIRepositoryInterface {

    private var acmeClient: AcmeClientInterface
    private var e2eiService: E2EIServiceInterface
    private let logger = WireLogger.e2ei

    public init(acmeClient: AcmeClientInterface, e2eiService: E2EIServiceInterface) {
        self.acmeClient = acmeClient
        self.e2eiService = e2eiService
    }

    public func loadACMEDirectory() async throws -> AcmeDirectory {
        logger.info("load ACME directory")

        do {
            try await e2eiService.setupEnrollment()
            let acmeDirectoryData = try await acmeClient.getACMEDirectory()
            return try await e2eiService.directoryResponse(directoryData: acmeDirectoryData)
        } catch {
            logger.error("failed to load ACME directory: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToLoadACMEDirectory
        }
    }

    public func getACMENonce(endpoint: String) async throws -> String {
        logger.info("get ACME nonce from \(endpoint)")

        do {
            return try await acmeClient.getACMENonce(url: endpoint)
        } catch {
            logger.error("failed to get ACME nonce: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.missingNonce
        }
    }

    public func createNewAccount(prevNonce: String, createAccountEndpoint: String) async throws -> String {
        logger.info("create new account at \(createAccountEndpoint)")

        do {
            let accountRequest = try await e2eiService.getNewAccountRequest(previousNonce: prevNonce)
            let apiResponse = try await acmeClient.sendACMERequest(url: createAccountEndpoint, requestBody: accountRequest)
            try await e2eiService.setAccountResponse(accountData: apiResponse.response)
            return apiResponse.nonce
        } catch {
            logger.error("failed to create new account: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToCreateAcmeAccount
        }
    }

    public func createNewOrder(prevNonce: String, createOrderEndpoint: String) async throws -> (acmeOrder: NewAcmeOrder?,
                                                                                                nonce: String,
                                                                                                location: String) {
        logger.info("create new order at  \(createOrderEndpoint)")

        do {
            let newOrderRequest = try await e2eiService.getNewOrderRequest(nonce: prevNonce)
            let apiResponse = try await acmeClient.sendACMERequest(url: createOrderEndpoint, requestBody: newOrderRequest)
            let orderResponse = try await e2eiService.setOrderResponse(order: apiResponse.response)
            return (acmeOrder: orderResponse, nonce: apiResponse.nonce, location: apiResponse.location)
        } catch {
            logger.error("failed to create new order: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToCreateNewOrder
        }
    }

}

enum E2EIRepositoryFailure: Error {

    case failedToLoadACMEDirectory
    case missingNonce
    case failedToCreateAcmeAccount
    case failedToCreateNewOrder

}
