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

package import Combine
package import Foundation
import SwiftUI
import UniformTypeIdentifiers
package import WireFoundation
import WireLogging
package import WireMessagingDomain
import WireMessagingDomainSupport

/// An item in the `FilesView`.
package struct FilesViewItem: Identifiable, Hashable {

    /// The kind of item
    enum Kind {

        /// A file.
        case file

        /// A folder.
        case folder
    }

    /// Identifier of this item on the wire drive backend.
    package let id: UUID

    /// The ETag of this item.
    let eTag: String

    /// The id of the topmost folder in the recycle bin, if the item is not at the root of the recycle bin.
    /// Needed to restore items which are in folders rather than directly at the root of the recycle bin.
    var recycleBinTopFolderId: UUID?

    /// The kind of this item - file or folder.
    let kind: Kind

    /// The name of the this item.
    let name: String

    /// The filepath of the item.
    let filePath: String

    /// The name of the user who owns (uploaded) this file.
    let ownedBy: String?

    /// The date when the item was last modified.
    let modifiedAt: Date?

    /// The icon representing the item's type.
    let icon: WireDriveFileType

    /// The tags that users have added for that file.
    let tags: [String]

    /// Whether the item can be edited.
    let isEditable: Bool

    /// The public link identifier if the item has a public link.
    let publicLinkID: String?

    /// The name of the conversation the node is attached to.
    let conversationName: String?

    /// The size of of this item
    let size: UInt64?
}

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

@MainActor
/// View model for the `FilesView`.
package final class FilesViewModel: ObservableObject {

    private typealias LoadItemsTask = Task<(items: [FilesViewItem], isLastPage: Bool), any Error>

    private enum Constants {

        /// How close to the end of the list before loading more items.
        static let loadMoreThreshold = 5
    }

    enum SheetNavigation: Identifiable {
        case editTags(fileItem: FilesViewItem)
        case shareLink(view: ShareLinkView)
        case moveToFolder(fileItem: FilesViewItem)
        case renameFile(view: FileRenameView)
        case create(view: CreateFileView)
        case versionHistory(view: FileVersioningView)

        var id: String {
            switch self {
            case let .editTags(fileItem: item):
                "editTags(\(item.id))"
            case let .shareLink(view):
                "shareLink(\(view.id))"
            case let .moveToFolder(fileItem):
                "moveToFolder(\(fileItem.id))"
            case let .create(view):
                "create(\(view.id))"
            case let .renameFile(view):
                "renameFile(\(view.id))"
            case let .versionHistory(view):
                "versionHistory(\(view.id))"
            }
        }
    }

    /// An navigation option displayed in the navigation folder menu.
    enum FolderMenuOption: Hashable {
        case folder(nodeID: UUID, title: String)
        case root
    }

    enum State: Equatable {

        case loading
        case received(items: [FilesViewItem])
        case pending // drive is not ready yet
        case error(isConnectionError: Bool)

        var items: [FilesViewItem] {
            switch self {
            case let .received(items):
                items
            default:
                []
            }
        }

        var isLoaded: Bool {
            switch self {
            case .loading, .pending, .error:
                false
            case .received:
                true
            }
        }
    }

    package struct UseCases {
        package init(
            fetchNodes: WireDriveFetchNodesPageUseCase,
            deleteNodes: WireDriveDeleteNodesUseCase,
            restoreNodes: WireDriveRestoreNodesUseCase,
            renameNode: any WireDriveRenameNodeUseCaseProtocol,
            updateTags: any WireDriveUpdateTagsUseCaseProtocol,
            getTagSuggestions: any WireDriveGetTagSuggestionsUseCaseProtocol,
            createFile: any WireDriveCreateFileUseCaseProtocol,
            fetchNodeVersions: any WireDriveFetchNodeVersionsUseCaseProtocol,
            restoreNodeVersion: any WireDriveRestoreNodeVersionUseCaseProtocol,
            getEditingURL: WireDriveGetEditingURLUseCase,
            getAsset: WireDriveGetAssetUseCase,
            getPublicLinkData: any WireDriveGetPublicLinkDataUseCaseProtocol,
            createPublicLink: WireDriveCreatePublicLinkUseCase,
            deletePublicLink: WireDriveDeletePublicLinkUseCase,
            updatePublicLinkExpiration: WireDriveUpdatePublicLinkExpirationUseCase,
            updatePublicLinkPassword: WireDriveUpdatePublicLinkPasswordUseCase,
            getDriveConversations: any WireDriveGetConversationsUseCaseProtocol,
            getFileTemplates: any WireDriveFetchFileTemplatesUseCaseProtocol,
            makeAssetAvailableOffline: WireDriveMakeAssetAvailableOfflineUseCase,
            removeAssetAvailableOffline: WireDriveRemoveAssetAvailableOfflineUseCase,
            getOfflineAvailableAssets: WireDriveFetchOfflineAvailableAssetsUseCase
        ) {

            self.fetchNodes = fetchNodes
            self.deleteNodes = deleteNodes
            self.restoreNodes = restoreNodes
            self.renameNode = renameNode
            self.updateTags = updateTags
            self.getTagSuggestions = getTagSuggestions
            self.createFile = createFile
            self.fetchNodeVersions = fetchNodeVersions
            self.restoreNodeVersion = restoreNodeVersion
            self.getEditingURL = getEditingURL
            self.getAsset = getAsset
            self.getPublicLinkData = getPublicLinkData
            self.createPublicLink = createPublicLink
            self.deletePublicLink = deletePublicLink
            self.updatePublicLinkExpiration = updatePublicLinkExpiration
            self.updatePublicLinkPassword = updatePublicLinkPassword
            self.getDriveConversations = getDriveConversations
            self.getFileTemplates = getFileTemplates
            self.makeAssetAvailableOffline = makeAssetAvailableOffline
            self.removeAssetAvailableOffline = removeAssetAvailableOffline
            self.getOfflineAvailableAssets = getOfflineAvailableAssets
        }

        let fetchNodes: WireDriveFetchNodesPageUseCase
        let deleteNodes: WireDriveDeleteNodesUseCase
        let restoreNodes: WireDriveRestoreNodesUseCase
        let renameNode: any WireDriveRenameNodeUseCaseProtocol
        let updateTags: any WireDriveUpdateTagsUseCaseProtocol
        let getTagSuggestions: any WireDriveGetTagSuggestionsUseCaseProtocol
        let createFile: any WireDriveCreateFileUseCaseProtocol
        let fetchNodeVersions: any WireDriveFetchNodeVersionsUseCaseProtocol
        let restoreNodeVersion: any WireDriveRestoreNodeVersionUseCaseProtocol
        let getEditingURL: WireDriveGetEditingURLUseCase
        let getAsset: WireDriveGetAssetUseCase
        let getPublicLinkData: any WireDriveGetPublicLinkDataUseCaseProtocol
        let createPublicLink: WireDriveCreatePublicLinkUseCase
        let deletePublicLink: WireDriveDeletePublicLinkUseCase
        let updatePublicLinkExpiration: WireDriveUpdatePublicLinkExpirationUseCase
        let updatePublicLinkPassword: WireDriveUpdatePublicLinkPasswordUseCase
        let getDriveConversations: any WireDriveGetConversationsUseCaseProtocol
        let getFileTemplates: any WireDriveFetchFileTemplatesUseCaseProtocol
        let makeAssetAvailableOffline: WireDriveMakeAssetAvailableOfflineUseCase
        let removeAssetAvailableOffline: WireDriveRemoveAssetAvailableOfflineUseCase
        let getOfflineAvailableAssets: WireDriveFetchOfflineAvailableAssetsUseCase
    }

    private let setNavigation: ([FilesViewItem]) -> Void
    private let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol
    private let nodesRepository: any WireDriveNodesRepositoryProtocol
    private let fileCache: any FileCache
    private let cellName: String? // nil when browsing all files
    private var subscriptions = Set<AnyCancellable>()
    private let navigationPath: [FilesViewItem]
    private var sortingSelection: FilesSortingViewModel.SortingSelection = .default

    let useCases: UseCases
    let isBrowsing: Bool
    let isRecycleBin: Bool
    let triggerReload: PassthroughSubject<Void, Never> //TODO: check if needed
    let title: String?
    var showSearchBar: Bool {
        guard !isOffline else {
            return false
        }

        return switch state {
        case .loading, .received:
            true
        case .pending, .error:
            false
        }
    }

    var navigationTitle: String {
        if let title {
            title
        } else {
            if isRecycleBin {
                Strings.RecycleBin.navigationTitle
            } else {
                Strings.Files.navigationTitle
            }
        }
    }

    /// Whether the view model is currently loading items.
    var isLoading: Bool {
        loadMoreTask != nil
    }

    var networkStatus: NetworkMonitor.NetworkStatus? {
        networkMonitor.currentStatus
    }

    var isOffline: Bool {
        networkMonitor.currentStatus == .disconnected
    }

    var shouldShowOfflineBar: Bool {
        isOffline && !state.items.isEmpty
    }

    @Published var hasMore = true
    @Published private var loadMoreTask: LoadItemsTask?
    @Published var searchText = ""
    @Published var alert: AlertModel?
    @Published var viewingURL: URL?
    @Published var state: State
    @Published var sheetNavigation: SheetNavigation?
    @Published var createView: CreateFileView?
    @Published var fileRenameView: FileRenameView?
    @Published var isEditing: FilesViewItem?
    @Published var templates: [WireDriveFileTemplate] = []
    @Published var conversations: [WireDriveConversation] = []
    @Published var filtersSelection: FilesFilteringViewModel.FiltersSelection = .empty

    @Published private var networkMonitor: NetworkMonitor

    private var selfUserID: String? {
        conversations
            .flatMap(\.participants)
            .first(where: \.isSelfUser)?.id
    }

    package init(
        useCases: UseCases,
        title: String? = nil,
        navigationPath: [FilesViewItem] = [],
        setNavigation: @escaping ([FilesViewItem]) -> Void = { _ in },
        isCellsStatePending: Bool,
        localAssetRepository: any WireDriveLocalAssetRepositoryProtocol,
        nodesRepository: any WireDriveNodesRepositoryProtocol,
        fileCache: any FileCache,
        cellName: String? = nil,
        isBrowsing: Bool,
        isRecycleBin: Bool = false,
        triggerReload: PassthroughSubject<Void, Never> = .init(),
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.useCases = useCases
        self.title = title
        self.navigationPath = navigationPath
        self.setNavigation = setNavigation
        self.localAssetRepository = localAssetRepository
        self.nodesRepository = nodesRepository
        self.fileCache = fileCache
        self.cellName = cellName
        self.state = isCellsStatePending ? .pending : .loading
        self.isBrowsing = isBrowsing
        self.isRecycleBin = isRecycleBin
        self.triggerReload = triggerReload
        self.networkMonitor = networkMonitor
    }

    func setup() async {
        await fetchConversations()
        bindSearch()
        fetchTemplates()
        Task { await reload() }
    }

    /// Reloads the items, clearing any previously loaded items.
    /// - Parameters:
    ///   - refreshing: Whether the reload was triggered by a pull-to-refresh action.
    ///
    /// Cancels any ongoing load operation and starts a new one.
    /// When `refreshing` is `true`, the current state is preserved since loading is managed by the system.

    func reload(refreshing: Bool = false) async {
        guard networkMonitor.currentStatus != nil else { return  }

        cancelLoad()
        state = refreshing ? state : .loading
        hasMore = !refreshing

        await loadMore(refreshing: refreshing)
    }

    /// Loads more items if available and `index` is towards the end of the list.
    ///
    /// This method checks if the `index` is within the threshold for loading more items. For example given a threshold
    /// of 5, when 10 items are loaded, it will load more when the index is 5 or above - i.e. when one of the last 5
    /// items is being displayed.
    ///
    /// - Parameter index: The index of the item which requested load more.
    func loadMoreIfNeeded(index: Int) async {
        let remaining = state.items.count - index - 1
        if remaining < Constants.loadMoreThreshold, hasMore {
            await loadMore()
        }
    }

    /// Returns a `FilesItemViewModel` for the item at the given index.
    func itemViewModel(index: Int) -> FilesItemViewModel {
        FilesItemViewModel(
            item: state.items[index],
            selectedSortingKey: sortingSelection.sortingKey,
            conversationName: isBrowsing ? state.items[index].conversationName : nil,
            localAssetRepository: localAssetRepository,
            onItemAction: { [weak self] action, item in
                guard let self else { return }
                switch action {
                case .primaryAction:
                    await performPrimaryAction(item: item)
                case .deleteToRecycleBin:
                    await deleteItem(item, permanently: false)
                case .deletePermanently:
                    await deleteItem(item, permanently: true)
                case .restore:
                    await restoreItem(item)
                case .rename:
                    sheetNavigation = .renameFile(view: makeFileRenameView(item: item))
                case .editTags:
                    sheetNavigation = .editTags(fileItem: item)
                case .shareLink:
                    sheetNavigation = .shareLink(view: makeShareLinkView(item: item))
                case .moveToFolder:
                    sheetNavigation = .moveToFolder(fileItem: item)
                case .showVersionHistory:
                    sheetNavigation = .versionHistory(view: makeFileVersioningView(item: item))
                case .edit:
                    isEditing = item
                case .makeAvailableOffline:
                    makeAssetAvailableOffline(item: item)
                case .removeAvailableOffline:
                    removeAssetAvailableOffline(item: item)
                }
            },
            isBrowsing: isBrowsing,
            isInRecycleBin: isRecycleBin,
        )
    }

    func moveToFolderView(item: FilesViewItem) -> some View {
        let containerPath = item.filePath.components(separatedBy: "/").dropLast().joined(separator: "/")
        let nodesRepository = nodesRepository
        let assetRepository = localAssetRepository
        let useCases = useCases
        return MoveToFolderView(
            viewModel: MoveToFolderViewModel(
                containerPath: containerPath,
                nodeID: item.id,
                nodeName: item.name,
                onFinish: { [weak self] in
                    self?.sheetNavigation = nil
                    Task { await self?.reload(refreshing: true) }
                },
                nodesRepository: nodesRepository,
                localAssetRepository: assetRepository,
                moveNodeUseCase: WireDriveMoveNodeUseCase(
                    nodesRepository: nodesRepository,
                    localAssetRepository: assetRepository
                ),
                createFileUseCase: useCases.createFile
            )
        )
    }

    func editFileView(item: FilesViewItem) -> some View {
        let getEditingURLUseCase = useCases.getEditingURL
        return EditFileView(
            viewModel: EditFileViewModel(
                nodeID: item.id,
                fileName: item.name,
                getEditingURLUseCase: getEditingURLUseCase
            )
        )
    }

    /// If item is a folder, navigates into it. If it's a file, downloads the related asset if necessary or views it or
    /// cancels the download.
    func performPrimaryAction(item: FilesViewItem) async {
        switch item.kind {
        case .file:
            await viewAsset(item: item)
        case .folder:
            openFolder(item: item)
        }
    }

    var folderMenuOptions: [FolderMenuOption] {
        var options: [FolderMenuOption] = navigationPath.reversed().map { .folder(nodeID: $0.id, title: $0.name) }
        options.append(.root)
        options.removeFirst()
        return options
    }

    func selectFolderMenuOption(_ option: FolderMenuOption) {
        let newPath: [FilesViewItem] = switch option {
        case let .folder(nodeID, _):
            if let index = navigationPath.firstIndex(where: { $0.id == nodeID }) {
                Array(navigationPath.prefix(upTo: index + 1))
            } else {
                []
            }
        case .root:
            []
        }

        setNavigation(newPath)
    }

    var isInFolder: Bool {
        !navigationPath.isEmpty
    }

    // MARK: - Private

    private func fetchTemplates() {
        Task {
            templates = try await useCases.getFileTemplates.invoke()
        }
    }

    private func fetchConversations() async {
        let allDriveConversations = await useCases.getDriveConversations.invoke()

        if let cellName {
            conversations = allDriveConversations.filter { $0.id == cellName }
        } else {
            conversations = allDriveConversations
        }
    }

    private func bindSearch() {
        $searchText
            .removeDuplicates()
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.reload() }
            }
            .store(in: &subscriptions)
    }

    /// Navigates to the folder represented by the given item.
    private func openFolder(item: FilesViewItem) {
        precondition(item.kind == .folder)

        var targetItem = item

        if isRecycleBin {
            let pathComponents = targetItem.filePath.split(separator: "/").map { String($0) }
            if pathComponents.count == 3 {
                // remember the id of the top folder in the recycle bin for later when an item in a subfolder will be
                // restored
                targetItem.recycleBinTopFolderId = targetItem.id
            } else if pathComponents.count > 3 {
                // for the next subfolder, just assign the id of the same top folder
                if let previousItem = navigationPath.last,
                   let recycleBinTopFolderId = previousItem.recycleBinTopFolderId {
                    targetItem.recycleBinTopFolderId = recycleBinTopFolderId
                }
            }
        }

        setNavigation(navigationPath + [targetItem])
    }

    /// Downloads if necessary or views the asset represented by the given item or cancels the download.
    private func viewAsset(item: FilesViewItem) async {
        precondition(item.kind == .file)

        do {
            let downloadState = try await useCases.getAsset.downloadState(nodeID: item.id) ?? .pending
            switch downloadState {
            case .pending, .failed:
                _ = try await useCases.getAsset.invoke(nodeID: item.id, eTag: item.eTag)
            case .downloaded:
                viewingURL = nil
                let url = try await useCases.getAsset.invoke(nodeID: item.id, eTag: item.eTag)
                viewingURL = url
            case .downloading:
                await useCases.getAsset.cancelDownload(nodeID: item.id)
            }
        } catch is CancellationError {
            // Cancelled by the user, ignore.
        } catch URLError.notConnectedToInternet, URLError.networkConnectionLost {
            alert = .noInternet
        } catch {
            alert = .unknownError
        }
    }

    func onCreate(target: WireDriveCreateFileUseCase.Target) {
        guard let cellName else { return }

        // When navigation path is empty, file/folder is created at the root path (cell name)
        let path = navigationPath.last?.filePath ?? cellName

        let viewModel = CreateFileViewModel(
            creationTarget: target,
            path: path,
            createFileUseCase: useCases.createFile,
            onNodeCreated: { [weak self] createdNode in
                guard let self else { return }
                if case .file = target {
                    isEditing = makeFileViewItem(node: createdNode)
                }
                Task {
                    await reload()
                }
            }
        )

        let createFileView = CreateFileView(
            viewModel: viewModel
        )

        sheetNavigation = .create(view: createFileView)
    }

    // MARK: - Private

    private func cancelLoad() {
        loadMoreTask?.cancel()
        loadMoreTask = nil
    }

    private func loadMore(refreshing: Bool = false) async {
        if isOffline {
            await loadOfflineFiles()
        } else {
            await loadOnlineFiles(refreshing: refreshing)
        }
    }

    private func loadOnlineFiles(refreshing: Bool) async {
        guard loadMoreTask == nil else { return }

        let offset = refreshing ? 0 : state.items.count
        let task = Task { try await fetchItems(offset: offset) }

        loadMoreTask = task
        do {
            let (newItems, isLastPage) = try await task.value
            let receivedItems = refreshing ? newItems : state.items + newItems
            state = .received(items: receivedItems.latestModified())
            hasMore = !isLastPage
        } catch is CancellationError {
            return // developer-driven error, discard
        } catch {
            if state.items.isEmpty {
                state = .error(isConnectionError: error.isNoInternetError)
            } else {
                if error.isNoInternetError {
                    // no-op, offline bar is dynamically shown/hidden on top of the list
                } else {
                    alert = .unknownError
                }
            }
            hasMore = state.items.isEmpty ? true : hasMore
        }
        loadMoreTask = nil
    }

    private func loadOfflineFiles() async {
        guard !isRecycleBin else {
            return state = .received(items: [])
        }

        do {
            let actionInput = LoadOfflineAvailableFilesUIAction.Input(
                conversationName: cellName != nil ? conversations.first?.name : nil,
                assetsPath: navigationPath.last?.filePath,
                getAsset: useCases.getAsset,
                getOfflineAvailableAssets: useCases.getOfflineAvailableAssets
            )

            let items = try await LoadOfflineAvailableFilesUIAction(input: actionInput)()

            state = .received(items: items)
        } catch {
            alert = .unknownError
            WireLogger.wireDrive.error("Error fetching offline assets:\n\(error)")
        }
        hasMore = false
    }

    private nonisolated func fetchItems(
        offset: Int
    ) async throws -> (items: [FilesViewItem], isLastPage: Bool) {
        let (nodes, isLastPage) = try await useCases.fetchNodes.invoke(
            searchTerm: searchText.isEmpty ? nil : searchText,
            metafilter: filtersSelection.toDomainModel(selfUserID: selfUserID),
            sortField: sortingSelection.sortingKey?.sortField,
            sortDirDesc: sortingSelection.sortingOrder == .descending,
            offset: offset
        )

        let items: [FilesViewItem] = nodes.compactMap(makeFileViewItem(node:))

        try Task.checkCancellation()
        return (items, isLastPage)
    }

    private func deleteItem(_ asset: FilesViewItem, permanently: Bool) async {
        guard state.isLoaded else {
            WireLogger.wireDrive.error("Attempt to delete asset while not visible", attributes: .safePublic)
            return
        }

        var currentItems = state.items
        currentItems.removeAll { $0.id == asset.id }
        state = .received(items: currentItems.latestModified())

        do {
            try await useCases.deleteNodes.invoke(nodeIDs: [asset.id], deletePermanently: permanently)
        } catch {
            guard state.isLoaded else { return }

            var currentItems = state.items
            currentItems.append(asset)
            state = .received(items: currentItems.latestModified())
        }
    }

    private nonisolated func makeFileViewItem(node: WireDriveNode) -> FilesViewItem? {
        guard let eTag = node.eTag else { return nil }

        let url = URL(string: node.path)
        let kind: FilesViewItem.Kind = node.type == .collection ? .folder : .file
        return FilesViewItem(
            id: node.id,
            eTag: eTag,
            kind: kind,
            name: url?.lastPathComponent ?? node.path,
            filePath: node.path,
            ownedBy: node.ownerUserName,
            modifiedAt: node.modified,
            icon: kind == .folder ? .folder : .make(
                type: node.mimeType.map { UTType(mimeType: $0) } ?? nil,
                fileExtension: url?.pathExtension
            ),
            tags: node.tags,
            isEditable: node.isEditable,
            publicLinkID: node.publicLinkID?.string,
            conversationName: node.conversation?.name,
            size: node.size
        )
    }

    private func restoreItem(_ asset: FilesViewItem) async {
        guard state.isLoaded else {
            WireLogger.wireDrive.error("Attempt to restore asset while not visible", attributes: .safePublic)
            return
        }

        var currentItems = state.items
        currentItems.removeAll { $0.id == asset.id }
        state = .received(items: currentItems.latestModified())

        let nodeIdToRestore = navigationPath.last?.recycleBinTopFolderId ?? asset.id

        do {
            try await useCases.restoreNodes.invoke(nodeIDs: [nodeIdToRestore])

            setNavigation([])
        } catch {
            guard state.isLoaded else { return }

            var currentItems = state.items
            currentItems.append(asset)
            state = .received(items: currentItems.latestModified())
        }
    }

    private func makeFileRenameView(
        item: FilesViewItem
    ) -> FileRenameView {
        let viewModel = FileRenameViewModel(
            renameNodeUseCase: useCases.renameNode,
            model: .init(
                nodeID: item.id,
                filename: item.name,
                filepath: item.filePath,
            ),
            kind: item.kind,
            onRenamed: { [weak self] in
                Task { await self?.reload() }
            }
        )

        return FileRenameView(viewModel: viewModel)
    }

    private func makeShareLinkView(
        item: FilesViewItem
    ) -> ShareLinkView {

        let viewModel = ShareLinkView.ViewModel(
            fileItem: item,
            useCases: ShareLinkView.ViewModel.UseCases(
                getLinkData: useCases.getPublicLinkData,
                createPublicLink: useCases.createPublicLink,
                deletePublicLink: useCases.deletePublicLink,
                updatePublicLinkExpiration: useCases.updatePublicLinkExpiration,
                updatePublicLinkPassword: useCases.updatePublicLinkPassword,
                getPublicLinkPasswordUseCase: WireDriveGetPublicLinkPasswordUseCase(keychain: Keychain()),
                storePublicLinkPasswordUseCase: WireDriveStorePublicLinkPasswordUseCase(keychain: Keychain()),
                deletePublicLinkPasswordUseCase: WireDriveDeletePublicLinkPasswordUseCase(keychain: Keychain())
            ),
            onLinkStateChanged: { [weak self] state in
                switch state {
                case .enabled, .disabled:
                    Task { await self?.reload() }
                default:
                    break
                }
            }
        )

        return ShareLinkView(viewModel: viewModel)
    }

    private func makeFileVersioningView(
        item: FilesViewItem
    ) -> FileVersioningView {
        let viewModel = FileVersioningViewModel(
            nodeID: item.id,
            name: item.name,
            eTag: item.eTag,
            fetchNodeVersionsUseCase: useCases.fetchNodeVersions,
            restoreNodeVersionUseCase: useCases.restoreNodeVersion,
            getAssetUseCase: useCases.getAsset,
            onVersionRestored: { [weak self] in
                Task { await self?.reload() }
            }
        )

        return FileVersioningView(viewModel: viewModel)
    }

    // MARK: - Sorting & Filtering

    func makeFilesSortingViewModel() -> FilesSortingViewModel {
        FilesSortingViewModel(
            isBrowsing: isBrowsing,
            subfolderName: navigationPath.last?.name
        ) { [weak self] sortingSelection in
            self?.sortingSelection = sortingSelection
            Task { await self?.reload() }
        }
    }

    func resetFilters() {
        filtersSelection = .empty
        sortingSelection = .default
    }

    func onUpdate(of filters: FilesFilteringViewModel.FiltersSelection) {
        guard filters != filtersSelection else { return }
        filtersSelection = filters
        Task { await reload() }
    }

    // MARK: - Offline mode

    private func makeAssetAvailableOffline(item: FilesViewItem) {
        Task {
            do {
                try await useCases.makeAssetAvailableOffline.invoke(nodeID: item.id)
            } catch {
                WireLogger.wireDrive.error("Failed to make asset available offline: \(String(describing: error))")
            }
        }
    }

    private func removeAssetAvailableOffline(item: FilesViewItem) {
        Task {
            do {
                try await useCases.removeAssetAvailableOffline.invoke(nodeID: item.id)

                if isOffline {
                    await reload()
                }
            } catch {
                WireLogger.wireDrive
                    .error("Failed to remove asset from available offline: \(String(describing: error))")
            }
        }
    }
}

private extension Collection<FilesViewItem> {
    /// Removes items with duplicate IDs keeping the latest modified if known, otherwise the first.
    func latestModified() -> [FilesViewItem] {
        var latestByID: [UUID: FilesViewItem] = [:]
        for item in self {
            if let existing = latestByID[item.id] {
                let existingDate = existing.modifiedAt ?? .distantPast
                let newDate = item.modifiedAt ?? .distantPast
                if newDate > existingDate {
                    latestByID[item.id] = item
                }
            } else {
                latestByID[item.id] = item
            }
        }

        var results: [FilesViewItem] = []
        for item in self where item == latestByID[item.id] {
            results.append(item)
        }

        return results
    }
}
