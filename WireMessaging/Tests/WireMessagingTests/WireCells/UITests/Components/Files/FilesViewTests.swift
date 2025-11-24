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

final class FilesViewTests: XCTestCase {

    private let modifiedAt = try! Date("2023-10-01T12:00:00Z", strategy: .iso8601)
    private var snapshotHelper: SnapshotHelper!
    private var nodesRepository: MockWireCellsNodesRepositoryProtocol!
    private var fetchNodesUseCase: WireCellsFetchNodesPageUseCase!
    private var deleteNodeUseCase: WireCellsDeleteNodesUseCase!
    private var renameNodeUseCase: WireCellsRenameNodeUseCase!
    private var updateTagsUseCase: (any WireCellsUpdateTagsUseCaseProtocol)!
    private var getTagSuggestionsUseCase: (any WireCellsGetTagSuggestionsUseCaseProtocol)!

    private let record: Bool? = nil

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        nodesRepository = MockWireCellsNodesRepositoryProtocol()
        nodesRepository.getNodes_MockMethod = { _ in ([], nil) }

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
        renameNodeUseCase = WireCellsRenameNodeUseCase(
            nodesRepository: nodesRepository,
            localAssetsRepository: MockWireCellsLocalAssetRepositoryProtocol(),
            nodeCache: MockWireCellsNodeCacheProtocol(),
            nodeRenameNotifier: WireCellsNodeRenameNotifier()
        )
        updateTagsUseCase = WireCellsUpdateTagsUseCase(nodesAPI: nodesApi)
        getTagSuggestionsUseCase = WireCellsGetTagSuggestionsUseCase(nodesAPI: nodesApi)
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        nodesRepository = nil
        fetchNodesUseCase = nil
        renameNodeUseCase = nil
        updateTagsUseCase = nil
        getTagSuggestionsUseCase = nil
    }

    @MainActor
    func testFilesViewItemView_withShortStrings() {
        let item = FilesViewItem(
            id: UUID(),
            kind: .file,
            name: "image.jpg",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image,
            tags: []
        )

        let view = FilesViewItemView(viewModel: .make(item: item))
            .frame(width: 390)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesViewItemView_withLongStrings() {
        let item = FilesViewItem(
            id: UUID(),
            kind: .file,
            name: "some random file with a long name.excel",
            filePath: "",
            ownedBy: "Liana Margaret Smith-Jones",
            modifiedAt: modifiedAt,
            icon: .spreadsheet,
            tags: []
        )

        let view = FilesViewItemView(viewModel: .make(item: item))
            .frame(width: 390)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesViewItemView_withOneTag() {
        let item = FilesViewItem(
            id: UUID(),
            kind: .file,
            name: "image.jpg",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image,
            tags: ["important"]
        )

        let view = FilesViewItemView(viewModel: .make(item: item))
            .frame(width: 390)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesViewItemView_withThreeTags() {
        let item = FilesViewItem(
            id: UUID(),
            kind: .file,
            name: "image.jpg",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image,
            tags: ["tag1", "tag2", "abcdef"]
        )

        let view = FilesViewItemView(viewModel: .make(item: item))
            .frame(width: 390)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesViewItemView_dynamicTypeVariants() {
        let item = FilesViewItem(
            id: UUID(),
            kind: .file,
            name: "some random file with a long name.excel",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .spreadsheet,
            tags: []
        )

        let view = FilesViewItemView(viewModel: .make(item: item))
            .frame(width: 390)

        for dynamicTypeSize in [DynamicTypeSize.allCases.min()!, DynamicTypeSize.allCases.max()!] {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)",
                    record: record
                )
        }
    }

    @MainActor
    func testFilesViewItemView_whenDownloading() {
        let item = FilesViewItem(
            id: UUID(),
            kind: .file,
            name: "image.jpg",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image,
            tags: []
        )
        let asset = WireCellsLocalAsset(
            nodeID: item.id,
            eTag: "eTag",
            path: "some/path",
            contentType: "some/content/type",
            size: nil,
            downloadState: .downloading(progress: 0.5)
        )

        let view = FilesViewItemView(viewModel: .make(item: item, asset: asset))
            .frame(width: 390)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesViewItemView_whenDownloadFailed() {
        let item = FilesViewItem(
            id: UUID(),
            kind: .file,
            name: "image.jpg",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image,
            tags: []
        )
        let asset = WireCellsLocalAsset(
            nodeID: item.id,
            eTag: "eTag",
            path: "some/path",
            contentType: "some/content/type",
            size: nil,
            downloadState: .failed(error: URLError(.notConnectedToInternet))
        )

        let view = FilesViewItemView(viewModel: .make(item: item, asset: asset))
            .frame(width: 390)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesView_LoadingState() async {
        let view = makeFilesView(state: .loading)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesView_NoDataState() async {
        let view = makeFilesView(state: .received(items: []))

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesView_PendingState() async {
        let view = makeFilesView(state: .pending)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesView_ErrorState() async {
        let view = makeFilesView(state: .error)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    private func makeFilesView(
        state: FilesViewModel.State
    ) -> some View {
        let filesViewModel = FilesViewModel(
            useCases: .init(
                fetchNodes: fetchNodesUseCase,
                deleteNodes: deleteNodeUseCase,
                renameNode: renameNodeUseCase,
                updateTags: updateTagsUseCase,
                getTagSuggestions: getTagSuggestionsUseCase,
                createFolder: WireCellsCreateFolderUseCase(
                    nodesRepository: nodesRepository
                ),
            ),
            isCellsStatePending: false,
            localAssetRepository: MockWireCellsLocalAssetRepositoryProtocol(),
            nodesRepository: nodesRepository,
            fileCache: MockFileCache(),
            isFoldersEnabled: true,
        )

        filesViewModel.state = state

        return NavigationStack {
            FilesView(viewModel: filesViewModel)
        }
        .frame(width: 375, height: 667)
    }

}

// MARK: - Private Helpers

private extension FilesItemViewModel {

    static func make(
        item: FilesViewItem,
        asset: WireCellsLocalAsset? = nil
    ) -> FilesItemViewModel {
        let localAssetRepository = MockWireCellsLocalAssetRepositoryProtocol()
        localAssetRepository.observeAssetNodeID_MockValue = CurrentValueSubject<WireCellsLocalAsset?, Never>(asset)
            .eraseToAnyPublisher()

        return FilesItemViewModel(
            item: item,
            localAssetRepository: localAssetRepository,
            onOpen: { _ in },
            onDelete: { _ in },
            onEditTagsSelected: { _ in },
            locale: Locale(identifier: "en_US_POSIX"),
            calendar: Calendar(identifier: .gregorian),
            timeZone: .gmt
        )
    }

}
