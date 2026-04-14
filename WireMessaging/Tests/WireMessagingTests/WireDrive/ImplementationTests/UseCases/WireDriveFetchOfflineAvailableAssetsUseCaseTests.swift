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
final class WireDriveFetchOfflineAvailableAssetsUseCaseTests {

    private let localAssetRepository: WireDriveLocalAssetRepository!
    private let store = MockWireDriveLocalAssetStoreProtocol()
    private var storeBacking: [UUID: WireDriveLocalAsset] = [:]
    private let sut: WireDriveFetchOfflineAvailableAssetsUseCase

    init() {
        self.localAssetRepository = WireDriveLocalAssetRepository(
            nodesAPI: MockNodesAPIProtocol(),
            fileDownloader: MockFileDownloading(),
            fileCache: MockFileCache(),
            store: store
        )

        self.sut = WireDriveFetchOfflineAvailableAssetsUseCase(
            localAssetRepository: localAssetRepository,
        )

        store.upsertAsset_MockMethod = { [weak self] asset in
            self?.storeBacking[asset.nodeID] = asset
        }

        store.offlineAssetsConversationNameAssetsPath_MockMethod = { [weak self] conversationName, _ in
            if let conversationName {
                return self?.storeBacking.map(\.value).filter { $0.conversationName == conversationName } ?? []
            } else {
                return self?.storeBacking.map(\.value) ?? []
            }
        }
    }

    @Test
    func `It retrieves all available offline assets locally`() async throws {
        // given
        let assets = [WireDriveLocalAsset.fixture(), .fixture(), .fixture()]
        try assets.forEach(store.upsertAsset)

        // when
        let availableAssets = try await sut.invoke(conversationName: nil, assetsPath: nil)

        // then
        #expect(availableAssets.count == assets.count)
    }

    @Test
    func `It retrieves available offline assets for a given conversation locally`() async throws {
        // given
        let assets = [
            WireDriveLocalAsset.fixture(conversationName: "Test"),
            .fixture(conversationName: "Test"),
            .fixture(),
            .fixture(),
            .fixture()
        ]
        try assets.forEach(store.upsertAsset)

        // when
        let availableAssets = try await sut.invoke(conversationName: "Test", assetsPath: nil)

        // then
        #expect(availableAssets.count == 2)
    }

}
