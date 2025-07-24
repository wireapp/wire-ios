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
import Testing
import WireCellsAPI

@testable import WireCellsImplementation
@testable import WireCellsImplementationSupport

@MainActor
final class WireCellsLocalAssetRepositoryTests {

    private let nodesAPI = NodesAPIProtocolMock()
    private let fileDownloader = FileDownloadingMock()
    private let fileCache = FileCacheMock()
    private let store = WireCellsLocalAssetMetadataStoreMock()
    private let sut: WireCellsLocalAssetRepository

    init() {
        self.sut = WireCellsLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileDownloader: fileDownloader,
            fileCache: fileCache,
            store: store
        )
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
        let nodeID = UUID()
        let assetMetadata = WireCellsLocalAssetMetadata.fixture(isDownloaded: true)
        store.assetMetadataNodeIDUUIDWireCellsLocalAssetMetadataReturnValue = assetMetadata

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
        let nodeID = UUID()
        let assetMetadata = WireCellsLocalAssetMetadata.fixture(isDownloaded: false)
        store.assetMetadataNodeIDUUIDWireCellsLocalAssetMetadataReturnValue = assetMetadata

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

}

// MARK: - Helper Extensions

private extension Task where Success == (URL, URLResponse), Failure == any Error {

    static func fixture() -> Task {
        Task {
            (URL(string: "https://example.com/file")!, URLResponse())
        }
    }

}
