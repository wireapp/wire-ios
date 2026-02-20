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
    private var nodesRepository: MockWireDriveNodesRepositoryProtocol!
    private var fetchNodesUseCase: WireDriveFetchNodesPageUseCase!
    private var deleteNodeUseCase: WireDriveDeleteNodesUseCase!
    private var restoreNodeUseCase: WireDriveRestoreNodesUseCase!
    private var renameNodeUseCase: WireDriveRenameNodeUseCase!
    private var updateTagsUseCase: (any WireDriveUpdateTagsUseCaseProtocol)!
    private var getTagSuggestionsUseCase: (any WireDriveGetTagSuggestionsUseCaseProtocol)!
    private var createFileUseCase: (any WireDriveCreateFileUseCaseProtocol)!
    private var fetchNodeVersionsUseCase: WireDriveFetchNodeVersionsUseCase!
    private var restoreNodeVersionUseCase: WireDriveRestoreNodeVersionUseCase!
    private var getEditingURLUseCase: WireDriveGetEditingURLUseCase!
    private var getAssetUseCase: WireDriveGetAssetUseCase!
    private var localAssetsRepository: MockWireDriveLocalAssetRepositoryProtocol!
    private var getPublicLinkData: WireDriveGetPublicLinkDataUseCase<MockNodesAPIProtocol>!
    private var createPublicLink: WireDriveCreatePublicLinkUseCase!
    private var deletePublicLink: WireDriveDeletePublicLinkUseCase!
    private var updatePublicLinkExpiration: WireDriveUpdatePublicLinkExpirationUseCase!
    private var updatePublicLinkPassword: WireDriveUpdatePublicLinkPasswordUseCase!
    private var getDriveConversationsUseCase: WireDriveGetConversationsUseCase<MockNodesAPIProtocol>!

    private let record: Bool? = nil

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        nodesRepository = MockWireDriveNodesRepositoryProtocol()
        nodesRepository.getNodes_MockMethod = { _ in ([], nil) }
        localAssetsRepository = MockWireDriveLocalAssetRepositoryProtocol()

        let nodesApi = MockNodesAPIProtocol()
        nodesApi.updateTagsNodeIDTags_MockMethod = { _, _ in }
        nodesApi.getAllTags_MockMethod = { ["tag1", "tag2", "abcdef"] }
        nodesApi.getDriveConversations_MockValue = [.mocked()]
        
        getDriveConversationsUseCase = WireDriveGetConversationsUseCase(nodesAPI: nodesApi)

        fetchNodesUseCase = WireDriveFetchNodesPageUseCase(
            configuration: .conversationFileView(root: .id(.mockID1)),
            repository: nodesRepository
        )
        deleteNodeUseCase = WireDriveDeleteNodesUseCase(
            repository: nodesRepository,
            fileCache: MockFileCache(),
            localAssetStore: MockWireDriveLocalAssetStoreProtocol()
        )
        restoreNodeUseCase = WireDriveRestoreNodesUseCase(
            repository: nodesRepository,
            fileCache: MockFileCache(),
            localAssetStore: MockWireDriveLocalAssetStoreProtocol()
        )
        renameNodeUseCase = WireDriveRenameNodeUseCase(
            nodesRepository: MockWireDriveNodesRepositoryProtocol(),
            localAssetsRepository: localAssetsRepository,
            nodeCache: MockWireDriveNodeCacheProtocol(),
            nodeRenameNotifier: WireDriveNodeRenameNotifier()
        )
        updateTagsUseCase = WireDriveUpdateTagsUseCase(nodesAPI: nodesApi)
        getTagSuggestionsUseCase = WireDriveGetTagSuggestionsUseCase(nodesAPI: nodesApi)
        getAssetUseCase = WireDriveGetAssetUseCase(
            localAssetRepository: localAssetsRepository,
            fileCache: MockFileCache()
        )

        createFileUseCase = WireDriveCreateFileUseCase(
            nodesRepository: nodesRepository
        )

        fetchNodeVersionsUseCase = WireDriveFetchNodeVersionsUseCase(repository: nodesRepository)
        restoreNodeVersionUseCase = WireDriveRestoreNodeVersionUseCase(
            repository: nodesRepository,
            localAssetsRepository: localAssetsRepository,
            nodeCache: MockWireDriveNodeCacheProtocol()
        )

        let editingURLRepository = MockWireDriveEditingURLRepositoryProtocol()
        editingURLRepository.getEditorURLId_MockValue = nil
        getEditingURLUseCase = WireDriveGetEditingURLUseCase(
            editingURLRepository: editingURLRepository
        )

        getPublicLinkData = WireDriveGetPublicLinkDataUseCase(nodesAPI: nodesApi)
        createPublicLink = WireDriveCreatePublicLinkUseCase(nodesAPI: nodesApi)
        deletePublicLink = WireDriveDeletePublicLinkUseCase(nodesAPI: nodesApi)
        updatePublicLinkExpiration = WireDriveUpdatePublicLinkExpirationUseCase(nodesAPI: nodesApi)
        updatePublicLinkPassword = WireDriveUpdatePublicLinkPasswordUseCase(nodesAPI: nodesApi)
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        nodesRepository = nil
        fetchNodesUseCase = nil
        localAssetsRepository = nil
        fetchNodeVersionsUseCase = nil
        createFileUseCase = nil
        getTagSuggestionsUseCase = nil
        updateTagsUseCase = nil
        renameNodeUseCase = nil
        deleteNodeUseCase = nil
        restoreNodeVersionUseCase = nil
        getDriveConversationsUseCase = nil
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
        let view = makeFilesBrowserView(state: .error(isConnectionError: false))

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
                createFileUseCase: createFileUseCase,
                fetchNodeVersions: fetchNodeVersionsUseCase,
                restoreNodeVersion: restoreNodeVersionUseCase,
                getEditingURL: getEditingURLUseCase,
                getAssetUseCase: getAssetUseCase,
                getPublicLinkData: getPublicLinkData,
                createPublicLink: createPublicLink,
                deletePublicLink: deletePublicLink,
                updatePublicLinkExpiration: updatePublicLinkExpiration,
                updatePublicLinkPassword: updatePublicLinkPassword,
                getDriveConversations: getDriveConversationsUseCase
            ),
            isCellsStatePending: false,
            localAssetRepository: localAssetsRepository,
            nodesRepository: nodesRepository,
            fileCache: MockFileCache(),
            isBrowsing: true,
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
