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
    private var fetchNodesUseCase: WireCellsFetchNodesUseCase!
    private var deleteNodeUseCase: WireCellsDeleteNodesUseCase!
    private var renameNodeUseCase: WireCellsRenameNodeUseCase!
    private var updateTagsUseCase: (any WireCellsUpdateTagsUseCaseProtocol)!
    private var getTagSuggestionsUseCase: (any WireCellsGetTagSuggestionsUseCaseProtocol)!
    private var createFolderUseCase: (any WireCellsCreateFolderUseCaseProtocol)!
    private var localAssetsRepository: MockWireCellsLocalAssetRepositoryProtocol!

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

        fetchNodesUseCase = WireCellsFetchNodesUseCase(
            configuration: .conversationFileView(root: .id(.mockID1), isFoldersEnabled: false),
            repository: nodesRepository
        )
        deleteNodeUseCase = WireCellsDeleteNodesUseCase(
            repository: nodesRepository,
            fileCache: MockFileCache(),
            localAssetStore: MockWireCellsLocalAssetStoreProtocol()
        )
        renameNodeUseCase = WireCellsRenameNodeUseCase(
            nodesRepository: MockWireCellsNodesRepositoryProtocol(),
            localAssetsRepository: MockWireCellsLocalAssetRepositoryProtocol(),
            nodeCache: MockWireCellsNodeCacheProtocol(),
            nodeRenameNotifier: WireCellsNodeRenameNotifier()
        )
        updateTagsUseCase = WireCellsUpdateTagsUseCase(nodesAPI: nodesApi)
        getTagSuggestionsUseCase = WireCellsGetTagSuggestionsUseCase(nodesAPI: nodesApi)
        createFolderUseCase = WireCellsCreateFolderUseCase(
            nodesRepository: nodesRepository
        )
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        nodesRepository = nil
        fetchNodesUseCase = nil
        localAssetsRepository = nil
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
                renameNode: renameNodeUseCase,
                updateTags: updateTagsUseCase,
                getTagSuggestions: getTagSuggestionsUseCase,
                createFolder: createFolderUseCase,
            ),
            isCellsStatePending: false,
            localAssetRepository: localAssetsRepository,
            fileCache: MockFileCache(),
            isFoldersEnabled: false,
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
