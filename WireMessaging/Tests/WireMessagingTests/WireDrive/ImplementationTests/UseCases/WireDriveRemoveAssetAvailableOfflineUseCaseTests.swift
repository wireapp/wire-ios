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
    private let fileDownloader = MockFileDownloading()
    private let fileCache = MockFileCache()
    private let store = MockWireDriveLocalAssetStoreProtocol()
    private var storeBacking: [UUID: WireDriveLocalAsset] = [:]
    private let sut: WireDriveRemoveAssetAvailableOfflineUseCase

    init() {
        self.localAssetRepository = WireDriveLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileDownloader: fileDownloader,
            fileCache: fileCache,
            store: store
        )

        self.sut = WireDriveRemoveAssetAvailableOfflineUseCase(
            localAssetRepository: localAssetRepository,
        )

        store.assetNodeID_MockMethod = { [weak self] nodeID in
            self?.storeBacking[nodeID]
        }
        store.upsertAssetAsync_MockMethod = { [weak self] asset in
            self?.storeBacking[asset.nodeID] = asset
        }
        store.upsertAsset_MockMethod = { [weak self] asset in
            self?.storeBacking[asset.nodeID] = asset
        }
        store.deleteAssetsNodeIDs_MockMethod = { [weak self] nodeIDs in
            for nodeID in nodeIDs {
                self?.storeBacking[nodeID] = nil
            }
        }

        fileCache.deleteFileForKey_MockMethod = { _ in
            // do nothing
        }
        fileCache.saveFileAtKey_MockMethod = { _, _ in }
    }

    @Test
    func removeOfflineAccess_whenDownloaded_deletesAssetAndCachedFile() async throws {
        let asset = WireDriveLocalAsset.fixture(
            isAvailableOffline: true,
            downloadState: .downloaded(cacheKey: "offline-file")
        )
        storeBacking[asset.nodeID] = asset

        try await sut.invoke(nodeID: asset.nodeID)

        #expect(storeBacking[asset.nodeID] == nil)
        #expect(fileCache.deleteFileForKey_Invocations == ["offline-file"])
    }

    @Test
    func removeOfflineAccess_whenPending_deletesOfflineIntentWithoutCachedFile() async throws {
        let asset = WireDriveLocalAsset.fixture(isAvailableOffline: true, downloadState: .pending)
        storeBacking[asset.nodeID] = asset

        try await sut.invoke(nodeID: asset.nodeID)

        #expect(storeBacking[asset.nodeID] == nil)
        #expect(fileCache.deleteFileForKey_Invocations.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)), arguments: [false, true])
    func removeOfflineAccess_whenDownloading_cancelsBeforeDeletingAsset(progressFinished: Bool) async throws {
        let downloadedAsset = WireDriveLocalAsset.fixture(
            isAvailableOffline: true,
            downloadState: .downloaded(cacheKey: "finished-offline-file")
        )
        storeBacking[downloadedAsset.nodeID] = downloadedAsset
        let nodeID = UUID()
        nodesAPI.getNodeNodeID_MockValue = .fixture(
            uuid: nodeID,
            downloadURL: URL(string: "https://example.com/offline-file")!
        )
        let (progress, progressContinuation) = AsyncThrowingStream.makeStream(of: Double.self)
        if progressFinished {
            progressContinuation.finish()
        } else {
            progressContinuation.yield(0.5)
        }
        defer { progressContinuation.finish() }

        let (started, startedContinuation) = AsyncStream.makeStream(of: Void.self)
        defer { startedContinuation.finish() }
        var startedIterator = started.makeAsyncIterator()
        let (completion, completionContinuation) = AsyncStream.makeStream(of: Void.self)
        defer { completionContinuation.finish() }
        var networkTask: Task<(URL, URLResponse), any Error>?
        fileDownloader.downloadFrom_MockMethod = { _ in
            let task = Task { @MainActor in
                startedContinuation.yield(())
                var iterator = completion.makeAsyncIterator()
                _ = await iterator.next()
                try Task.checkCancellation()
                return (URL(fileURLWithPath: "/tmp/offline-file"), URLResponse())
            }
            networkTask = task
            return (progress: progress, download: task)
        }
        defer { networkTask?.cancel() }

        let downloadTask = Task {
            try await localAssetRepository.downloadAsset(nodeID: nodeID, isAvailableOffline: true)
        }
        defer { downloadTask.cancel() }
        _ = await startedIterator.next()
        #expect(storeBacking[nodeID]?.isAvailableOffline == true)

        try await sut.invoke(nodeID: downloadedAsset.nodeID)
        try await sut.invoke(nodeID: nodeID)

        let result = await downloadTask.result
        #expect(throws: CancellationError.self) { try result.get() }
        #expect(networkTask?.isCancelled == true)
        #expect(storeBacking[downloadedAsset.nodeID] == nil)
        #expect(storeBacking[nodeID] == nil)
        #expect(store.deleteAssetsNodeIDs_Invocations == [[downloadedAsset.nodeID], [nodeID]])
        #expect(fileCache.deleteFileForKey_Invocations == ["finished-offline-file"])
        #expect(fileCache.saveFileAtKey_Invocations.isEmpty)

        // Late progress or a late download completion must not restore offline access.
        progressContinuation.yield(1)
        completionContinuation.yield(())
        #expect(storeBacking[nodeID] == nil)
    }

}
