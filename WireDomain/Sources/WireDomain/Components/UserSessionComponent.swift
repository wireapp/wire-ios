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
import WireAPI
import WireDataModel
import WireFoundation

public final class UserSessionComponent {

    private let selfUserID: UUID

    private let backendEnvironment: WireAPI.BackendEnvironment
    private let minTLSVersion: WireAPI.TLSVersion
    private let apiVersion: WireAPI.APIVersion

    private let localDomain: String
    private let isFederationEnabled: Bool
    private let isMLSEnabled: Bool

    private let sharedUserDefaults: UserDefaults
    private let syncContext: NSManagedObjectContext
    private let eventContext: NSManagedObjectContext

    private let mlsService: any MLSServiceInterface
    private let mlsDecryptionService: any MLSDecryptionServiceInterface
    private let proteusService: any ProteusServiceInterface

    public init(
        selfUserID: UUID,
        backendEnvironment: WireAPI.BackendEnvironment,
        minTLSVersion: WireAPI.TLSVersion,
        apiVersion: WireAPI.APIVersion,
        localDomain: String,
        isFederationEnabled: Bool,
        isMLSEnabled: Bool,
        sharedUserDefaults: UserDefaults,
        syncContext: NSManagedObjectContext,
        eventContext: NSManagedObjectContext,
        mlsService: any MLSServiceInterface,
        mlsDecryptionService: any MLSDecryptionServiceInterface,
        proteusService: any ProteusServiceInterface
    ) {
        self.selfUserID = selfUserID
        self.backendEnvironment = backendEnvironment
        self.minTLSVersion = minTLSVersion
        self.apiVersion = apiVersion
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled
        self.isMLSEnabled = isMLSEnabled
        self.sharedUserDefaults = sharedUserDefaults
        self.syncContext = syncContext
        self.eventContext = eventContext
        self.mlsService = mlsService
        self.mlsDecryptionService = mlsDecryptionService
        self.proteusService = proteusService
    }

    private lazy var keychain: some KeychainProtocol = WireFoundation.Keychain()

    private lazy var cookieStorage: some CookieStorageProtocol = CookieStorage(
        userID: selfUserID,
        cookieEncryptionKey: UserDefaults.cookiesKey(),
        keychain: keychain
    )

    private lazy var serverTrustValidator = ServerTrustValidator(
        pinnedKeys: backendEnvironment.pinnedKeys
    )

    private lazy var urlSessionConfigurationFactory = URLSessionConfigurationFactory(
        minTLSVersion: minTLSVersion,
        proxySettings: backendEnvironment.proxySettings
    )

    private lazy var networkService: NetworkService = {
        let networkService = NetworkService(
            baseURL: backendEnvironment.url,
            serverTrustValidator: serverTrustValidator
        )
        let config = urlSessionConfigurationFactory.makeRESTAPISessionConfiguration()
        let session = URLSession(
            configuration: config,
            delegate: networkService,
            delegateQueue: nil
        )
        networkService.configure(with: session)
        return networkService
    }()

    private lazy var pushChannelNetworkService: NetworkService = {
        let networkService = NetworkService(
            baseURL: backendEnvironment.webSocketURL,
            serverTrustValidator: serverTrustValidator
        )
        let config = urlSessionConfigurationFactory.makeWebSocketSessionConfiguration()
        let session = URLSession(
            configuration: config,
            delegate: networkService,
            delegateQueue: nil
        )
        networkService.configure(with: session)
        return networkService
    }()

    // MARK: - Children

    public func clientSessionComponent(clientID: String) -> ClientSessionComponent {
        ClientSessionComponent(
            selfUserID: selfUserID,
            selfClientID: clientID,
            networkService: networkService,
            pushChannelNetworkService: pushChannelNetworkService,
            apiVersion: apiVersion,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled,
            isMLSEnabled: isMLSEnabled,
            cookieStorage: cookieStorage,
            sharedUserDefaults: sharedUserDefaults,
            syncContext: syncContext,
            eventContext: eventContext,
            mlsService: mlsService,
            mlsDecryptionService: mlsDecryptionService,
            proteusService: proteusService
        )
    }

}
