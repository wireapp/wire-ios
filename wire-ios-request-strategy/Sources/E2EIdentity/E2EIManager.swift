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

}

public final class E2EIManager: E2EIManagerInterface {

    private var apiProvider: APIProvider
    private var context: NSManagedObjectContext?

    public init(apiProvider: APIProvider, context: NSManagedObjectContext) {
        self.apiProvider = apiProvider
        self.context = context
    }

    public func loadACMEDirectory() async -> AcmeDirectory? {
        var directory: WireCoreCrypto.AcmeDirectory?

        guard let acmeAPI = apiProvider.acmeAPI(apiVersion: .v5),
              let acmeDirectory = await acmeAPI.getACMEDirectory() else {
            WireLogger.e2ei.warn("Failed to get acme directory from acme server")

            return nil
        }

        context?.performAndWait {
            guard let e2eiService = context?.e2eiService else {
                WireLogger.e2ei.warn("E2EIService is missing")

                return
            }

            guard let acmeDirectoryData = try? JSONEncoder().encode(acmeDirectory),
                  let directoryResponse = try? e2eiService.directoryResponse(directoryData: acmeDirectoryData) else {
                WireLogger.e2ei.warn("Failed to get directory response")

                return
            }
            directory = directoryResponse

        }

        guard let directory = directory else {
            return nil
        }
        return AcmeDirectory(newNonce: directory.newNonce,
                             newAccount: directory.newAccount,
                             newOrder: directory.newOrder)
    }

    public func getACMENonce(endpoint: String) async -> String? {
        guard let acmeAPI = apiProvider.acmeAPI(apiVersion: .v5) else {
            return nil
        }
        return await acmeAPI.getACMENonce(url: endpoint)
    }

    public func createNewAccount(prevNonce: String, createAccountEndpoint: String) async -> String? {
        var response: ACMEResponse?

        context?.performAndWait {
            guard let e2eiService = context?.e2eiService else {
                WireLogger.e2ei.warn("E2EIService is missing")

                return
            }

            guard let accountRequest = try? e2eiService.getNewAccountRequest(previousNonce: prevNonce) else {
                WireLogger.e2ei.warn("Failed to get new account request")

                return
            }

            // TODO: convert accountRequest to ZMTransportData
            guard let acmeAPI = apiProvider.acmeAPI(apiVersion: .v5),
                  let apiResponse = await acmeAPI.sendACMERequest(url: createAccountEndpoint, body: accountRequest) else {

                return nil
            }

            guard let resp = try? e2eiService.setAccountResponse(accountData: apiResponse.response) else {
                return
            }
            response = apiResponse

        }

        return response?.nonce
    }

}
