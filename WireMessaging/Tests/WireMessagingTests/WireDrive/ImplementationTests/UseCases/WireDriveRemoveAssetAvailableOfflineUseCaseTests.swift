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

import Foundation
import Testing

import WireMessagingDomainSupport
@testable import WireMessagingData
@testable import WireMessagingDomain

@MainActor
final class WireDriveRemoveAssetAvailableOfflineUseCaseTests {

    private let nodesAPI = MockNodesAPIProtocol()
    private let localAssetRepository: WireDriveLocalAssetRepository!
    private let store = MockWireDriveLocalAssetStoreProtocol()
    private var storeBacking: [UUID: WireDriveLocalAsset] = [:]
    private let sut: WireDriveRemoveAssetAvailableOfflineUseCase

    init() {
        self.localAssetRepository = WireDriveLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileCache: MockFileCache(),
            store: store
        )

        self.sut = WireDriveRemoveAssetAvailableOfflineUseCase(
            localAssetRepository: localAssetRepository,
        )

        store.assetNodeID_MockMethod = { [weak self] nodeID in
            self?.storeBacking[nodeID]
        }
        store.upsertAsset_MockMethod = { [weak self] asset in
            self?.storeBacking[asset.nodeID] = asset
        }
    }

    @Test
    func `It retrieves and sets the available offline flag to false`() async throws {
        // given
        let asset = WireDriveLocalAsset.fixture(
            isAvailableOffline: true,
            downloadState: .downloaded(cacheKey: UUID.mockID1.uuidString)
        )
        storeBacking[asset.nodeID] = asset
        #expect(asset.isAvailableOffline == true)

        // when
        try sut.invoke(nodeID: asset.nodeID)

        // then
        #expect(storeBacking[asset.nodeID]?.isAvailableOffline == false)
    }

    @Test
    func `It throws when asset is missing locally`() async throws {
        // given
        let asset = WireDriveLocalAsset.fixture(
            isAvailableOffline: true,
            downloadState: .downloaded(cacheKey: UUID.mockID1.uuidString)
        )

        // then
        #expect(throws: WireDriveRemoveAssetAvailableOfflineUseCase.Failure.assetNotFound) {
            // when
            try sut.invoke(nodeID: asset.nodeID)
        }
    }

}
