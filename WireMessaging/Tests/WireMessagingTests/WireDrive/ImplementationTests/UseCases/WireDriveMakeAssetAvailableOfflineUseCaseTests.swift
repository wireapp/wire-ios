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
        _ = await sut.invoke(nodeIDs: [asset.nodeID])

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
        _ = await sut.invoke(nodeIDs: [nodeID])

        // then
        #expect(fileDownloader.downloadFrom_Invocations.count == 1)
        #expect(storeBacking[asset.nodeID]?.isAvailableOffline == true)
    }

    @Test
    func `It reuses cached assets and downloads missing assets in the same selection`() async throws {
        let cachedAsset = WireDriveLocalAsset.fixture(
            nodeID: UUID(),
            isAvailableOffline: false,
            downloadState: .downloaded(cacheKey: "cached-file")
        )
        storeBacking[cachedAsset.nodeID] = cachedAsset
        let nodeID = UUID()
        nodesAPI.getNodeNodeID_MockValue = .fixture(
            uuid: nodeID,
            eTag: "eTag",
            downloadURL: URL(string: "https://wire.com")!
        )
        let (progressStream, continuation) = AsyncThrowingStream.makeStream(of: Double.self)
        continuation.finish()
        fileDownloader.downloadFrom_MockValue = (progress: progressStream, download: Task.fixture())

        _ = await sut.invoke(nodeIDs: [cachedAsset.nodeID, nodeID, cachedAsset.nodeID])

        #expect(storeBacking[cachedAsset.nodeID]?.isAvailableOffline == true)
        #expect(storeBacking[cachedAsset.nodeID]?.downloadState.cacheKey == "cached-file")
        #expect(storeBacking[nodeID]?.isAvailableOffline == true)
        #expect(storeBacking[nodeID]?.downloadState.cacheKey != nil)
        #expect(nodesAPI.getNodeNodeID_Invocations == [nodeID])
        #expect(fileDownloader.downloadFrom_Invocations.count == 1)
    }

    @Test
    func `It continues after a cached asset update fails`() async throws {
        let failedAsset = WireDriveLocalAsset.fixture(downloadState: .downloaded(cacheKey: "failed-file"))
        let cachedAsset = WireDriveLocalAsset.fixture(downloadState: .downloaded(cacheKey: "cached-file"))
        storeBacking[failedAsset.nodeID] = failedAsset
        storeBacking[cachedAsset.nodeID] = cachedAsset
        store.upsertAsset_MockMethod = { [weak self] asset in
            if asset.nodeID == failedAsset.nodeID {
                throw CocoaError(.fileWriteUnknown)
            }
            self?.storeBacking[asset.nodeID] = asset
        }
        let nodeID = UUID()
        nodesAPI.getNodeNodeID_MockValue = .fixture(
            uuid: nodeID,
            downloadURL: URL(string: "https://wire.com")!
        )
        let (progress, continuation) = AsyncThrowingStream.makeStream(of: Double.self)
        continuation.finish()
        fileDownloader.downloadFrom_MockValue = (progress: progress, download: Task.fixture())

        let results = await sut.invoke(nodeIDs: [failedAsset.nodeID, cachedAsset.nodeID, nodeID])

        #expect(results.count == 3)
        let failedResult = try #require(results[failedAsset.nodeID])
        #expect(throws: CocoaError(.fileWriteUnknown)) {
            try failedResult.get()
        }
        try #require(results[cachedAsset.nodeID]).get()
        try #require(results[nodeID]).get()
        #expect(storeBacking[failedAsset.nodeID]?.isAvailableOffline == false)
        #expect(storeBacking[cachedAsset.nodeID]?.isAvailableOffline == true)
        #expect(storeBacking[nodeID]?.downloadState.cacheKey != nil)
    }

    @Test
    func `It returns individual results when one download fails`() async throws {
        let failedNodeID = UUID()
        let successfulNodeID = UUID()
        nodesAPI.getNodeNodeID_MockMethod = { nodeID in
            .fixture(
                uuid: nodeID,
                downloadURL: nodeID == failedNodeID ? nil : URL(string: "https://wire.com")!
            )
        }
        let (progress, continuation) = AsyncThrowingStream.makeStream(of: Double.self)
        continuation.finish()
        fileDownloader.downloadFrom_MockValue = (progress: progress, download: Task.fixture())

        let results = await sut.invoke(nodeIDs: [failedNodeID, successfulNodeID])

        #expect(results.count == 2)
        let failedResult = try #require(results[failedNodeID])
        #expect(throws: WireDriveLocalAssetRepositoryError.missingDownloadURL) {
            try failedResult.get()
        }
        try #require(results[successfulNodeID]).get()
        #expect(storeBacking[successfulNodeID]?.isAvailableOffline == true)
        #expect(storeBacking[successfulNodeID]?.downloadState.cacheKey != nil)
    }

    @Test
    func `It does nothing for an empty selection`() async throws {
        let results = await sut.invoke(nodeIDs: [])

        #expect(results.isEmpty)
        #expect(store.upsertAsset_Invocations.isEmpty)
        #expect(nodesAPI.getNodeNodeID_Invocations.isEmpty)
        #expect(fileDownloader.downloadFrom_Invocations.isEmpty)
    }

}
