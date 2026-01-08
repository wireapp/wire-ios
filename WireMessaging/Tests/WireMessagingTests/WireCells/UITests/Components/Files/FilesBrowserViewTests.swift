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
import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class FilesBrowserViewTests: XCTestCase {

    private let modifiedAt = try! Date("2023-10-01T12:00:00Z", strategy: .iso8601)
    private var snapshotHelper: SnapshotHelper!
    private var nodesRepository: MockWireCellsNodesRepositoryProtocol!
    private var fetchNodesUseCase: WireCellsFetchNodesPageUseCase!
    private var deleteNodeUseCase: WireCellsDeleteNodesUseCase!
    private var restoreNodeUseCase: WireCellsRestoreNodesUseCase!
    private var renameNodeUseCase: WireCellsRenameNodeUseCase!
    private var updateTagsUseCase: (any WireCellsUpdateTagsUseCaseProtocol)!
    private var getTagSuggestionsUseCase: (any WireCellsGetTagSuggestionsUseCaseProtocol)!
    private var createFolderUseCase: (any WireCellsCreateFolderUseCaseProtocol)!
    private var fetchNodeVersionsUseCase: WireCellsFetchNodeVersionsUseCase!
    private var restoreNodeVersionUseCase: WireCellsRestoreNodeVersionUseCase!
    private var getEditingURLUseCase: WireCellsGetEditingURLUseCase!
    private var getAssetUseCase: WireCellsGetAssetUseCase!
    private var localAssetsRepository: MockWireCellsLocalAssetRepositoryProtocol!
    private var getPublicLinkData: WireCellsGetPublicLinkDataUseCase<MockNodesAPIProtocol>!
    private var createPublicLink: WireCellsCreatePublicLinkUseCase!
    private var deletePublicLink: WireCellsDeletePublicLinkUseCase!
    private var updatePublicLinkExpiration: WireCellsUpdatePublicLinkExpirationUseCase!
    private var updatePublicLinkPassword: WireCellsUpdatePublicLinkPasswordUseCase!

    private let record: Bool? = nil

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        nodesRepository = MockWireCellsNodesRepositoryProtocol()
        nodesRepository.getNodes_MockMethod = { _ in ([], nil) }
        localAssetsRepository = MockWireCellsLocalAssetRepositoryProtocol()

        let nodesApi = MockNodesAPIProtocol()
        nodesApi.updateTagsNodeIDTags_MockMethod = { _, _ in }
        nodesApi.getAllTags_MockMethod = { ["tag1", "tag2", "abcdef"] }

        fetchNodesUseCase = WireCellsFetchNodesPageUseCase(
            configuration: .conversationFileView(root: .id(.mockID1), isFoldersEnabled: false),
            repository: nodesRepository
        )
        deleteNodeUseCase = WireCellsDeleteNodesUseCase(
            repository: nodesRepository,
            fileCache: MockFileCache(),
            localAssetStore: MockWireCellsLocalAssetStoreProtocol()
        )
        restoreNodeUseCase = WireCellsRestoreNodesUseCase(
            repository: nodesRepository,
            fileCache: MockFileCache(),
            localAssetStore: MockWireCellsLocalAssetStoreProtocol()
        )
        renameNodeUseCase = WireCellsRenameNodeUseCase(
            nodesRepository: MockWireCellsNodesRepositoryProtocol(),
            localAssetsRepository: localAssetsRepository,
            nodeCache: MockWireCellsNodeCacheProtocol(),
            nodeRenameNotifier: WireCellsNodeRenameNotifier()
        )
        updateTagsUseCase = WireCellsUpdateTagsUseCase(nodesAPI: nodesApi)
        getTagSuggestionsUseCase = WireCellsGetTagSuggestionsUseCase(nodesAPI: nodesApi)
        getAssetUseCase = WireCellsGetAssetUseCase(
            localAssetRepository: localAssetsRepository,
            fileCache: MockFileCache()
        )

        createFolderUseCase = WireCellsCreateFolderUseCase(
            nodesRepository: nodesRepository
        )

        fetchNodeVersionsUseCase = WireCellsFetchNodeVersionsUseCase(repository: nodesRepository)
        restoreNodeVersionUseCase = WireCellsRestoreNodeVersionUseCase(
            repository: nodesRepository,
            localAssetsRepository: localAssetsRepository,
            nodeCache: MockWireCellsNodeCacheProtocol()
        )

        let editingURLRepository = MockWireCellsEditingURLRepositoryProtocol()
        editingURLRepository.getEditorURLId_MockValue = nil
        getEditingURLUseCase = WireCellsGetEditingURLUseCase(
            editingURLRepository: editingURLRepository
        )

        getPublicLinkData = WireCellsGetPublicLinkDataUseCase(nodesAPI: nodesApi)
        createPublicLink = WireCellsCreatePublicLinkUseCase(nodesAPI: nodesApi)
        deletePublicLink = WireCellsDeletePublicLinkUseCase(nodesAPI: nodesApi)
        updatePublicLinkExpiration = WireCellsUpdatePublicLinkExpirationUseCase(nodesAPI: nodesApi)
        updatePublicLinkPassword = WireCellsUpdatePublicLinkPasswordUseCase(nodesAPI: nodesApi)
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        nodesRepository = nil
        fetchNodesUseCase = nil
        localAssetsRepository = nil
        fetchNodeVersionsUseCase = nil
        createFolderUseCase = nil
        getTagSuggestionsUseCase = nil
        updateTagsUseCase = nil
        renameNodeUseCase = nil
        deleteNodeUseCase = nil
        restoreNodeVersionUseCase = nil
    }

    @MainActor
    func testFilesBrowserView_LoadingState() async {
        let view = makeFilesBrowserView(state: .loading)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesBrowserView_NoDataState() async {
        let view = makeFilesBrowserView(state: .received(items: []))

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesBrowserView_PendingState() async {
        let view = makeFilesBrowserView(state: .pending)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesBrowserView_ErrorState() async {
        let view = makeFilesBrowserView(state: .error)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesBrowserView_ReceivedItemsState() async {
        let view = makeFilesBrowserView(
            state: .received(
                items: [
                    .fixture(),
                    .fixture(tags: ["tag1"]),
                    .fixture(tags: ["tag1", "tag2", "abc"])
                ]
            )
        )
        localAssetsRepository.observeAssetNodeID_MockValue = Just(nil).eraseToAnyPublisher()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    private func makeFilesBrowserView(
        state: FilesViewModel.State
    ) -> some View {
        let filesViewModel = FilesViewModel(
            useCases: .init(
                fetchNodes: fetchNodesUseCase,
                deleteNodes: deleteNodeUseCase,
                restoreNodes: restoreNodeUseCase,
                renameNode: renameNodeUseCase,
                updateTags: updateTagsUseCase,
                getTagSuggestions: getTagSuggestionsUseCase,
                createFolder: createFolderUseCase,
                fetchNodeVersions: fetchNodeVersionsUseCase,
                restoreNodeVersion: restoreNodeVersionUseCase,
                getEditingURL: getEditingURLUseCase,
                getAssetUseCase: getAssetUseCase,
                getPublicLinkData: getPublicLinkData,
                createPublicLink: createPublicLink,
                deletePublicLink: deletePublicLink,
                updatePublicLinkExpiration: updatePublicLinkExpiration,
                updatePublicLinkPassword: updatePublicLinkPassword,
            ),
            isCellsStatePending: false,
            localAssetRepository: localAssetsRepository,
            nodesRepository: nodesRepository,
            fileCache: MockFileCache(),
            isFoldersEnabled: false,
            isCollaboraEnabled: false,
            accentColorProvider: { .default }
        )

        filesViewModel.state = state
        filesViewModel.hasMore = false

        let filesBrowserView = FilesBrowserView(viewModel: filesViewModel)

        return NavigationStack {
            filesBrowserView
        }
        .frame(width: 375, height: 667)
    }

}
