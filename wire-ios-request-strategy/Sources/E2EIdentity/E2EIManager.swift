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

public protocol E2EIManagerInterface {

    /// Fetch acme directory for hyperlinks.
    func loadACMEDirectory() async -> AcmeDirectory?

    /// Get a nonce for creating an account.
    func getACMENonce(endpoint: String) async -> String?

    /// Create a new account.
    func createNewAccount(prevNonce: String, createAccountEndpoint: String) async -> String?

    /// Create a new order.
    func createNewOrder(prevNonce: String, createOrderEndpoint: String) async -> (acmeOrder: WireCoreCrypto.NewAcmeOrder?, nonce: String, location: String)?

}

public final class E2EIManager: E2EIManagerInterface {

    private var apiProvider: APIProvider
    private var e2eiService: E2EIServiceInterface?

    public init(apiProvider: APIProvider, e2eiService: E2EIServiceInterface) {
        self.apiProvider = apiProvider
        self.e2eiService = e2eiService
    }

    public func loadACMEDirectory() async -> AcmeDirectory? {
        guard let acmeAPI = apiProvider.acmeAPI(apiVersion: .v5),
              let acmeDirectory = await acmeAPI.getACMEDirectory() else {
            WireLogger.e2ei.warn("Failed to get acme directory from acme server")

            return nil
        }

        guard let acmeDirectoryData = try? JSONEncoder().encode(acmeDirectory),
              let directoryResponse = try? await e2eiService?.directoryResponse(directoryData: acmeDirectoryData) else {
            WireLogger.e2ei.warn("Failed to get directory response")

            return nil
        }

        return AcmeDirectory(newNonce: directoryResponse.newNonce,
                             newAccount: directoryResponse.newAccount,
                             newOrder: directoryResponse.newOrder)
    }

    public func getACMENonce(endpoint: String) async -> String? {
        guard let acmeAPI = apiProvider.acmeAPI(apiVersion: .v5) else {
            return nil
        }
        return await acmeAPI.getACMENonce(url: endpoint)
    }

    public func createNewAccount(prevNonce: String, createAccountEndpoint: String) async -> String? {
        guard let accountRequest = try? await e2eiService?.getNewAccountRequest(previousNonce: prevNonce) else {
            WireLogger.e2ei.warn("Failed to get new account request")

            return nil
        }

        guard let acmeAPI = apiProvider.acmeAPI(apiVersion: .v5),
              let apiResponse = await acmeAPI.sendACMERequest(url: createAccountEndpoint, body: accountRequest) else {

            return nil
        }

        do {
            try await e2eiService?.setAccountResponse(accountData: apiResponse.response)
            return apiResponse.nonce
        } catch {
            return nil
        }
    }

    public func createNewOrder(prevNonce: String, createOrderEndpoint: String) async -> (acmeOrder: WireCoreCrypto.NewAcmeOrder?, nonce: String, location: String)? {
        guard let newOrderRequest = try? await e2eiService?.getNewOrderRequest(nonce: prevNonce) else {
            WireLogger.e2ei.warn("Failed to get new order request")

            return nil
        }
        guard let acmeAPI = apiProvider.acmeAPI(apiVersion: .v5),
              let apiResponse = await acmeAPI.sendACMERequest(url: createOrderEndpoint, body: newOrderRequest) else {

            return nil
        }

        do {
            let orderResponse = try await e2eiService?.setOrderResponse(order: apiResponse.response)
            return (acmeOrder: orderResponse, nonce: apiResponse.nonce, location: apiResponse.location)
        } catch {
            return nil
        }
    }

}
