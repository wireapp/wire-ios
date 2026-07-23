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
import Network
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
    private var driveConversationsUseCase: WireDriveGetConversationsUseCase<MockNodesAPIProtocol>!
    private var makeAssetAvailableOfflineUseCase: WireDriveMakeAssetAvailableOfflineUseCase!
    private var removeAssetAvailableOfflineUseCase: WireDriveRemoveAssetAvailableOfflineUseCase!
    private var fetchOfflineAvailableAssetsUseCase: WireDriveFetchOfflineAvailableAssetsUseCase!
    private var networkMonitor: NetworkMonitor!

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

        nodesApi.getDriveConversations_MockValue = .mocked(selfUserRole: .editor)

        driveConversationsUseCase = WireDriveGetConversationsUseCase(nodesAPI: nodesApi)

        getPublicLinkData = WireDriveGetPublicLinkDataUseCase(nodesAPI: nodesApi)
        createPublicLink = WireDriveCreatePublicLinkUseCase(nodesAPI: nodesApi)
        deletePublicLink = WireDriveDeletePublicLinkUseCase(nodesAPI: nodesApi)
        updatePublicLinkExpiration = WireDriveUpdatePublicLinkExpirationUseCase(nodesAPI: nodesApi)
        updatePublicLinkPassword = WireDriveUpdatePublicLinkPasswordUseCase(nodesAPI: nodesApi)
        makeAssetAvailableOfflineUseCase = WireDriveMakeAssetAvailableOfflineUseCase(
            localAssetRepository: localAssetsRepository
        )
        removeAssetAvailableOfflineUseCase = WireDriveRemoveAssetAvailableOfflineUseCase(
            localAssetRepository: localAssetsRepository
        )

        fetchOfflineAvailableAssetsUseCase = WireDriveFetchOfflineAvailableAssetsUseCase(
            localAssetRepository: localAssetsRepository
        )

        networkMonitor = NetworkMonitor(monitor: MockNWPathMonitoring(), initialStatus: .connected)
        networkMonitor.currentStatus = .connected
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
        driveConversationsUseCase = nil
        networkMonitor = nil
    }

    @MainActor
    func testFilesViewItemView_withShortStrings() {
        let item = filesViewItem()

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
        let item = filesViewItem(
            name: "some random file with a long name.excel",
            ownedBy: "Liana Margaret Smith-Jones",
            icon: .spreadsheet,
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
        let item = filesViewItem(
            tags: ["important"]
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
        let item = filesViewItem(
            tags: ["tag1", "tag2", "abcdef"]
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
        let item = filesViewItem(
            name: "some random file with a long name.excel",
            ownedBy: "Natsuko Shiroi",
            icon: .spreadsheet
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
        let item = filesViewItem()

        let asset = WireDriveLocalAsset(
            nodeID: item.id,
            eTag: "eTag",
            path: "some/path",
            contentType: "some/content/type",
            size: nil,
            conversationName: "Conversation 1",
            ownerName: "User 1",
            modified: nil,
            isAvailableOffline: false,
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
        let item = filesViewItem()

        let asset = WireDriveLocalAsset(
            nodeID: item.id,
            eTag: "eTag",
            path: "some/path",
            contentType: "some/content/type",
            size: nil,
            conversationName: "Conversation 1",
            ownerName: "User 1",
            modified: nil,
            isAvailableOffline: false,
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
    func testFilesViewItemView_ReadOnly() {
        let item = filesViewItem(readOnly: true)

        let asset = WireDriveLocalAsset(
            nodeID: item.id,
            eTag: "eTag",
            path: "some/path",
            contentType: "some/content/type",
            size: nil,
            conversationName: "Conversation 1",
            ownerName: "User 1",
            modified: nil,
            isAvailableOffline: false,
            downloadState: .downloaded(cacheKey: "")
        )
        let viewModel = FilesItemViewModel.make(item: item, asset: asset, isBrowsing: true)
        // TODO: [WPB-25941] Remove when feature is complete
        viewModel.isDrivePermissionsFlagEnabled = true
        let view = FilesItemView(viewModel: viewModel)
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
        let view = await makeFilesView(state: .loading)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesView_NoDataState() async {
        let view = await makeFilesView(state: .received(items: []))

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesView_PendingState() async {
        let view = await makeFilesView(state: .pending)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesView_ErrorState() async {
        let view = await makeFilesView(state: .error(isConnectionError: false))

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    @MainActor
    func testFilesView_ViewerOnly() async {
        // Given
        let nodesApi = MockNodesAPIProtocol()
        nodesApi.getDriveConversations_MockValue = .mocked()
        driveConversationsUseCase = WireDriveGetConversationsUseCase(nodesAPI: nodesApi)

        // When
        let view = await makeFilesView(state: .received(items: []), isReadOnly: true)

        // Then
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }

    private func filesViewItem(
        name: String = "image.jpg",
        ownedBy: String = "Natsuko Shiroi",
        icon: WireDriveFileType = .image,
        tags: [String] = [],
        readOnly: Bool = false
    ) -> FilesViewItem {
        FilesViewItem(
            id: UUID(),
            eTag: "eTag",
            kind: .file,
            name: name,
            filePath: "",
            ownedBy: ownedBy,
            modifiedAt: modifiedAt,
            icon: icon,
            tags: tags,
            isEditable: false,
            publicLinkID: nil,
            conversationName: "Conversation 1",
            isReadOnly: readOnly,
            size: nil
        )
    }

    @MainActor
    private func makeFilesView(
        state: FilesListStateController.State,
        isBrowsing: Bool = false,
        isReadOnly: Bool = false
    ) async -> some View {
        let filesViewModel = FilesViewModel(
            useCases: .init(
                fetchNodes: fetchNodesUseCase,
                deleteNodes: deleteNodeUseCase,
                restoreNodes: restoreNodeUseCase,
                renameNode: renameNodeUseCase,
                updateTags: updateTagsUseCase,
                getTagSuggestions: getTagSuggestionsUseCase,
                createFile: WireDriveCreateFileUseCase(
                    nodesRepository: nodesRepository
                ),
                fetchNodeVersions: WireDriveFetchNodeVersionsUseCase(repository: nodesRepository),
                restoreNodeVersion: WireDriveRestoreNodeVersionUseCase(
                    repository: nodesRepository,
                    localAssetsRepository: MockWireDriveLocalAssetRepositoryProtocol(),
                    nodeCache: MockWireDriveNodeCacheProtocol()
                ),
                getEditingURL: getEditingURLUseCase,
                getAsset: WireDriveGetAssetUseCase(
                    localAssetRepository: MockWireDriveLocalAssetRepositoryProtocol(),
                    fileCache: MockFileCache()
                ),
                getPublicLinkData: getPublicLinkData,
                createPublicLink: createPublicLink,
                deletePublicLink: deletePublicLink,
                updatePublicLinkExpiration: updatePublicLinkExpiration,
                updatePublicLinkPassword: updatePublicLinkPassword,
                getDriveConversations: driveConversationsUseCase,
                getFileTemplates: WireDriveFetchFileTemplatesUseCase(
                    repository: nodesRepository
                ),
                makeAssetAvailableOffline: makeAssetAvailableOfflineUseCase,
                removeAssetAvailableOffline: removeAssetAvailableOfflineUseCase,
                getOfflineAvailableAssets: fetchOfflineAvailableAssetsUseCase
            ),
            isCellsStatePending: false,
            localAssetRepository: MockWireDriveLocalAssetRepositoryProtocol(),
            nodesRepository: nodesRepository,
            isBrowsing: isBrowsing,
            networkMonitor: networkMonitor
        )

        await filesViewModel.setup()

        filesViewModel.filesController.state = state
        filesViewModel.filesController.hasMore = false
        filesViewModel.showReadOnlyBanner = isReadOnly

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
        asset: WireDriveLocalAsset? = nil,
        isBrowsing: Bool = false
    ) -> FilesItemViewModel {
        let localAssetRepository = MockWireDriveLocalAssetRepositoryProtocol()
        localAssetRepository.observeAssetNodeID_MockValue = CurrentValueSubject<WireDriveLocalAsset?, Never>(asset)
            .eraseToAnyPublisher()
        localAssetRepository.assetNodeID_MockValue = WireDriveLocalAsset.fixture()

        return FilesItemViewModel(
            item: item,
            selectedSortingKey: .date,
            conversationName: "Conversation 1",
            localAssetRepository: localAssetRepository,
            onItemAction: { _, _ in },
            locale: Locale(identifier: "en_US_POSIX"),
            calendar: Calendar(identifier: .gregorian),
            timeZone: .gmt,
            isBrowsing: isBrowsing,
            isInRecycleBin: false
        )
    }

}

private final class MockNWPathMonitoring: NWPathMonitoring {
    var pathUpdateHandler: (@Sendable (NWPath) -> Void)?

    func start(queue: DispatchQueue) {}
}
