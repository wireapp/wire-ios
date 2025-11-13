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
import WireMessagingDomain

@testable import WireMessagingDomainSupport
@testable import WireMessagingUI

@MainActor
final class FilesViewModelTests {

    private let nodesRepository = MockWireCellsNodesRepositoryProtocol()
    private let localAssetRepository = MockWireCellsLocalAssetRepositoryProtocol()
    private let localAssetStore = MockWireCellsLocalAssetStoreProtocol()
    private let fileCache = MockFileCache()
    private let sut: FilesViewModel
    private var itemsUpdates: [[FilesViewItem]] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.sut = FilesViewModel(
            fetchNodesUseCase: WireCellsFetchNodesUseCase(
                configuration: .conversationFileView(root: .path("some-cell"), isFoldersEnabled: false),
                repository: nodesRepository
            ),
            deleteNodesUseCase: WireCellsDeleteNodesUseCase(
                repository: nodesRepository,
                fileCache: fileCache,
                localAssetStore: localAssetStore
            ),
            createFolderUseCase: WireCellsCreateFolderUseCase(
                nodesRepository: nodesRepository
            ),
            renameNodeUseCase: WireCellsRenameNodeUseCase(
                nodesRepository: MockWireCellsNodesRepositoryProtocol(),
                localAssetsRepository: MockWireCellsLocalAssetRepositoryProtocol(),
                nodeCache: MockWireCellsNodeCacheProtocol(),
                nodeRenameNotifier: WireCellsNodeRenameNotifier()
            ),
            isCellsStatePending: false,
            localAssetRepository: localAssetRepository,
            fileCache: fileCache,
            isFoldersEnabled: true
        )

        sut.$state.dropFirst().sink { [weak self] state in
            self?.itemsUpdates.append(state.items)
        }.store(in: &cancellables)
    }

    @Test
    func hasMore() async throws {
        // given
        nodesRepository.getNodes_MockMethod = { request in
            let page1 = (nodes: [WireCellsNode.fixture()], nextOffset: 1)
            let page2 = (nodes: [WireCellsNode.fixture()], nextOffset: Int?.none)
            return request.offset == 0 ? page1 : page2
        }
        #expect(sut.hasMore == true)

        // when
        await sut.reload()

        // then
        #expect(sut.hasMore == true)

        // when
        await sut.loadMoreIfNeeded(index: 0)

        // then
        #expect(sut.hasMore == false)
    }

    @Test
    func isLoading() async throws {
        // given
        nodesRepository.getNodes_MockMethod = { [sut] request in
            // Here we assert that loading is true when the methods under test are called.
            #expect(sut.isLoading == true)

            let page1 = (nodes: [WireCellsNode.fixture()], nextOffset: 1)
            let page2 = (nodes: [WireCellsNode.fixture()], nextOffset: Int?.none)
            return request.offset == 0 ? page1 : page2
        }
        #expect(sut.isLoading == false)

        // when
        await sut.reload()

        // then
        #expect(sut.isLoading == false)

        // when
        await sut.loadMoreIfNeeded(index: 0)

        // then
        #expect(sut.isLoading == false)
    }

    @Test
    func reload_clearsItemsBeforeLoading() async throws {
        // given
        let node = WireCellsNode.fixture(path: "some-cell/a.jpg", modified: nil, ownerUserName: nil)
        nodesRepository.getNodes_MockMethod = { _ in (nodes: [node], nextOffset: nil) }

        // when
        await sut.reload()
        await sut.reload()

        // then
        #expect(itemsUpdates == [
            [], // Clears items
            [FilesViewItem(
                id: node.id,
                kind: .file,
                name: "a.jpg",
                filePath: "some-cell/a.jpg",
                ownedBy: nil,
                modifiedAt: nil,
                icon: .other
            )],
            [], // Clears items
            [FilesViewItem(
                id: node.id,
                kind: .file,
                name: "a.jpg",
                filePath: "some-cell/a.jpg",
                ownedBy: nil,
                modifiedAt: nil,
                icon: .other
            )]
        ])
    }

    @Test
    func reload_alwaysLoadsFirstPage() async throws {
        // given
        nodesRepository.getNodes_MockMethod = { _ in
            (nodes: [WireCellsNode.fixture()], nextOffset: 1) // There is a new page available
        }

        await sut.reload()
        #expect(sut.hasMore == true)

        // when
        await sut.reload()

        // then
        #expect(nodesRepository.getNodes_Invocations.last?.offset == 0)
    }

    @Test
    func reload_updatesItems() async throws {
        // given
        let now = Date()
        let node1 = WireCellsNode.fixture(
            path: "some-cell/a.jpg",
            modified: now,
            mimeType: "image/jpeg",
            ownerUserName: "Emel"
        )
        let node2 = WireCellsNode.fixture(path: "some-cell/b.jpg", modified: nil, ownerUserName: nil)
        nodesRepository.getNodes_MockMethod = { _ in (nodes: [node1, node2], nextOffset: nil) }

        // when
        await sut.reload()

        // then
        #expect(sut.state.items == [
            FilesViewItem(
                id: node1.id,
                kind: .file,
                name: "a.jpg",
                filePath: "some-cell/a.jpg",
                ownedBy: "Emel",
                modifiedAt: now,
                icon: .image
            ),
            FilesViewItem(
                id: node2.id,
                kind: .file,
                name: "b.jpg",
                filePath: "some-cell/b.jpg",
                ownedBy: nil,
                modifiedAt: nil,
                icon: .other
            )
        ])
    }

    @Test
    func loadMoreIfNeeded_appendsItems() async throws {
        // given
        let now = Date()
        let node1 = WireCellsNode.fixture(path: "some-cell/a.jpg", modified: now, ownerUserName: "Emel")
        let node2 = WireCellsNode.fixture(path: "some-cell/b.jpg", modified: now - 60, ownerUserName: nil)
        let node3 = WireCellsNode.fixture(path: "some-cell/c.jpg", modified: nil, ownerUserName: nil)
        nodesRepository.getNodes_MockMethod = { request in
            switch request.offset {
            case 0:
                (nodes: [node1], nextOffset: 1)
            case 1:
                (nodes: [node2], nextOffset: 2)
            default:
                (nodes: [node3], nextOffset: nil)
            }
        }

        // when
        await sut.reload()
        await sut.loadMoreIfNeeded(index: 0) // Index doesn't related to pagination
        await sut.loadMoreIfNeeded(index: 0) // Index doesn't related to pagination

        // then
        #expect(sut.state.items == [
            FilesViewItem(
                id: node1.id,
                kind: .file,
                name: "a.jpg",
                filePath: "some-cell/a.jpg",
                ownedBy: "Emel",
                modifiedAt: now,
                icon: .other
            ),
            FilesViewItem(
                id: node2.id,
                kind: .file,
                name: "b.jpg",
                filePath: "some-cell/b.jpg",
                ownedBy: nil,
                modifiedAt: now - 60,
                icon: .other
            ),
            FilesViewItem(
                id: node3.id,
                kind: .file,
                name: "c.jpg",
                filePath: "some-cell/c.jpg",
                ownedBy: nil,
                modifiedAt: nil,
                icon: .other
            )
        ])
    }

    @Test
    func loadMoreIfNeeded_doesNothingWhenNoMoreToLoad() async throws {
        // given
        nodesRepository.getNodes_MockMethod = { _ in
            (nodes: [WireCellsNode.fixture()], nextOffset: nil) // No more pages available
        }
        await sut.reload()
        #expect(sut.state.items.count == 1)
        itemsUpdates = [] // Reset updates to track only the next ones

        // when
        await sut.loadMoreIfNeeded(index: 0) // Index doesn't related to pagination

        // then
        #expect(itemsUpdates.isEmpty)
    }

    @Test
    func loadMoreIfNeeded_respectsThreshold() async throws {
        // given
        let nodes = (0 ..< 10).map { i in
            WireCellsNode.fixture(path: "some-cell/\(i).jpg", modified: nil, ownerUserName: nil)
        }
        nodesRepository.getNodes_MockMethod = { _ in (nodes: nodes, nextOffset: 10) }

        await sut.reload()
        #expect(sut.state.items.count == 10)
        nodesRepository.getNodes_Invocations.removeAll() // Reset invocations to track only the next ones

        // when
        await sut.loadMoreIfNeeded(index: 4) // index is not one of the last 5 rows

        // then
        #expect(nodesRepository.getNodes_Invocations.isEmpty)

        // when
        await sut.loadMoreIfNeeded(index: 5) // index is one of the last 5 rows

        // then
        #expect(nodesRepository.getNodes_Invocations.count == 1)
    }

    @Test
    func loadMoreIfNeeded_discardsConcurrentRequests() async throws {
        // given
        nodesRepository.getNodes_MockMethod = { request in
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            return (nodes: [WireCellsNode.fixture()], nextOffset: request.offset + 1)
        }
        await sut.reload()
        #expect(sut.state.items.count == 1)
        nodesRepository.getNodes_Invocations.removeAll() // Reset invocations to track only the next ones

        // when
        let task1 = Task { await sut.loadMoreIfNeeded(index: 0) }
        let task2 = Task { await sut.loadMoreIfNeeded(index: 0) }

        // Wait for both tasks to complete
        await task1.value
        await task2.value

        // then
        #expect(nodesRepository.getNodes_Invocations.count == 1)
        #expect(sut.state.items.count == 2)
    }

    @Test(arguments: [
        (error: URLError(.notConnectedToInternet), expectedAlert: AlertModel.noInternet),
        (error: URLError(.networkConnectionLost), expectedAlert: AlertModel.noInternet),
        (error: URLError(.badURL), expectedAlert: AlertModel.unknownError)
    ])
    func loadFailure(error: any Error, expectedAlert: AlertModel) async {
        // given
        nodesRepository.getNodes_MockError = error

        // when
        await sut.reload()

        // then
        #expect(sut.state == .error)
        #expect(sut.isLoading == false)
    }

    @Test
    func itemsFilteredCorrectly() async throws {
        // This is not a real scenario but tests that the logic for removing duplicates is correct.
        // It _is_ possible for different versions of the same node to appear across different pages. We need to ensure
        // that there is only ever one version of a node in the list.

        // given
        let now = Date()
        let nodeA = WireCellsNode.fixture(path: "foo/aa.xyz")
        let nodeB = WireCellsNode.fixture(path: "foo/bb.xyz")
        let nodeC = WireCellsNode.fixture(path: "foo/cc.xyz")
        let nodeD = WireCellsNode.fixture(path: "foo/dd.xyz")
        let nodeA_V2 = WireCellsNode.fixture(uuid: nodeA.id, path: "foo/aaa.xyz", modified: now)
        let nodeD_V2 = WireCellsNode.fixture(uuid: nodeD.id, path: "foo/ccc.xyz")

        nodesRepository.getNodes_MockValue = (
            nodes: [nodeA, nodeB, nodeC, nodeD, nodeA_V2, nodeD_V2],
            nextOffset: nil
        )

        // when
        await sut.reload()

        // then
        #expect(
            sut.state.items == [
                FilesViewItem(
                    id: nodeB.id,
                    kind: .file,
                    name: "bb.xyz",
                    filePath: "foo/bb.xyz",
                    ownedBy: nil,
                    modifiedAt: nil,
                    icon: .other
                ),
                FilesViewItem(
                    id: nodeC.id,
                    kind: .file,
                    name: "cc.xyz",
                    filePath: "foo/cc.xyz",
                    ownedBy: nil,
                    modifiedAt: nil,
                    icon: .other
                ),
                FilesViewItem(
                    id: nodeD.id,
                    kind: .file,
                    name: "dd.xyz",
                    filePath: "foo/dd.xyz",
                    ownedBy: nil,
                    modifiedAt: nil,
                    icon: .other
                ),
                FilesViewItem(
                    id: nodeA.id,
                    kind: .file,
                    name: "aaa.xyz",
                    filePath: "foo/aaa.xyz",
                    ownedBy: nil,
                    modifiedAt: now,
                    icon: .other
                )
            ]
        )
    }

    // MARK: - openItem

    @Test
    func openItem_whenFileAlreadyDownloaded() async throws {
        // given
        let nodeID = UUID()
        localAssetRepository.assetNodeID_MockValue = WireCellsLocalAsset.fixture(
            downloadState: .downloaded(cacheKey: "some-key")
        )
        fileCache.fileURLForKey_MockValue = URL(fileURLWithPath: "/foo")

        // when
        await sut.openItem(item: .fixture(id: nodeID))

        // then
        #expect(fileCache.fileURLForKey_Invocations == ["some-key"])
        #expect(sut.viewingURL == URL(fileURLWithPath: "/foo"))
    }

    @Test
    func openItem_whenFileNeedsDownloaded() async throws {
        // given
        var assets: [UUID: WireCellsLocalAsset] = [:]
        let nodeID = UUID()
        localAssetRepository.assetNodeID_MockMethod = { nodeID in
            assets[nodeID]
        }
        localAssetRepository.downloadAssetNodeID_MockMethod = { nodeID in
            assets[nodeID] = WireCellsLocalAsset.fixture(downloadState: .downloaded(cacheKey: "some-key"))
        }
        fileCache.fileURLForKey_MockValue = URL(fileURLWithPath: "/foo")

        // when
        await sut.openItem(item: .fixture(id: nodeID))

        // then
        #expect(fileCache.fileURLForKey_Invocations == ["some-key"])
        #expect(sut.viewingURL == URL(fileURLWithPath: "/foo"))
    }

    @Test
    func openItem_whenFileAlreadyDownloading() async throws {
        // given
        var assets: [UUID: WireCellsLocalAsset] = [:]
        let nodeID = UUID()
        localAssetRepository.assetNodeID_MockMethod = { nodeID in
            assets[nodeID]
        }
        localAssetRepository
            .downloadAssetNodeID_MockError = WireCellsLocalAssetRepositoryError.downloadAlreadyInProgress

        localAssetRepository.observeAssetNodeID_MockMethod = { nodeID in
            let asset = WireCellsLocalAsset.fixture(downloadState: .downloaded(cacheKey: "some-key"))
            assets[nodeID] = asset
            return [asset].publisher.eraseToAnyPublisher()
        }

        fileCache.fileURLForKey_MockValue = URL(fileURLWithPath: "/foo")

        // when
        await sut.openItem(item: .fixture(id: nodeID))

        // then
        #expect(fileCache.fileURLForKey_Invocations == ["some-key"])
        #expect(sut.viewingURL == URL(fileURLWithPath: "/foo"))
    }

    @Test(arguments: [
        (error: URLError(.notConnectedToInternet), expectedAlert: AlertModel.noInternet),
        (error: URLError(.networkConnectionLost), expectedAlert: AlertModel.noInternet),
        (error: URLError(.badURL), expectedAlert: AlertModel.unknownError)
    ])
    func openItem_triggersAlertOnFailure(error: any Error, expectedAlert: AlertModel) async {
        // given
        localAssetRepository.assetNodeID_MockError = error

        // when
        await sut.openItem(item: .fixture())

        // then
        #expect(sut.alert == expectedAlert)
    }

}
