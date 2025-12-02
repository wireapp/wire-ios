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

    /// Identifier of this item on the wire cells backend.
    package let id: UUID

    /// The id of the topmost folder in the recycle bin, if the item is not at the root of the recycle bin.
    /// Needed to restore items which are in folders rather than directly at the root of the recycle bin.
    var recycleBinTopFolderId: UUID?

    /// The kind of this item - file or folder.
    let kind: Kind

    /// The name of the user who owns (uploaded or created) this item.
    let name: String

    /// The filepath of the item.
    let filePath: String

    /// The name of the user who owns (uploaded) this file.
    let ownedBy: String?

    /// The date when the item was last modified.
    let modifiedAt: Date?

    /// The icon representing the item's type.
    let icon: FileIcon

    /// The tags that users have added for that file.
    let tags: [String]
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
        case shareLink(fileItem: FilesViewItem)
        case renameFile(view: FileRenameView)
        case createFolder(view: CreateFolderView)
        case filters(view: FilesFiltersView)

        var id: String {
            switch self {
            case let .editTags(fileItem: item):
                "editTags(\(item.id))"
            case let .shareLink(fileItem: item):
                "shareLink(\(item.id))"
            case let .createFolder(view):
                "createFolder(\(view.id))"
            case let .renameFile(view):
                "renameFile(\(view.id))"
            case let .filters(view):
                "filters(\(view.id))"
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
        case pending // cells are not ready yet
        case error

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
            fetchNodes: WireCellsFetchNodesUseCase,
            deleteNodes: WireCellsDeleteNodesUseCase,
            restoreNodes: WireCellsRestoreNodesUseCase,
            renameNode: any WireCellsRenameNodeUseCaseProtocol,
            updateTags: any WireCellsUpdateTagsUseCaseProtocol,
            getTagSuggestions: any WireCellsGetTagSuggestionsUseCaseProtocol,
            createFolder: any WireCellsCreateFolderUseCaseProtocol,
        ) {

            self.fetchNodes = fetchNodes
            self.deleteNodes = deleteNodes
            self.restoreNodes = restoreNodes
            self.renameNode = renameNode
            self.updateTags = updateTags
            self.getTagSuggestions = getTagSuggestions
            self.createFolder = createFolder
        }

        let fetchNodes: WireCellsFetchNodesUseCase
        let deleteNodes: WireCellsDeleteNodesUseCase
        let restoreNodes: WireCellsRestoreNodesUseCase
        let renameNode: any WireCellsRenameNodeUseCaseProtocol
        let updateTags: any WireCellsUpdateTagsUseCaseProtocol
        let getTagSuggestions: any WireCellsGetTagSuggestionsUseCaseProtocol
        let createFolder: any WireCellsCreateFolderUseCaseProtocol
    }

    let useCases: UseCases

    private let setNavigation: ([FilesViewItem]) -> Void
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private let fileCache: any FileCache
    private var lastSelectedItem: FilesViewItem?
    private let cellName: String? // nil when browsing all files
    private var subscriptions = Set<AnyCancellable>()
    private let navigationPath: [FilesViewItem]
    private let accentColorProvider: () -> WireAccentColor
    let isFoldersEnabled: Bool
    let isRecycleBin: Bool
    let triggerReload: PassthroughSubject<Void, Never>

    @Published var hasMore = true
    @Published private var loadMoreTask: LoadItemsTask?
    @Published var searchText = ""
    @Published var alert: AlertModel?
    @Published var viewingURL: URL?
    @Published var state: State
    @Published var sheetNavigation: SheetNavigation?

    var shouldReload: Bool = false
    var filterWithTags: [String] = []
    let title: String?
    var showSearchBar: Bool {
        state != .error && state != .pending
    }

    package init(
        useCases: UseCases,
        title: String? = nil,
        navigationPath: [FilesViewItem] = [],
        setNavigation: @escaping ([FilesViewItem]) -> Void = { _ in },
        isCellsStatePending: Bool,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        fileCache: any FileCache,
        cellName: String? = nil,
        isFoldersEnabled: Bool,
        isRecycleBin: Bool = false,
        triggerReload: PassthroughSubject<Void, Never> = .init(),
        accentColorProvider: @escaping () -> WireAccentColor
    ) {
        self.useCases = useCases
        self.title = title
        self.navigationPath = navigationPath
        self.setNavigation = setNavigation
        self.localAssetRepository = localAssetRepository
        self.fileCache = fileCache
        self.cellName = cellName
        self.state = isCellsStatePending ? .pending : .loading
        self.isFoldersEnabled = isFoldersEnabled
        self.isRecycleBin = isRecycleBin
        self.triggerReload = triggerReload
        self.accentColorProvider = accentColorProvider

        bindSearch()
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

    /// Reloads the items, clearing any previously loaded items.
    /// - Parameters:
    ///   - refreshing: Whether the reload was triggered by a pull-to-refresh action.
    ///
    /// Cancels any ongoing load operation and starts a new one.
    /// When `refreshing` is `true`, the current state is preserved since loading is managed by the system.

    func reload(refreshing: Bool = false) async {
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
            localAssetRepository: localAssetRepository,
            onItemAction: { [weak self] action, item in
                guard let self else { return }
                switch action {
                case .open:
                    await openItem(item: item)
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
                    sheetNavigation = .shareLink(fileItem: item)
                }
            },
            isInRecycleBin: isRecycleBin,
        )
    }

    func openFilters() {
        let filesFiltersViewModel = FilesFiltersViewModel(
            fetchTagsUseCase: useCases.getTagSuggestions,
            savedTags: filterWithTags,
            accentColorProvider: accentColorProvider
        )

        filesFiltersViewModel.$savedTags
            .sink { [weak self] tags in
                guard let self else { return }
                shouldReload = filterWithTags != tags
                filterWithTags = tags
            }.store(in: &subscriptions)

        sheetNavigation = .filters(
            view: FilesFiltersView(viewModel: filesFiltersViewModel)
        )
    }

    /// If item is a folder, navigates into it. If it's a file, downloads the related asset if necessary and views it.
    func openItem(item: FilesViewItem) async {
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

    func onSheetDismissed() async {
        if shouldReload {
            await reload()
            shouldReload = false
        }
    }

    // MARK: - Private

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

    /// Downloads if necessary and views the asset represented by the given item.
    private func viewAsset(item: FilesViewItem) async {
        precondition(item.kind == .file)

        // Bookkeeping ensure we only attempt to display the most recently selected item.
        lastSelectedItem = item

        do {
            if let url = try await localURL(for: item), item == lastSelectedItem {
                viewingURL = url
            }
        } catch URLError.notConnectedToInternet, URLError.networkConnectionLost {
            alert = .noInternet
        } catch {
            alert = .unknownError
        }
    }

    func onCreateFolder() {
        guard let cellName else { return }

        // When navigation path is empty, folder is created at the root path (cell name)
        let folderPath = navigationPath.last?.filePath ?? cellName

        let viewModel = CreateFolderViewModel(
            createFolderUseCase: useCases.createFolder,
            folderPath: folderPath
        )

        // to know whether we need to reload nodes.
        viewModel.$didCreate
            .filter(\.self)
            .sink { [weak self] didCreate in
                self?.shouldReload = didCreate
            }.store(in: &subscriptions)

        let createFolderView = CreateFolderView(
            viewModel: viewModel
        )

        sheetNavigation = .createFolder(view: createFolderView)
    }

    // MARK: - Private

    private func localURL(for item: FilesViewItem) async throws -> URL? {
        // If the file is already downloaded, return the local URL.
        if
            let cacheKey = try localAssetRepository.asset(nodeID: item.id)?.downloadState.cacheKey,
            let url = fileCache.fileURL(forKey: cacheKey) {
            return url
        }

        let cacheKey: String?
        do {
            try await localAssetRepository.downloadAsset(nodeID: item.id)
            cacheKey = try localAssetRepository.asset(nodeID: item.id)?.downloadState.cacheKey
        } catch WireCellsLocalAssetRepositoryError.downloadAlreadyInProgress {
            try await awaitDownload(item: item)
            cacheKey = try localAssetRepository.asset(nodeID: item.id)?.downloadState.cacheKey
        }
        return cacheKey.flatMap { fileCache.fileURL(forKey: $0) }
    }

    private func cancelLoad() {
        loadMoreTask?.cancel()
        loadMoreTask = nil
    }

    private func loadMore(refreshing: Bool = false) async {
        guard loadMoreTask == nil else { return }

        let offset = refreshing ? 0 : state.items.count
        let task = Task { try await fetchItems(offset: offset) }

        loadMoreTask = task
        do {
            let (newItems, isLastPage) = try await task.value
            let receivedItems = Self.processItems(refreshing ? newItems : state.items + newItems)
            state = .received(items: receivedItems)
            hasMore = !isLastPage
        } catch is CancellationError {
            return // developer-driven error, discard
        } catch {
            if state.items.isEmpty {
                state = .error
            } else {
                let urlError = (error as? URLError)?.code
                let isNoInternetError = urlError == .notConnectedToInternet || urlError == .networkConnectionLost
                alert = isNoInternetError ? .noInternet : .unknownError
            }

            hasMore = state.items.isEmpty ? true : hasMore
        }
        loadMoreTask = nil
    }

    private nonisolated func fetchItems(
        offset: Int
    ) async throws -> (items: [FilesViewItem], isLastPage: Bool) {
        let (nodes, isLastPage) = try await useCases.fetchNodes.invoke(
            searchTerm: searchText.isEmpty ? nil : searchText,
            tags: filterWithTags,
            offset: offset
        )

        let items = nodes.map { node in
            let url = URL(string: node.path)
            let kind: FilesViewItem.Kind = node.type == .collection ? .folder : .file
            return FilesViewItem(
                id: node.id,
                kind: kind,
                name: url?.lastPathComponent ?? node.path,
                filePath: node.path,
                ownedBy: node.ownerUserName,
                modifiedAt: node.modified,
                icon: kind == .folder ? .folder : .make(
                    type: node.mimeType.map { UTType(mimeType: $0) } ?? nil,
                    fileExtension: url?.pathExtension
                ),
                tags: node.tags
            )
        }

        try Task.checkCancellation()
        return (items, isLastPage)
    }

    private func awaitDownload(item: FilesViewItem) async throws {
        for await item in localAssetRepository.observeAsset(nodeID: item.id).values {
            try Task.checkCancellation()

            switch item?.downloadState {
            case .downloaded:
                return
            case let .failed(error):
                throw error
            default:
                break
            }
        }
    }

    private func deleteItem(_ asset: FilesViewItem, permanently: Bool) async {
        guard state.isLoaded else {
            WireLogger.wireCells.error("Attempt to delete asset while not visible", attributes: .safePublic)
            return
        }

        var currentItems = state.items
        currentItems.removeAll { $0.id == asset.id }
        state = .received(items: Self.processItems(currentItems))

        do {
            try await useCases.deleteNodes.invoke(nodeIDs: [asset.id], deletePermanently: permanently)
        } catch {
            guard state.isLoaded else { return }

            var currentItems = state.items
            currentItems.append(asset)
            state = .received(items: Self.processItems(currentItems))
        }
    }

    private func restoreItem(_ asset: FilesViewItem) async {
        guard state.isLoaded else {
            WireLogger.wireCells.error("Attempt to restore asset while not visible", attributes: .safePublic)
            return
        }

        var currentItems = state.items
        currentItems.removeAll { $0.id == asset.id }
        state = .received(items: Self.processItems(currentItems))

        let nodeIdToRestore = navigationPath.last?.recycleBinTopFolderId ?? asset.id

        do {
            try await useCases.restoreNodes.invoke(nodeIDs: [nodeIdToRestore])

            setNavigation([])
        } catch {
            guard state.isLoaded else { return }

            var currentItems = state.items
            currentItems.append(asset)
            state = .received(items: Self.processItems(currentItems))
        }
    }

    /// Removes items with duplicate IDs keeping the latest modified if known, otherwise the first.
    private static func processItems(_ items: [FilesViewItem]) -> [FilesViewItem] {
        var latestByID: [UUID: FilesViewItem] = [:]
        for item in items {
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
        for item in items where item == latestByID[item.id] {
            results.append(item)
        }

        return results
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
            kind: item.kind
        )

        // to know whether we need to reload items.
        viewModel.$didRename
            .sink { [weak self] didRename in
                self?.shouldReload = didRename
            }.store(in: &subscriptions)

        return FileRenameView(viewModel: viewModel)
    }

}
