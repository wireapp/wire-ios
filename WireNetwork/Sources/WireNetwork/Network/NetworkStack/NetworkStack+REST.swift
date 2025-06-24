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

import Foundation
import WireFoundation

public extension NetworkStack {

    func unauthenticatedRESTAPI() async throws -> UnauthenticatedRESTAPI {
        UnauthenticatedRESTAPI(
            apiVersion: try await resolvedAPIVersion(),
            networkService: try networkServices.rest
        )
    }

    func authenticatedRESTAPI(
        userID: UUID,
        clientID: String?,
        cookieEncryptionKey: Data
    ) async throws -> AuthenticatedRESTAPI {
        let apiVersion = try await resolvedAPIVersion()
        let networkServices = try networkServices

        let cookieStorage = CookieStorage(
            userID: userID,
            cookieEncryptionKey: cookieEncryptionKey,
            keychain: Keychain()
        )

        let authenticationManager = AuthenticationManager(
            clientID: clientID,
            cookieStorage: cookieStorage,
            networkService: networkServices.rest,
            onAuthenticationFailure: {} // TODO: network stack should bubble this up
        )

        let apiService = APIService(
            networkService: networkServices.rest,
            authenticationManager: authenticationManager
        )

        let pushChannelService = PushChannelService(
            networkService: networkServices.webSocket,
            authenticationManager: authenticationManager
        )

        return AuthenticatedRESTAPI(
            apiVersion: apiVersion,
            apiService: apiService,
            pushChannelService: pushChannelService
        )
    }

}
