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
import WireAPI

public final class NetworkStack {

    let backendEnvironment: BackendEnvironment
    let minTLSVersion: TLSVersion
    let cookieEncryptionKey: Data

    public init(
        backendEnvironment: BackendEnvironment,
        minTLSVersion: TLSVersion,
        cookieEncryptionKey: Data
    ) {
        self.backendEnvironment = backendEnvironment
        self.minTLSVersion = minTLSVersion
        self.cookieEncryptionKey = cookieEncryptionKey
    }

    private lazy var keychain: some KeychainProtocol = Keychain()
    private lazy var urlSessionConfigurationFactory = URLSessionConfigurationFactory(
        minTLSVersion: minTLSVersion,
        proxySettings: backendEnvironment.proxySettings
    )

    private lazy var apiService: some APIServiceProtocol = APIService(
        networkService: apiNetworkService,
        authenticationManager: MockAuthManager()
    )

    public lazy var apiNetworkService: NetworkService = {
        let service = NetworkService(baseURL: backendEnvironment.url, serverTrustValidator: serverTrustValidator)
        let config = urlSessionConfigurationFactory.makeRESTAPISessionConfiguration()
        let session = URLSession(configuration: config, delegate: service, delegateQueue: nil)
        service.configure(with: session)
        return service
    }()

    private lazy var serverTrustValidator = ServerTrustValidator(
        pinnedKeys: backendEnvironment.pinnedKeys,
        currentDateProvider: .system
    )

}

private struct MockAuthManager: AuthenticationManagerProtocol {
    func getValidAccessToken() async throws -> WireAPI.AccessToken {
        fatalError()
    }
    
    func refreshAccessToken() async throws -> WireAPI.AccessToken {
        fatalError()
    }
    
    
}
