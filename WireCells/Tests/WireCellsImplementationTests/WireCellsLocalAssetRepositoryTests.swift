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

import Combine
import Foundation
import Testing
import WireCellsAPI

@testable import WireCellsImplementation
@testable import WireCellsImplementationSupport

@MainActor
final class WireCellsLocalAssetRepositoryTests {

    private let nodeID = UUID()
    private let nodesAPI = NodesAPIProtocolMock()
    private let fileDownloader = FileDownloadingMock()
    private let fileCache = FileCacheMock()
    private let store = WireCellsLocalAssetMetadataStoreMock()
    private let sut: WireCellsLocalAssetRepository
    private var storeBacking: [UUID: WireCellsLocalAssetMetadata] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var observedAssets: [WireCellsLocalAsset?] = []

    init() {
        self.sut = WireCellsLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileDownloader: fileDownloader,
            fileCache: fileCache,
            store: store
        )
        store.assetMetadataNodeIDUUIDWireCellsLocalAssetMetadataClosure = { [weak self] nodeID in
            self?.storeBacking[nodeID]
        }
        store.upsertAssetMetadataMetadataWireCellsLocalAssetMetadataVoidClosure = { [weak self] metadata in
            self?.storeBacking[metadata.nodeID] = metadata
        }
        sut.observeAsset(nodeID: nodeID).sink { [weak self] asset in
            self?.observedAssets.append(asset)
        }.store(in: &cancellables)
    }

    @Test
    func asset_whenNoMetadataInStore() throws {
        // given
        store.assetMetadataNodeIDUUIDWireCellsLocalAssetMetadataReturnValue = nil

        #expect(try sut.asset(nodeID: UUID()) == nil)
    }

    @Test(arguments: [WireCellsLocalAssetRepository.DownloadState?]([
        nil,
        .downloading(progress: 0.5, task: .fixture()),
        .error(error: URLError(.badURL))
    ]))
    func asset_whenFileDownloaded(downloadState: WireCellsLocalAssetRepository.DownloadState?) throws {
        // given
        let assetMetadata = WireCellsLocalAssetMetadata.fixture(isDownloaded: true)
        storeBacking[nodeID] = assetMetadata

        var downloadStates: [UUID: WireCellsLocalAssetRepository.DownloadState] = [:]
        downloadStates[nodeID] = downloadState
        let sut = WireCellsLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileDownloader: fileDownloader,
            fileCache: fileCache,
            store: store,
            downloadStates: downloadStates
        )

        // when
        let asset = try sut.asset(nodeID: nodeID)

        // then
        #expect(
            asset == WireCellsLocalAsset(
                nodeID: assetMetadata.nodeID,
                eTag: assetMetadata.eTag,
                path: assetMetadata.path,
                contentType: assetMetadata.contentType,
                size: assetMetadata.size,
                downloadState: .downloaded(cacheKey: assetMetadata.cacheKey),
            )
        )
    }

    @Test(arguments: [(WireCellsLocalAssetRepository.DownloadState?, WireCellsLocalAsset.DownloadState)]([
        (nil, .pending),
        (.downloading(progress: 0.5, task: .fixture()), .downloading(progress: 0.5)),
        (.error(error: URLError(.badURL)), .failed(error: URLError(.badURL)))
    ]))
    func asset_whenFileNotDownloaded(
        inputDownloadState: WireCellsLocalAssetRepository.DownloadState?,
        expectedDownloadState: WireCellsLocalAsset.DownloadState
    ) throws {
        // given
        let assetMetadata = WireCellsLocalAssetMetadata.fixture(isDownloaded: false)
        storeBacking[nodeID] = assetMetadata

        var downloadStates: [UUID: WireCellsLocalAssetRepository.DownloadState] = [:]
        downloadStates[nodeID] = inputDownloadState
        let sut = WireCellsLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileDownloader: fileDownloader,
            fileCache: fileCache,
            store: store,
            downloadStates: downloadStates
        )

        // when
        let asset = try sut.asset(nodeID: nodeID)

        // then
        #expect(
            asset == WireCellsLocalAsset(
                nodeID: assetMetadata.nodeID,
                eTag: assetMetadata.eTag,
                path: assetMetadata.path,
                contentType: assetMetadata.contentType,
                size: assetMetadata.size,
                downloadState: expectedDownloadState,
            )
        )
    }

    @Test
    func refreshMetadata_success_whenNoExistingMetadata() async throws {
        // given
        storeBacking[nodeID] = nil

        let node = WireCellsNode.fixture(
            uuid: nodeID,
            path: "path/file.png",
            size: 1234,
            eTag: "abc",
            mimeType: "image/png",
            downloadURL: URL(string: "https://example.com/file.png")!
        )
        nodesAPI.getNodeNodeIDUUIDWireCellsNodeReturnValue = node

        // when
        let metadata = try await sut.refreshMetadata(nodeID: nodeID)

        // then the returned metadata is correct
        #expect(
            metadata == WireCellsLocalAssetMetadata(
                nodeID: nodeID,
                eTag: "abc",
                path: "path/file.png",
                contentType: "image/png",
                size: 1234,
                isDownloaded: false
            )
        )

        // then the store is updated with the new metadata
        #expect(storeBacking[nodeID] == metadata)

        // then no files are deleted
        #expect(fileCache.deleteFileForKeyKeyStringVoidCalled == false)

        // then one asset change is observed
        try #require(observedAssets.count == 1)
        #expect(
            observedAssets.first == WireCellsLocalAsset(
                nodeID: nodeID,
                eTag: "abc",
                path: "path/file.png",
                contentType: "image/png",
                size: 1234,
                downloadState: .pending,
            )
        )
    }

    @Test
    func refreshMetadata_success_whenOutOfDateExistingMetadata() async throws {
        // given
        storeBacking[nodeID] = WireCellsLocalAssetMetadata(
            nodeID: nodeID,
            eTag: "def", // eTag is out of date
            path: "path/file.png",
            contentType: "image/png",
            size: 1234,
            isDownloaded: true
        )

        nodesAPI.getNodeNodeIDUUIDWireCellsNodeReturnValue = WireCellsNode.fixture(
            uuid: nodeID,
            path: "path/file.png",
            size: 1234,
            eTag: "abc",
            mimeType: "image/png",
            downloadURL: URL(string: "https://example.com/file.png")!
        )

        // when
        let metadata = try await sut.refreshMetadata(nodeID: nodeID)

        // then the returned metadata is correct
        #expect(
            metadata == WireCellsLocalAssetMetadata(
                nodeID: nodeID,
                eTag: "abc",
                path: "path/file.png",
                contentType: "image/png",
                size: 1234,
                isDownloaded: false
            )
        )

        // then the store is updated with the new metadata
        #expect(storeBacking[nodeID] == metadata)

        // then old files are deleted
        #expect(fileCache.deleteFileForKeyKeyStringVoidReceivedInvocations == ["\(nodeID.uuidString)-def"])

        // then one asset change is observed
        try #require(observedAssets.count == 1)
        #expect(
            observedAssets.first == WireCellsLocalAsset(
                nodeID: nodeID,
                eTag: "abc",
                path: "path/file.png",
                contentType: "image/png",
                size: 1234,
                downloadState: .pending,
            )
        )
    }

    @Test
    func downloadAsset_whenDownloadInProgress() async throws {
        // given
        let sut = WireCellsLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileDownloader: fileDownloader,
            fileCache: fileCache,
            store: store,
            downloadStates: [nodeID: .downloading(progress: 0.5, task: Task.fixture())]
        )

        // when, then

        let nodeID = nodeID // Necessary for the macro compiler :(
        await #expect(throws: WireCellsLocalAssetRepositoryError.downloadAlreadyInProgress) {
            _ = try await sut.downloadAsset(nodeID: nodeID)
        }
    }

    @Test
    func downloadAsset_whenSuccess() async throws {
        // given
        storeBacking[nodeID] = nil

        let node = WireCellsNode.fixture(
            uuid: nodeID,
            path: "path/file.png",
            size: 1234,
            eTag: "abc",
            mimeType: "image/png",
            downloadURL: URL(string: "https://example.com/file.png")!
        )
        nodesAPI.getNodeNodeIDUUIDWireCellsNodeReturnValue = node

        let (progressStream, progressContinuation) = AsyncStream.makeStream(of: Double.self)
        fileDownloader.downloadFromUrlURL_ProgressAsyncStreamDoubleDownloadTaskURLURLResponseAnyErrorReturnValue =
            (progress: progressStream, download: Task.fixture())

        Task {
            progressContinuation.yield(0.5)
            progressContinuation.yield(1)
            progressContinuation.finish()
        }

        // when
        try await sut.downloadAsset(nodeID: nodeID)

        // then
        #expect(
            storeBacking[nodeID] == WireCellsLocalAssetMetadata(
                nodeID: nodeID,
                eTag: "abc",
                path: "path/file.png",
                contentType: "image/png",
                size: 1234,
                isDownloaded: true
            )
        )

        #expect(
            observedAssets == [
                WireCellsLocalAsset(
                    nodeID: nodeID,
                    eTag: "abc",
                    path: "path/file.png",
                    contentType: "image/png",
                    size: 1234,
                    downloadState: .pending,
                ),
                WireCellsLocalAsset(
                    nodeID: nodeID,
                    eTag: "abc",
                    path: "path/file.png",
                    contentType: "image/png",
                    size: 1234,
                    downloadState: .downloading(progress: 0.5)
                ),
                WireCellsLocalAsset(
                    nodeID: nodeID,
                    eTag: "abc",
                    path: "path/file.png",
                    contentType: "image/png",
                    size: 1234,
                    downloadState: .downloading(progress: 1.0)
                ),
                WireCellsLocalAsset(
                    nodeID: nodeID,
                    eTag: "abc",
                    path: "path/file.png",
                    contentType: "image/png",
                    size: 1234,
                    downloadState: .downloaded(cacheKey: "\(nodeID.uuidString)-abc")
                )
            ]
        )
    }
}

// MARK: - Helper Extensions

private extension Task where Success == (URL, URLResponse), Failure == any Error {

    static func fixture() -> Task {
        Task {
            (URL(string: "https://example.com/file")!, URLResponse())
        }
    }

}
