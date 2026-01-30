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

final class FilesViewTests: XCTestCase {

    private let modifiedAt = try! Date("2023-10-01T12:00:00Z", strategy: .iso8601)
    private var snapshotHelper: SnapshotHelper!
    private var nodesRepository: MockWireDriveNodesRepositoryProtocol!
    private var fetchNodesUseCase: WireDriveFetchNodesPageUseCase!
    private var deleteNodeUseCase: WireDriveDeleteNodesUseCase!
    private var restoreNodeUseCase: WireDriveRestoreNodesUseCase!
    private var renameNodeUseCase: WireDriveRenameNodeUseCase!
    private var updateTagsUseCase: (any WireDriveUpdateTagsUseCaseProtocol)!
    private var getTagSuggestionsUseCase: (any WireDriveGetTagSuggestionsUseCaseProtocol)!
    private var getEditingURLUseCase: WireDriveGetEditingURLUseCase!
    private var getPublicLinkData: WireDriveGetPublicLinkDataUseCase<MockNodesAPIProtocol>!
    private var createPublicLink: WireDriveCreatePublicLinkUseCase!
    private var deletePublicLink: WireDriveDeletePublicLinkUseCase!
    private var updatePublicLinkExpiration: WireDriveUpdatePublicLinkExpirationUseCase!
    private var updatePublicLinkPassword: WireDriveUpdatePublicLinkPasswordUseCase!

    private let record: Bool? = nil

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        nodesRepository = MockWireDriveNodesRepositoryProtocol()
        nodesRepository.getNodes_MockMethod = { _ in ([], nil) }

        let nodesApi = MockNodesAPIProtocol()
        nodesApi.updateTagsNodeIDTags_MockMethod = { _, _ in }
        nodesApi.getAllTags_MockMethod = { ["tag1", "tag2", "abcdef"] }

        let localAssetsRepository = MockWireDriveLocalAssetRepositoryProtocol()

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
            nodesRepository: nodesRepository,
            localAssetsRepository: localAssetsRepository,
            nodeCache: MockWireDriveNodeCacheProtocol(),
            nodeRenameNotifier: WireDriveNodeRenameNotifier()
        )
        updateTagsUseCase = WireDriveUpdateTagsUseCase(nodesAPI: nodesApi)
        getTagSuggestionsUseCase = WireDriveGetTagSuggestionsUseCase(nodesAPI: nodesApi)

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
        renameNodeUseCase = nil
        updateTagsUseCase = nil
        getTagSuggestionsUseCase = nil
        getEditingURLUseCase = nil
        getPublicLinkData = nil
        createPublicLink = nil
        deletePublicLink = nil
        updatePublicLinkExpiration = nil
        updatePublicLinkPassword = nil
    }

    @MainActor
    func testFilesViewItemView_withShortStrings() {
        let item = FilesViewItem(
            id: UUID(),
            eTag: "eTag",
            kind: .file,
            name: "image.jpg",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image,
            tags: [],
            isEditable: false,
            publicLinkID: nil,
            conversationName: "Conversation 1"
        )

        let view = FilesItemView(viewModel: .make(item: item))
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
            eTag: "eTag",
            kind: .file,
            name: "some random file with a long name.excel",
            filePath: "",
            ownedBy: "Liana Margaret Smith-Jones",
            modifiedAt: modifiedAt,
            icon: .spreadsheet,
            tags: [],
            isEditable: false,
            publicLinkID: nil,
            conversationName: "Conversation 1"
        )

        let view = FilesItemView(viewModel: .make(item: item))
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
            eTag: "eTag",
            kind: .file,
            name: "image.jpg",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image,
            tags: ["important"],
            isEditable: false,
            publicLinkID: nil,
            conversationName: "Conversation 1"
        )

        let view = FilesItemView(viewModel: .make(item: item))
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
            eTag: "eTag",
            kind: .file,
            name: "image.jpg",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image,
            tags: ["tag1", "tag2", "abcdef"],
            isEditable: false,
            publicLinkID: nil,
            conversationName: "Conversation 1"
        )

        let view = FilesItemView(viewModel: .make(item: item))
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
            eTag: "eTag",
            kind: .file,
            name: "some random file with a long name.excel",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .spreadsheet,
            tags: [],
            isEditable: false,
            publicLinkID: nil,
            conversationName: "Conversation 1"
        )

        let view = FilesItemView(viewModel: .make(item: item))
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
            eTag: "eTag",
            kind: .file,
            name: "image.jpg",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image,
            tags: [],
            isEditable: false,
            publicLinkID: nil,
            conversationName: "Conversation 1"
        )
        let asset = WireDriveLocalAsset(
            nodeID: item.id,
            eTag: "eTag",
            path: "some/path",
            contentType: "some/content/type",
            size: nil,
            downloadState: .downloading(progress: 0.5)
        )

        let view = FilesItemView(viewModel: .make(item: item, asset: asset))
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
            eTag: "eTag",
            kind: .file,
            name: "image.jpg",
            filePath: "",
            ownedBy: "Natsuko Shiroi",
            modifiedAt: modifiedAt,
            icon: .image,
            tags: [],
            isEditable: false,
            publicLinkID: nil,
            conversationName: "Conversation 1"
        )
        let asset = WireDriveLocalAsset(
            nodeID: item.id,
            eTag: "eTag",
            path: "some/path",
            contentType: "some/content/type",
            size: nil,
            downloadState: .failed(error: URLError(.notConnectedToInternet))
        )

        let view = FilesItemView(viewModel: .make(item: item, asset: asset))
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
        let view = makeFilesView(state: .error(isConnectionError: false))

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
                restoreNodes: restoreNodeUseCase,
                renameNode: renameNodeUseCase,
                updateTags: updateTagsUseCase,
                getTagSuggestions: getTagSuggestionsUseCase,
                createFileUseCase: WireDriveCreateFileUseCase(
                    nodesRepository: nodesRepository
                ),
                fetchNodeVersions: WireDriveFetchNodeVersionsUseCase(repository: nodesRepository),
                restoreNodeVersion: WireDriveRestoreNodeVersionUseCase(
                    repository: nodesRepository,
                    localAssetsRepository: MockWireDriveLocalAssetRepositoryProtocol(),
                    nodeCache: MockWireDriveNodeCacheProtocol()
                ),
                getEditingURL: getEditingURLUseCase,
                getAssetUseCase: WireDriveGetAssetUseCase(
                    localAssetRepository: MockWireDriveLocalAssetRepositoryProtocol(),
                    fileCache: MockFileCache()
                ),
                getPublicLinkData: getPublicLinkData,
                createPublicLink: createPublicLink,
                deletePublicLink: deletePublicLink,
                updatePublicLinkExpiration: updatePublicLinkExpiration,
                updatePublicLinkPassword: updatePublicLinkPassword,
            ),
            isCellsStatePending: false,
            localAssetRepository: MockWireDriveLocalAssetRepositoryProtocol(),
            nodesRepository: nodesRepository,
            fileCache: MockFileCache(),
            isBrowsing: false,
            accentColorProvider: { .default }
        )

        filesViewModel.state = state
        filesViewModel.hasMore = false

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
        asset: WireDriveLocalAsset? = nil
    ) -> FilesItemViewModel {
        let localAssetRepository = MockWireDriveLocalAssetRepositoryProtocol()
        localAssetRepository.observeAssetNodeID_MockValue = CurrentValueSubject<WireDriveLocalAsset?, Never>(asset)
            .eraseToAnyPublisher()

        return FilesItemViewModel(
            item: item,
            conversationName: "Conversation 1",
            localAssetRepository: localAssetRepository,
            onItemAction: { _, _ in },
            locale: Locale(identifier: "en_US_POSIX"),
            calendar: Calendar(identifier: .gregorian),
            timeZone: .gmt,
            isBrowsing: false,
            isInRecycleBin: false
        )
    }

}
