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
final class WireDriveMakeAssetAvailableOfflineUseCaseTests {

    private let nodesAPI = MockNodesAPIProtocol()
    private let localAssetRepository: WireDriveLocalAssetRepository!
    private let fileDownloader = MockFileDownloading()
    private let fileCache = MockFileCache()
    private let store = MockWireDriveLocalAssetStoreProtocol()
    private var storeBacking: [UUID: WireDriveLocalAsset] = [:]
    private let sut: WireDriveMakeAssetAvailableOfflineUseCase

    init() {
        self.localAssetRepository = WireDriveLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileDownloader: fileDownloader,
            fileCache: fileCache,
            store: store
        )

        self.sut = WireDriveMakeAssetAvailableOfflineUseCase(
            localAssetRepository: localAssetRepository,
        )

        fileCache.saveFileAtKey_MockMethod = { _, _ in }
        fileCache.deleteFileForKey_MockMethod = { _ in }

        store.assetNodeID_MockMethod = { [weak self] nodeID in
            self?.storeBacking[nodeID]
        }
        store.upsertAsset_MockMethod = { [weak self] asset in
            self?.storeBacking[asset.nodeID] = asset
        }
    }

    @Test
    func `It retrieves the asset locally and sets the available offline flag to true`() async throws {
        // given
        let asset = WireDriveLocalAsset.fixture(
            isAvailableOffline: false,
            downloadState: .downloaded(cacheKey: UUID.mockID1.uuidString)
        )
        storeBacking[asset.nodeID] = asset
        #expect(asset.isAvailableOffline == false)

        // when
        try await sut.invoke(nodeID: asset.nodeID)

        // then
        #expect(storeBacking[asset.nodeID]?.isAvailableOffline == true)
    }

    @Test
    func `It downloads and sets the available offline flag to true`() async throws {
        // given
        let nodeID = UUID()
        let asset = WireDriveLocalAsset.fixture(nodeID: nodeID, isAvailableOffline: false)

        nodesAPI.getNodeNodeID_MockValue = .fixture(
            uuid: nodeID,
            eTag: "eTag",
            downloadURL: URL(string: "https://wire.com")!
        )
        let (progressStream, progressContinuation) = AsyncThrowingStream.makeStream(of: Double.self)
        fileDownloader.downloadFrom_MockValue = (progress: progressStream, download: Task.fixture())

        Task {
            progressContinuation.yield(0.5)
            progressContinuation.yield(1)
            progressContinuation.finish()
        }

        // when
        try await sut.invoke(nodeID: nodeID)

        // then
        #expect(fileDownloader.downloadFrom_Invocations.count == 1)
        #expect(storeBacking[asset.nodeID]?.isAvailableOffline == true)
    }

}
