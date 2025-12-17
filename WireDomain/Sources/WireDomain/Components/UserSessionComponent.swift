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
import WireDataModel
import WireFoundation
import WireNetwork

public final class UserSessionComponent {

    private let currentBuildNumber: String
    private let selfUserID: UUID

    private let restNetworkService: NetworkService
    private let websocketNetworkService: NetworkService
    private let blacklistNetworkService: NetworkService
    public let backendMetadata: ResolvedBackendMetadata

    private let isMLSEnabled: Bool

    private let sharedUserDefaults: UserDefaults
    private let sharedContainerURL: URL?
    private let syncContext: NSManagedObjectContext
    private let eventContext: NSManagedObjectContext

    private let mlsService: any MLSServiceInterface
    private let mlsDecryptionService: any MLSDecryptionServiceInterface
    private let proteusService: any ProteusServiceInterface
    private let coreCryptoProvider: any CoreCryptoProviderProtocol

    private let faultyRemovalKey: String?
    private let domainAffectedByFaultyRemovalKey: String?

    public init(
        currentBuildNumber: String,
        selfUserID: UUID,
        cookieStorage: any CookieStorageProtocol,
        restNetworkService: NetworkService,
        websocketNetworkService: NetworkService,
        blacklistNetworkService: NetworkService,
        backendMetaData: ResolvedBackendMetadata,
        isMLSEnabled: Bool,
        sharedUserDefaults: UserDefaults,
        sharedContainerURL: URL?,
        syncContext: NSManagedObjectContext,
        eventContext: NSManagedObjectContext,
        mlsService: any MLSServiceInterface,
        mlsDecryptionService: any MLSDecryptionServiceInterface,
        proteusService: any ProteusServiceInterface,
        coreCryptoProvider: any CoreCryptoProviderProtocol,
        faultyRemovalKey: String?,
        domainAffectedByFaultyRemovalKey: String?
    ) {
        self.currentBuildNumber = currentBuildNumber
        self.selfUserID = selfUserID
        self.cookieStorage = cookieStorage
        self.restNetworkService = restNetworkService
        self.websocketNetworkService = websocketNetworkService
        self.blacklistNetworkService = blacklistNetworkService
        self.backendMetadata = backendMetaData
        self.isMLSEnabled = isMLSEnabled
        self.sharedUserDefaults = sharedUserDefaults
        self.syncContext = syncContext
        self.eventContext = eventContext
        self.mlsService = mlsService
        self.mlsDecryptionService = mlsDecryptionService
        self.proteusService = proteusService
        self.coreCryptoProvider = coreCryptoProvider
        self.sharedContainerURL = sharedContainerURL
        self.faultyRemovalKey = faultyRemovalKey
        self.domainAffectedByFaultyRemovalKey = domainAffectedByFaultyRemovalKey
    }

    private let cookieStorage: any CookieStorageProtocol

    // MARK: - Children

    public func clientSessionComponent(
        clientID: String,
        completionHandlers: ClientSessionComponent.CompletionHandlers
    ) -> ClientSessionComponent {
        ClientSessionComponent(
            selfUserID: selfUserID,
            selfClientID: clientID,
            restNetworkService: restNetworkService,
            websocketNetworkService: websocketNetworkService,
            backendMetadata: backendMetadata,
            isMLSEnabled: isMLSEnabled,
            cookieStorage: cookieStorage,
            sharedContainerURL: sharedContainerURL,
            sharedUserDefaults: sharedUserDefaults,
            syncContext: syncContext,
            eventContext: eventContext,
            mlsService: mlsService,
            mlsDecryptionService: mlsDecryptionService,
            proteusService: proteusService,
            coreCryptoProvider: coreCryptoProvider,
            completionHandlers: completionHandlers,
            faultyRemovalKey: faultyRemovalKey,
            domainAffectedByFaultyRemovalKey: domainAffectedByFaultyRemovalKey
        )
    }

    // MARK: - Factory

    public func makeIsBuildBlacklistedUseCase() -> some IsBuildBlacklistedUseCase {
        let api = BlacklistAPIBuilder(networkService: blacklistNetworkService).makeAPI()
        return IsBuildBlacklistedUseCaseImpl(
            currentBuildNumber: currentBuildNumber,
            api: api
        )
    }

}
