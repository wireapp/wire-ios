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

import Combine
import Foundation
import Testing
import WireMessagingDomain

@testable import WireMessagingData
@testable import WireMessagingDomainSupport

@MainActor
final class WireDriveLocalAssetRepositoryTests {

    private let nodeID = UUID()
    private let nodesAPI = MockNodesAPIProtocol()
    private let fileDownloader = MockFileDownloading()
    private let fileCache = MockFileCache()
    private let store = MockWireDriveLocalAssetStoreProtocol()
    private var storeBacking: [UUID: WireDriveLocalAsset] = [:]
    private let sut: WireDriveLocalAssetRepository
    private var cancellables = Set<AnyCancellable>()
    private let wireDriveConversation = WireDriveConversation(
        id: UUID().uuidString,
        name: "Conversation 1",
        participants: []
    )

    init() {
        self.sut = WireDriveLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileDownloader: fileDownloader,
            fileCache: fileCache,
            store: store
        )

        // Mock requires methods set to avoid fatal error :/
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
    func asset_whenNoAssetInStore() throws {
        // given
        storeBacking[nodeID] = nil

        // when
        let asset = try sut.asset(nodeID: nodeID)

        // then
        #expect(asset == nil)
    }

    @Test
    func asset_whenAssetInStore() throws {
        // given
        try store.upsertAsset(WireDriveLocalAsset.fixture(nodeID: nodeID))

        // when
        let asset = try sut.asset(nodeID: nodeID)

        // then
        #expect(asset == asset)
    }

    @Test
    func refreshMetadata_success_whenNoStoredAsset() async throws {
        // given
        storeBacking[nodeID] = nil

        let node = WireDriveNode.fixture(
            uuid: nodeID,
            conversation: wireDriveConversation,
            path: "path/file.png",
            size: 1234,
            eTag: "abc",
            mimeType: "image/png",
            ownerUserName: "User 1",
            downloadURL: URL(string: "https://example.com/file.png")!
        )
        nodesAPI.getNodeNodeID_MockValue = node

        // when
        _ = try await sut.refreshAssetMetadata(nodeID: nodeID)

        // then the store is updated with the new metadata
        let expectedAsset = WireDriveLocalAsset(
            nodeID: nodeID,
            eTag: "abc",
            path: "path/file.png",
            contentType: "image/png",
            size: 1234,
            conversationName: "Conversation 1",
            ownerName: "User 1",
            modified: nil,
            isAvailableOffline: false,
            downloadState: .pending
        )

        #expect(
            try store.asset(nodeID: nodeID) == expectedAsset
        )

        // then no files are deleted
        #expect(fileCache.deleteFileForKey_Invocations.isEmpty)

        // then one asset change is observed
        try #require(store.upsertAsset_Invocations.count == 1)
        #expect(
            store.upsertAsset_Invocations.first == expectedAsset
        )
    }

    @Test
    func refreshMetadata_success_whenOutOfDateExistingMetadata() async throws {
        // given
        storeBacking[nodeID] = WireDriveLocalAsset(
            nodeID: nodeID,
            eTag: "def", // eTag is out of date
            path: "path/file.png",
            contentType: "image/png",
            size: 1234,
            conversationName: "Conversation 1",
            ownerName: "User 1",
            modified: nil,
            isAvailableOffline: false,
            downloadState: .downloaded(cacheKey: "some-cache-key")
        )

        nodesAPI.getNodeNodeID_MockValue = WireDriveNode.fixture(
            uuid: nodeID,
            path: "path/file.png",
            size: 1234,
            eTag: "abc",
            mimeType: "image/png",
            downloadURL: URL(string: "https://example.com/file.png")!
        )

        // when
        _ = try await sut.refreshAssetMetadata(nodeID: nodeID)

        // then the store is updated with the new metadata
        #expect(
            try store.asset(nodeID: nodeID) == WireDriveLocalAsset(
                nodeID: nodeID,
                eTag: "abc",
                path: "path/file.png",
                contentType: "image/png",
                size: 1234,
                conversationName: "Conversation 1",
                ownerName: "User 1",
                modified: nil,
                isAvailableOffline: false,
                downloadState: .pending
            )
        )

        // then old files are deleted
        #expect(fileCache.deleteFileForKey_Invocations == ["some-cache-key"])

        // then one asset change is observed
        try #require(store.upsertAsset_Invocations.count == 1)
        #expect(
            store.upsertAsset_Invocations.first == WireDriveLocalAsset(
                nodeID: nodeID,
                eTag: "abc",
                path: "path/file.png",
                contentType: "image/png",
                size: 1234,
                conversationName: "Conversation 1",
                ownerName: "User 1",
                modified: nil,
                isAvailableOffline: false,
                downloadState: .pending,
            )
        )
    }

    @Test
    func downloadAsset_whenSuccess() async throws {
        // given
        storeBacking[nodeID] = nil

        let node = WireDriveNode.fixture(
            uuid: nodeID,
            conversation: wireDriveConversation,
            path: "path/file.png",
            size: 1234,
            eTag: "abc",
            mimeType: "image/png",
            ownerUserName: "User 1",
            downloadURL: URL(string: "https://example.com/file.png")!
        )
        nodesAPI.getNodeNodeID_MockValue = node

        let (progressStream, progressContinuation) = AsyncThrowingStream.makeStream(of: Double.self)
        fileDownloader.downloadFrom_MockValue = (progress: progressStream, download: Task.fixture())

        Task {
            progressContinuation.yield(0.5)
            progressContinuation.yield(1)
            progressContinuation.finish()
        }

        // when
        try await sut.downloadAsset(nodeID: nodeID, isAvailableOffline: false)

        // then
        #expect(
            try store.asset(nodeID: nodeID) == WireDriveLocalAsset(
                nodeID: nodeID,
                eTag: "abc",
                path: "path/file.png",
                contentType: "image/png",
                size: 1234,
                conversationName: "Conversation 1",
                ownerName: "User 1",
                modified: nil,
                isAvailableOffline: false,
                downloadState: .downloaded(cacheKey: "\(nodeID.uuidString)-abc/file.png")
            )
        )

        #expect(
            store.upsertAsset_Invocations == [
                WireDriveLocalAsset(
                    nodeID: nodeID,
                    eTag: "abc",
                    path: "path/file.png",
                    contentType: "image/png",
                    size: 1234,
                    conversationName: "Conversation 1",
                    ownerName: "User 1",
                    modified: nil,
                    isAvailableOffline: false,
                    downloadState: .pending,
                ),
                WireDriveLocalAsset(
                    nodeID: nodeID,
                    eTag: "abc",
                    path: "path/file.png",
                    contentType: "image/png",
                    size: 1234,
                    conversationName: "Conversation 1",
                    ownerName: "User 1",
                    modified: nil,
                    isAvailableOffline: false,
                    downloadState: .downloading(progress: 0.5)
                ),
                WireDriveLocalAsset(
                    nodeID: nodeID,
                    eTag: "abc",
                    path: "path/file.png",
                    contentType: "image/png",
                    size: 1234,
                    conversationName: "Conversation 1",
                    ownerName: "User 1",
                    modified: nil,
                    isAvailableOffline: false,
                    downloadState: .downloading(progress: 1.0)
                ),
                WireDriveLocalAsset(
                    nodeID: nodeID,
                    eTag: "abc",
                    path: "path/file.png",
                    contentType: "image/png",
                    size: 1234,
                    conversationName: "Conversation 1",
                    ownerName: "User 1",
                    modified: nil,
                    isAvailableOffline: false,
                    downloadState: .downloaded(cacheKey: "\(nodeID.uuidString)-abc/file.png")
                )
            ]
        )
    }

    @Test
    func downloadAsset_withoutFileExtension() async throws {
        // given
        storeBacking[nodeID] = nil

        let node = WireDriveNode.fixture(
            uuid: nodeID,
            conversation: wireDriveConversation,
            path: "path/fileWithoutExtension",
            size: 1234,
            eTag: "abc",
            mimeType: "image/png",
            ownerUserName: "User 1",
            downloadURL: URL(string: "https://example.com/fileWithoutExtension")!
        )
        nodesAPI.getNodeNodeID_MockValue = node

        let (progressStream, progressContinuation) = AsyncThrowingStream.makeStream(of: Double.self)
        fileDownloader.downloadFrom_MockValue = (progress: progressStream, download: Task.fixture())

        Task {
            progressContinuation.yield(0.5)
            progressContinuation.yield(1)
            progressContinuation.finish()
        }

        // when
        try await sut.downloadAsset(nodeID: nodeID, isAvailableOffline: false)

        // then
        func expectedAsset(downloadState: WireDriveLocalAsset.DownloadState) -> WireDriveLocalAsset {
            WireDriveLocalAsset(
                nodeID: nodeID,
                eTag: "abc",
                path: "path/fileWithoutExtension",
                contentType: "image/png",
                size: 1234,
                conversationName: "Conversation 1",
                ownerName: "User 1",
                modified: nil,
                isAvailableOffline: false,
                downloadState: downloadState,
            )
        }

        #expect(
            try store
                .asset(nodeID: nodeID) ==
                expectedAsset(downloadState: .downloaded(cacheKey: "\(nodeID.uuidString)-abc/fileWithoutExtension"))
        )

        #expect(
            store.upsertAsset_Invocations == [
                expectedAsset(downloadState: .pending),
                expectedAsset(downloadState: .downloading(progress: 0.5)),
                expectedAsset(downloadState: .downloading(progress: 1)),
                expectedAsset(downloadState: .downloaded(cacheKey: "\(nodeID.uuidString)-abc/fileWithoutExtension"))
            ]
        )
    }

    @Test
    func downloadAsset_whenDownloadInProgress() async throws {
        // given
        storeBacking[nodeID] = nil

        let node = WireDriveNode.fixture(
            uuid: nodeID,
            conversation: wireDriveConversation,
            path: "path/file.png",
            size: 1234,
            eTag: "abc",
            mimeType: "image/png",
            ownerUserName: "User 1",
            downloadURL: URL(string: "https://example.com/file.png")!
        )
        nodesAPI.getNodeNodeID_MockValue = node

        let (progressStream, progressContinuation) = AsyncThrowingStream.makeStream(of: Double.self)
        fileDownloader.downloadFrom_MockValue = (progress: progressStream, download: Task.fixture())

        Task {
            progressContinuation.yield(0.5)
            progressContinuation.yield(1)
            progressContinuation.finish()
        }

        // when downloading multiple times concurrently
        let assets = try await withThrowingTaskGroup(
            of: WireDriveLocalAsset?.self,
            returning: [WireDriveLocalAsset].self
        ) { [nodeID, sut, store] taskGroup in
            for _ in 1 ... 3 {
                taskGroup.addTask {
                    try await sut.downloadAsset(nodeID: nodeID, isAvailableOffline: false)
                    return try await store.asset(nodeID: nodeID)
                }
            }

            var results = [WireDriveLocalAsset]()
            for try await result in taskGroup {
                if let result {
                    results.append(result)
                }
            }

            return results
        }

        // then
        #expect(assets.count == 3)

        func expectedAsset(downloadState: WireDriveLocalAsset.DownloadState) -> WireDriveLocalAsset {
            WireDriveLocalAsset(
                nodeID: nodeID,
                eTag: "abc",
                path: "path/file.png",
                contentType: "image/png",
                size: 1234,
                conversationName: "Conversation 1",
                ownerName: "User 1",
                modified: nil,
                isAvailableOffline: false,
                downloadState: downloadState,
            )
        }

        #expect(
            try assets.allSatisfy { asset in
                asset == expectedAsset(downloadState: .downloaded(cacheKey: "\(nodeID.uuidString)-abc/file.png"))
            }
        )

        #expect(
            store.upsertAsset_Invocations == [
                expectedAsset(downloadState: .pending),
                expectedAsset(downloadState: .downloading(progress: 0.5)),
                expectedAsset(downloadState: .downloading(progress: 1)),
                expectedAsset(downloadState: .downloaded(cacheKey: "\(nodeID.uuidString)-abc/file.png"))
            ]
        )
    }

}
