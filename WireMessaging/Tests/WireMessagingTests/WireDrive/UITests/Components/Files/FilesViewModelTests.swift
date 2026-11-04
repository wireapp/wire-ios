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
import Network
import Testing
import WireMessagingDomain

@testable import WireMessagingDomainSupport
@testable import WireMessagingUI

@MainActor
final class FilesViewModelTests {

    private let nodesRepository = MockWireDriveNodesRepositoryProtocol()
    private let localAssetRepository = MockWireDriveLocalAssetRepositoryProtocol()
    private let localAssetStore = MockWireDriveLocalAssetStoreProtocol()
    private let fileCache = MockFileCache()
    private let sut: FilesViewModel
    private var itemsUpdates: [[FilesViewItem]] = []
    private var cancellables = Set<AnyCancellable>()
    private var networkMonitor = NetworkMonitor(monitor: MockNWPathMonitoring(), initialStatus: .connected)

    init() async {
        let nodesApi = MockNodesAPIProtocol()
        nodesApi.updateTagsNodeIDTags_MockMethod = { _, _ in }
        nodesApi.getAllTags_MockMethod = { ["tag1", "tag2", "abcdef"] }
        nodesApi.getDriveConversations_MockValue = [.mocked()]

        let editingURLRepository = MockWireDriveEditingURLRepositoryProtocol()
        editingURLRepository.getEditorURLId_MockValue = nil

        networkMonitor.currentStatus = .connected
        localAssetRepository.offlineAssetsConversationNameAssetsPath_MockValue = []
        localAssetRepository.observeAssetNodeID_MockValue = Just(nil).eraseToAnyPublisher()

        self.sut = FilesViewModel(
            useCases: .init(
                fetchNodesPage: WireDriveFetchNodesPageUseCase(
                    repository: nodesRepository
                ),
                fetchNodes: WireDriveFetchNodesUseCase(
                    state: WireDriveNodesCollection(),
                    repository: nodesRepository
                ),
                deleteNodes: WireDriveDeleteNodesUseCase(
                    repository: nodesRepository,
                    fileCache: fileCache,
                    localAssetStore: localAssetStore
                ),
                emptyRecycleBin: WireDriveEmptyRecycleBinUseCase(
                    repository: nodesRepository,
                    fileCache: fileCache,
                    localAssetStore: localAssetStore
                ),
                restoreNodes: WireDriveRestoreNodesUseCase(
                    repository: nodesRepository,
                    fileCache: fileCache,
                    localAssetStore: localAssetStore
                ),
                renameNode: WireDriveRenameNodeUseCase(
                    nodesRepository: MockWireDriveNodesRepositoryProtocol(),
                    localAssetsRepository: MockWireDriveLocalAssetRepositoryProtocol(),
                    nodeCache: MockWireDriveNodeCacheProtocol(),
                    nodeRenameNotifier: WireDriveNodeRenameNotifier()
                ),
                updateTags: WireDriveUpdateTagsUseCase(nodesAPI: nodesApi),
                getTagSuggestions: WireDriveGetTagSuggestionsUseCase(nodesAPI: nodesApi),
                createFile: WireDriveCreateFileUseCase(nodesRepository: nodesRepository),
                fetchNodeVersions: WireDriveFetchNodeVersionsUseCase(repository: nodesRepository),
                restoreNodeVersion: WireDriveRestoreNodeVersionUseCase(
                    repository: nodesRepository,
                    localAssetsRepository: localAssetRepository,
                    nodeCache: MockWireDriveNodeCacheProtocol()
                ),
                getEditingURL: WireDriveGetEditingURLUseCase(editingURLRepository: editingURLRepository),
                getAsset: WireDriveGetAssetUseCase(
                    localAssetRepository: localAssetRepository,
                    fileCache: fileCache
                ),
                getPublicLinkData: WireDriveGetPublicLinkDataUseCase<MockNodesAPIProtocol>(nodesAPI: nodesApi),
                createPublicLink: WireDriveCreatePublicLinkUseCase(nodesAPI: nodesApi),
                deletePublicLink: WireDriveDeletePublicLinkUseCase(nodesAPI: nodesApi),
                updatePublicLinkExpiration: WireDriveUpdatePublicLinkExpirationUseCase(nodesAPI: nodesApi),
                updatePublicLinkPassword: WireDriveUpdatePublicLinkPasswordUseCase(nodesAPI: nodesApi),
                getDriveConversations: WireDriveGetConversationsUseCase<MockNodesAPIProtocol>(nodesAPI: nodesApi),
                getFileTemplates: WireDriveFetchFileTemplatesUseCase(repository: nodesRepository),
                makeAssetAvailableOffline: WireDriveMakeAssetAvailableOfflineUseCase(
                    localAssetRepository: localAssetRepository
                ),
                removeAssetAvailableOffline: WireDriveRemoveAssetAvailableOfflineUseCase(
                    localAssetRepository: localAssetRepository
                ),
                getOfflineAvailableAssets: WireDriveFetchOfflineAvailableAssetsUseCase(
                    localAssetRepository: localAssetRepository
                ),
                observeAsset: WireDriveObserveAssetUseCase(localAssetRepository: localAssetRepository),
                moveNodes: WireDriveMoveNodesUseCase(
                    nodesRepository: nodesRepository,
                    localAssetRepository: localAssetRepository
                ),
                enqueueUploads: MockWireDriveEnqueueDirectUploadsUseCaseProtocol()
            ),
            isCellsStatePending: false,
            isBrowsing: false,
            networkMonitor: networkMonitor
        )

        localAssetRepository.assetNodeID_MockValue = .fixture()
        localAssetRepository
            .refreshAssetMetadataNodeID_MockValue = (WireDriveNode.fixture(), WireDriveLocalAsset.fixture())
        localAssetRepository.downloadAssetNodeIDIsAvailableOffline_MockMethod = { _, _ in }
        localAssetRepository.offlineAssetsConversationNameAssetsPath_MockValue = []
        nodesRepository.getNodes_MockMethod = { _ in
            ([], 0)
        }

        await sut.setup()

        sut.filesController.controller.$state.dropFirst().sink { [weak self] state in
            self?.itemsUpdates.append(state.items)
        }.store(in: &cancellables)

        await sut.reload()
    }

    @Test
    func hasMore() async throws {
        // given
        nodesRepository.getNodes_MockMethod = { request in
            let page1 = (nodes: [WireDriveNode.fixture(conversation: .fixture())], nextOffset: 1)
            let page2 = (nodes: [WireDriveNode.fixture(conversation: .fixture())], nextOffset: Int?.none)
            return request.offset == 0 ? page1 : page2
        }
        #expect(sut.filesController.hasMore == true)

        // when
        await sut.reload()

        // then
        #expect(sut.filesController.hasMore == true)

        // when
        await sut.loadMoreIfNeeded(index: 0)

        // then
        #expect(sut.filesController.hasMore == false)
    }

    @Test
    func isLoading() async throws {
        // given
        nodesRepository.getNodes_MockMethod = { [sut] request in
            // Here we assert that loading is true when the methods under test are called.
            #expect(sut.filesController.isLoading == true)

            let page1 = (nodes: [WireDriveNode.fixture()], nextOffset: 1)
            let page2 = (nodes: [WireDriveNode.fixture()], nextOffset: Int?.none)
            return request.offset == 0 ? page1 : page2
        }

        #expect(sut.filesController.isLoading == false)

        // when
        await sut.reload()

        // then
        #expect(sut.filesController.isLoading == false)

        // when
        await sut.loadMoreIfNeeded(index: 0)

        // then
        #expect(sut.filesController.isLoading == false)
    }

    @Test
    func reload_clearsItemsBeforeLoading() async throws {
        // given
        let conversation = WireDriveConversation.fixture()
        let node = WireDriveNode.fixture(
            conversation: conversation,
            path: "some-cell/a.jpg",
            modified: nil,
            ownerUserName: nil
        )
        nodesRepository.getNodes_MockMethod = { _ in (nodes: [node], nextOffset: nil) }

        itemsUpdates = []

        // when
        await sut.reload()
        await sut.reload()

        // then
        #expect(itemsUpdates == [
            [], // Clears items
            [FilesViewItem(
                id: node.id,
                eTag: "eTag",
                kind: .file,
                name: "a.jpg",
                filePath: "some-cell/a.jpg",
                ownedBy: nil,
                modifiedAt: nil,
                icon: .other,
                tags: [],
                isEditable: false,
                publicLinkID: nil,
                conversationName: conversation.name,
                isReadOnly: false,
                size: nil,
                thumbnailURL: nil
            )],
            [], // Clears items
            [FilesViewItem(
                id: node.id,
                eTag: "eTag",
                kind: .file,
                name: "a.jpg",
                filePath: "some-cell/a.jpg",
                ownedBy: nil,
                modifiedAt: nil,
                icon: .other,
                tags: [],
                isEditable: false,
                publicLinkID: nil,
                conversationName: conversation.name,
                isReadOnly: false,
                size: nil,
                thumbnailURL: nil
            )]
        ])
    }

    @Test
    func reload_alwaysLoadsFirstPage() async throws {
        // given
        nodesRepository.getNodes_MockMethod = { _ in
            (nodes: [WireDriveNode.fixture()], nextOffset: 1) // There is a new page available
        }

        await sut.reload()
        #expect(sut.filesController.hasMore == true)

        // when
        await sut.reload()

        // then
        #expect(nodesRepository.getNodes_Invocations.last?.offset == 0)
    }

    @Test
    func reload_updatesItems() async throws {
        // given
        let now = Date()
        let conversation = WireDriveConversation.fixture()
        let node1 = WireDriveNode.fixture(
            conversation: conversation,
            path: "some-cell/a.jpg",
            modified: now,
            mimeType: "image/jpeg",
            ownerUserName: "Emel"
        )
        let node2 = WireDriveNode.fixture(
            conversation: conversation,
            path: "some-cell/b.jpg",
            modified: nil,
            ownerUserName: nil
        )
        nodesRepository.getNodes_MockMethod = { _ in (nodes: [node1, node2], nextOffset: nil) }

        // when
        await sut.reload()

        // then
        #expect(sut.state.items == [
            FilesViewItem(
                id: node1.id,
                eTag: "eTag",
                kind: .file,
                name: "a.jpg",
                filePath: "some-cell/a.jpg",
                ownedBy: "Emel",
                modifiedAt: now,
                icon: .image,
                tags: [],
                isEditable: false,
                publicLinkID: nil,
                conversationName: conversation.name,
                isReadOnly: false,
                size: nil,
                thumbnailURL: nil
            ),
            FilesViewItem(
                id: node2.id,
                eTag: "eTag",
                kind: .file,
                name: "b.jpg",
                filePath: "some-cell/b.jpg",
                ownedBy: nil,
                modifiedAt: nil,
                icon: .other,
                tags: [],
                isEditable: false,
                publicLinkID: nil,
                conversationName: conversation.name,
                isReadOnly: false,
                size: nil,
                thumbnailURL: nil
            )
        ])
    }

    @Test
    func loadMoreIfNeeded_appendsItems() async throws {
        // given
        let now = Date()
        let conversation = WireDriveConversation.fixture()
        let node1 = WireDriveNode.fixture(
            conversation: conversation,
            path: "some-cell/a.jpg",
            modified: now,
            ownerUserName: "Emel"
        )
        let node2 = WireDriveNode.fixture(
            conversation: conversation,
            path: "some-cell/b.jpg",
            modified: now - 60,
            ownerUserName: nil
        )
        let node3 = WireDriveNode.fixture(
            conversation: conversation,
            path: "some-cell/c.jpg",
            modified: nil,
            ownerUserName: nil
        )
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
                eTag: "eTag",
                kind: .file,
                name: "a.jpg",
                filePath: "some-cell/a.jpg",
                ownedBy: "Emel",
                modifiedAt: now,
                icon: .other,
                tags: [],
                isEditable: false,
                publicLinkID: nil,
                conversationName: conversation.name,
                isReadOnly: false,
                size: nil,
                thumbnailURL: nil
            ),
            FilesViewItem(
                id: node2.id,
                eTag: "eTag",
                kind: .file,
                name: "b.jpg",
                filePath: "some-cell/b.jpg",
                ownedBy: nil,
                modifiedAt: now - 60,
                icon: .other,
                tags: [],
                isEditable: false,
                publicLinkID: nil,
                conversationName: conversation.name,
                isReadOnly: false,
                size: nil,
                thumbnailURL: nil
            ),
            FilesViewItem(
                id: node3.id,
                eTag: "eTag",
                kind: .file,
                name: "c.jpg",
                filePath: "some-cell/c.jpg",
                ownedBy: nil,
                modifiedAt: nil,
                icon: .other,
                tags: [],
                isEditable: false,
                publicLinkID: nil,
                conversationName: conversation.name,
                isReadOnly: false,
                size: nil,
                thumbnailURL: nil
            )
        ])
    }

    @Test
    func loadMoreIfNeeded_doesNothingWhenNoMoreToLoad() async throws {
        // given
        nodesRepository.getNodes_MockMethod = { _ in
            (nodes: [WireDriveNode.fixture(conversation: .fixture())], nextOffset: nil) // No more pages available
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
            WireDriveNode.fixture(
                conversation: .fixture(),
                path: "some-cell/\(i).jpg",
                modified: nil,
                ownerUserName: nil
            )
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
            return (nodes: [WireDriveNode.fixture(conversation: .fixture())], nextOffset: request.offset + 1)
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
        let isConnectionError = error.isURLError(.notConnectedToInternet) || error.isURLError(.networkConnectionLost)
        #expect(sut.state == .error(isConnectionError: isConnectionError))
        #expect(sut.filesController.isLoading == false)
    }

    @Test
    func itemsFilteredCorrectly() async throws {
        // This is not a real scenario but tests that the logic for removing duplicates is correct.
        // It _is_ possible for different versions of the same node to appear across different pages. We need to ensure
        // that there is only ever one version of a node in the list.

        // given
        let now = Date()
        let conversation = WireDriveConversation.fixture()
        let nodeA = WireDriveNode.fixture(conversation: conversation, path: "foo/aa.xyz")
        let nodeB = WireDriveNode.fixture(conversation: conversation, path: "foo/bb.xyz")
        let nodeC = WireDriveNode.fixture(conversation: conversation, path: "foo/cc.xyz")
        let nodeD = WireDriveNode.fixture(conversation: conversation, path: "foo/dd.xyz")
        let nodeA_V2 = WireDriveNode.fixture(
            uuid: nodeA.id,
            conversation: conversation,
            path: "foo/aaa.xyz",
            modified: now
        )
        let nodeD_V2 = WireDriveNode.fixture(uuid: nodeD.id, conversation: conversation, path: "foo/ccc.xyz")

        nodesRepository.getNodes_MockMethod = { _ in
            (
                nodes: [nodeA, nodeB, nodeC, nodeD, nodeA_V2, nodeD_V2],
                nextOffset: nil
            )
        }

        // when
        await sut.reload()

        // then
        #expect(
            sut.state.items == [
                FilesViewItem(
                    id: nodeB.id,
                    eTag: "eTag",
                    kind: .file,
                    name: "bb.xyz",
                    filePath: "foo/bb.xyz",
                    ownedBy: nil,
                    modifiedAt: nil,
                    icon: .other,
                    tags: [],
                    isEditable: false,
                    publicLinkID: nil,
                    conversationName: conversation.name,
                    isReadOnly: false,
                    size: nil,
                    thumbnailURL: nil
                ),
                FilesViewItem(
                    id: nodeC.id,
                    eTag: "eTag",
                    kind: .file,
                    name: "cc.xyz",
                    filePath: "foo/cc.xyz",
                    ownedBy: nil,
                    modifiedAt: nil,
                    icon: .other,
                    tags: [],
                    isEditable: false,
                    publicLinkID: nil,
                    conversationName: conversation.name,
                    isReadOnly: false,
                    size: nil,
                    thumbnailURL: nil
                ),
                FilesViewItem(
                    id: nodeD.id,
                    eTag: "eTag",
                    kind: .file,
                    name: "dd.xyz",
                    filePath: "foo/dd.xyz",
                    ownedBy: nil,
                    modifiedAt: nil,
                    icon: .other,
                    tags: [],
                    isEditable: false,
                    publicLinkID: nil,
                    conversationName: conversation.name,
                    isReadOnly: false,
                    size: nil,
                    thumbnailURL: nil
                ),
                FilesViewItem(
                    id: nodeA.id,
                    eTag: "eTag",
                    kind: .file,
                    name: "aaa.xyz",
                    filePath: "foo/aaa.xyz",
                    ownedBy: nil,
                    modifiedAt: now,
                    icon: .other,
                    tags: [],
                    isEditable: false,
                    publicLinkID: nil,
                    conversationName: conversation.name,
                    isReadOnly: false,
                    size: nil,
                    thumbnailURL: nil
                )
            ]
        )
    }

    // MARK: - openItem

    @Test
    func makeOfflineAvailability_tracksMixedOfflineAndDownloadingSelection() {
        let offlineFile = FilesViewItem.fixture()
        let downloadingFile = FilesViewItem.fixture()
        let updates = CurrentValueSubject<WireDriveLocalAsset?, Never>(nil)
        localAssetRepository.observeAssetNodeID_MockMethod = { nodeID in
            if nodeID == downloadingFile.id { return updates.eraseToAnyPublisher() }
            return Just(nil).eraseToAnyPublisher()
        }
        sut.availableOfflineAssets = [.fixture(nodeID: offlineFile.id, isAvailableOffline: true)]
        sut.selectedItems = [offlineFile, downloadingFile, .fixture(kind: .folder)]
        #expect(sut.canMakeSelectedItemsAvailableOffline)

        updates.send(.fixture(nodeID: downloadingFile.id, downloadState: .downloading(progress: 0.2)))
        #expect(sut.canMakeSelectedItemsAvailableOffline)

        updates.send(.fixture(
            nodeID: downloadingFile.id,
            isAvailableOffline: true,
            downloadState: .downloading(progress: 0.2)
        ))
        #expect(!sut.canMakeSelectedItemsAvailableOffline)

        sut.selectedItems.insert(.fixture())
        #expect(sut.canMakeSelectedItemsAvailableOffline)

        sut.selectedItems = [offlineFile, downloadingFile]
        #expect(!sut.canMakeSelectedItemsAvailableOffline)
        updates.send(nil)
        #expect(sut.canMakeSelectedItemsAvailableOffline)

        sut.selectedItems = [offlineFile]
        #expect(!sut.canMakeSelectedItemsAvailableOffline)
        sut.selectedItems = [.fixture(kind: .folder)]
        #expect(!sut.canMakeSelectedItemsAvailableOffline)
        sut.selectedItems = []
        #expect(!sut.canMakeSelectedItemsAvailableOffline)
    }

    @Test
    func removeOfflineAccessAvailability_tracksSelectedDownloads() {
        let file = FilesViewItem.fixture()
        let updates = CurrentValueSubject<WireDriveLocalAsset?, Never>(nil)
        localAssetRepository.observeAssetNodeID_MockValue = updates.eraseToAnyPublisher()
        sut.selectedItems = [file]
        #expect(!sut.canRemoveSelectedItemsOfflineAccess)

        updates.send(.fixture(nodeID: file.id, downloadState: .downloading(progress: 0.2)))
        #expect(sut.canRemoveSelectedItemsOfflineAccess)

        updates.send(.fixture(
            nodeID: file.id,
            isAvailableOffline: true,
            downloadState: .downloaded(cacheKey: "offline-file")
        ))
        #expect(sut.canRemoveSelectedItemsOfflineAccess)

        sut.selectedItems = [.fixture(kind: .folder)]
        updates.send(.fixture(nodeID: file.id, downloadState: .downloading(progress: 0.5)))
        #expect(!sut.canRemoveSelectedItemsOfflineAccess)
    }

    @Test(arguments: [false, true])
    func offlineActionAvailability_whenOnlySelectedFileIsDownloading(isAvailableOffline: Bool) {
        let file = FilesViewItem.fixture()
        let asset = WireDriveLocalAsset.fixture(
            nodeID: file.id,
            isAvailableOffline: isAvailableOffline,
            downloadState: .downloading(progress: 0.2)
        )
        localAssetRepository.observeAssetNodeID_MockValue = Just(asset).eraseToAnyPublisher()

        sut.selectedItems = [file]

        #expect(sut.canMakeSelectedItemsAvailableOffline == !isAvailableOffline)
        #expect(sut.canRemoveSelectedItemsOfflineAccess)
    }

    @Test
    func removeOfflineAccessAvailability_includesCompletedOfflineFilesInMixedSelection() {
        let file = FilesViewItem.fixture()
        sut.availableOfflineAssets = [.fixture(nodeID: file.id, isAvailableOffline: true)]
        sut.selectedItems = [file, .fixture(kind: .folder)]
        #expect(sut.canRemoveSelectedItemsOfflineAccess)
    }

    @Test(arguments: [false, true])
    func makeAvailableOffline_whenSelectionContainsFolder_keepsSelectionAndShowsWarning(includeFile: Bool) {
        var items: Set<FilesViewItem> = [.fixture(kind: .folder)]
        if includeFile {
            items.insert(.fixture())
        }
        sut.selectedItems = items
        sut.multipleSelection = .active
        let refreshCount = localAssetRepository.offlineAssetsConversationNameAssetsPath_Invocations.count

        sut.makeAssetsAvailableOffline(items: items)

        #expect(sut.offlineActionWarningID != nil)
        #expect(sut.selectedItems == items)
        #expect(sut.multipleSelection == .active)
        #expect(localAssetRepository.assetNodeID_Invocations.isEmpty)
        #expect(localAssetRepository.downloadAssetsNodeIDsIsAvailableOffline_Invocations.isEmpty)
        #expect(localAssetRepository.offlineAssetsConversationNameAssetsPath_Invocations.count == refreshCount)
    }

    @Test(arguments: [false, true])
    func removeOfflineAccess_whenSelectionContainsFolder_removesOnlySelectedFiles(includeFile: Bool) async {
        var items: Set<FilesViewItem> = [.fixture(kind: .folder)]
        if includeFile {
            items.insert(.fixture())
        }
        let (refreshes, continuation) = AsyncStream.makeStream(of: Void.self)
        defer { continuation.finish() }
        var iterator = refreshes.makeAsyncIterator()
        localAssetRepository.deleteAssetNodeID_MockMethod = { _ in }
        localAssetRepository.offlineAssetsConversationNameAssetsPath_MockMethod = { _, _ in
            continuation.yield(())
            return []
        }
        sut.selectedItems = items
        sut.multipleSelection = .active

        sut.removeAssetAvailableOffline(items: items)
        _ = await iterator.next()

        let files = items.filter { $0.kind == .file }
        #expect(Set(localAssetRepository.deleteAssetNodeID_Invocations) == Set(files.map(\.id)))
        #expect(sut.offlineActionWarningID == nil)
        #expect(sut.selectedItems == files)
        #expect(sut.multipleSelection == .inactive)
    }

    @Test
    func removeOfflineAccess_whenSelectionContainsOnlyFiles_removesEveryFile() async {
        let items: Set<FilesViewItem> = [.fixture(), .fixture()]
        let (refreshes, continuation) = AsyncStream.makeStream(of: Void.self)
        defer { continuation.finish() }
        var iterator = refreshes.makeAsyncIterator()
        localAssetRepository.deleteAssetNodeID_MockMethod = { _ in }
        localAssetRepository.offlineAssetsConversationNameAssetsPath_MockMethod = { _, _ in
            continuation.yield(())
            return []
        }
        sut.selectedItems = items
        sut.multipleSelection = .active

        sut.removeAssetAvailableOffline(items: items)
        _ = await iterator.next()

        #expect(Set(localAssetRepository.deleteAssetNodeID_Invocations) == Set(items.map(\.id)))
        #expect(sut.offlineActionWarningID == nil)
        #expect(sut.multipleSelection == .inactive)
    }

    @Test
    func makeAvailableOffline_whenPartialFailure_marksOnlyFailedItemsAndAllowsRetry() async {
        let (offlineRefreshes, continuation) = AsyncStream.makeStream(of: Void.self)
        defer { continuation.finish() }
        var refreshIterator = offlineRefreshes.makeAsyncIterator()
        localAssetRepository.offlineAssetsConversationNameAssetsPath_MockMethod = { _, _ in
            continuation.yield(())
            return []
        }
        let successfulItem = FilesViewItem.fixture(id: UUID())
        let failedItem = FilesViewItem.fixture(id: UUID())
        let unrelatedID = UUID()
        sut.failedItemActions[successfulItem.id] = .makeAvailableOffline
        sut.failedItemActions[unrelatedID] = .makeAvailableOffline
        localAssetRepository.assetNodeID_MockMethod = { _ in nil }
        localAssetRepository.downloadAssetsNodeIDsIsAvailableOffline_MockMethod = { _, _ in
            [
                successfulItem.id: .success(()),
                failedItem.id: .failure(URLError(.networkConnectionLost))
            ]
        }

        sut.makeAssetsAvailableOffline(items: [successfulItem, failedItem])
        // Offline assets are refreshed after the individual results have been processed.
        _ = await refreshIterator.next()

        #expect(sut.failedItemActions[successfulItem.id] == nil)
        #expect(sut.failedItemActions[failedItem.id] == .makeAvailableOffline)
        #expect(sut.failedItemActions[unrelatedID] == .makeAvailableOffline)

        localAssetRepository.downloadAssetsNodeIDsIsAvailableOffline_MockMethod = { nodeIDs, _ in
            #expect(nodeIDs == [failedItem.id])
            return [failedItem.id: .success(())]
        }

        sut.makeAssetsAvailableOffline(items: [failedItem])
        _ = await refreshIterator.next()

        #expect(sut.failedItemActions[failedItem.id] == nil)
        #expect(sut.failedItemActions[unrelatedID] == .makeAvailableOffline)
    }

    @Test
    func openItem_whenFileAlreadyDownloaded() async throws {
        // given
        let nodeID = UUID()
        localAssetRepository.assetNodeID_MockValue = WireDriveLocalAsset.fixture(
            downloadState: .downloaded(cacheKey: "some-key")
        )
        fileCache.fileURLForKey_MockValue = URL(fileURLWithPath: "/foo")

        // when
        await sut.performPrimaryAction(item: .fixture(id: nodeID))

        // then
        #expect(fileCache.fileURLForKey_Invocations == ["some-key"])
        #expect(sut.quickPreviewItem?.url == URL(fileURLWithPath: "/foo"))
    }

    @Test
    func openItem_whenFileNeedsDownloaded() async throws {
        // given
        var assets: [UUID: WireDriveLocalAsset] = [:]
        let nodeID = UUID()
        localAssetRepository.assetNodeID_MockMethod = { nodeID in
            assets[nodeID]
        }
        localAssetRepository.downloadAssetNodeIDIsAvailableOffline_MockMethod = { nodeID, _ in
            assets[nodeID] = WireDriveLocalAsset.fixture(downloadState: .downloaded(cacheKey: "some-key"))
        }
        fileCache.fileURLForKey_MockValue = URL(fileURLWithPath: "/foo")

        // when
        await sut.performPrimaryAction(item: .fixture(id: nodeID))

        // then
        #expect(fileCache.fileURLForKey_Invocations == ["some-key"])
        #expect(sut.quickPreviewItem?
            .url == nil) // expecting the file to not open automatically after download anymore, if it's large.
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
        await sut.performPrimaryAction(item: .fixture())

        // then
        #expect(sut.alert == expectedAlert)
    }

    @Test
    func testOfflineBarIsHiddenWhenItemsAreEmpty() {
        networkMonitor.currentStatus = .disconnected
        sut.filesController.state = .received(items: [])

        #expect(sut.shouldShowOfflineBar == false)
    }

    @Test
    func testOfflineBarIsShownWhenOfflineWithItems() {
        let nodeA = WireDriveNode.fixture(path: "foo/aa.xyz")
        let now = Date()

        networkMonitor.currentStatus = .disconnected

        sut.filesController.state = .received(items: [
            FilesViewItem(
                id: nodeA.id,
                eTag: "eTag",
                kind: .file,
                name: "aaa.xyz",
                filePath: "foo/aaa.xyz",
                ownedBy: nil,
                modifiedAt: now,
                icon: .other,
                tags: [],
                isEditable: false,
                publicLinkID: nil,
                conversationName: nil,
                isReadOnly: false,
                size: nil,
                thumbnailURL: nil
            )
        ])

        #expect(sut.shouldShowOfflineBar == true)
    }

}

private final class MockNWPathMonitoring: NWPathMonitoring {
    var pathUpdateHandler: (@Sendable (NWPath) -> Void)?

    func start(queue: DispatchQueue) {}
}
