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
import Foundation
import WireLogging
package import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

/// View model for the `FilesView`.
@MainActor
package final class FilesViewModel: ObservableObject {

    enum SheetNavigation: Identifiable {
        case create(target: WireDriveCreateFileUseCase.Target)
        case editTags(fileItem: FilesViewItem)
        case shareLink(fileItem: FilesViewItem)
        case moveToFolder(fileItem: FilesViewItem)
        case renameFile(fileItem: FilesViewItem)
        case versionHistory(fileItem: FilesViewItem)

        var id: String {
            switch self {
            case let .create(target):
                "create(\(target.id))"
            case let .editTags(item):
                "editTags(\(item.id))"
            case let .shareLink(item):
                "shareLink(\(item.id))"
            case let .moveToFolder(item):
                "moveToFolder(\(item.id))"
            case let .renameFile(item):
                "renameFile(\(item.id))"
            case let .versionHistory(item):
                "versionHistory(\(item.id))"
            }
        }
    }

    /// An navigation option displayed in the navigation folder menu.
    enum FolderMenuOption: Hashable {
        case folder(nodeID: UUID, title: String)
        case root
    }

    private let setNavigation: ([FilesViewItem]) -> Void
    private var subscriptions = Set<AnyCancellable>()
    let cellName: String? // nil when browsing all files
    let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol
    let nodesRepository: any WireDriveNodesRepositoryProtocol
    let navigationPath: [FilesViewItem]
    var sortingSelection: FilesSortingViewModel.SortingSelection = .default
    let useCases: UseCases
    let isBrowsing: Bool
    let isRecycleBin: Bool
    let triggerReload: PassthroughSubject<Void, Never>
    let title: String?

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

    private var selfUserID: String? {
        conversations
            .flatMap(\.participants)
            .first(where: \.isSelfUser)?.id
    }

    @Published var searchText = ""
    @Published var alert: AlertModel?
    @Published var viewingURL: URL?
    @Published var sheetNavigation: SheetNavigation?
    @Published var isEditing: FilesViewItem?
    @Published var templates: [WireDriveFileTemplate] = []
    @Published var conversations: [WireDriveConversation] = []
    @Published var filtersSelection: FilesFilteringViewModel.FiltersSelection = .empty
    @Published var networkMonitor: NetworkMonitor
    @Published var filesListLoader: FilesListLoader

    var state: FilesListLoader.Loader.State {
        filesListLoader.loader.state
    }

    // MARK: init

    package init(
        useCases: UseCases,
        title: String? = nil,
        navigationPath: [FilesViewItem] = [],
        setNavigation: @escaping ([FilesViewItem]) -> Void = { _ in },
        isCellsStatePending: Bool,
        localAssetRepository: any WireDriveLocalAssetRepositoryProtocol,
        nodesRepository: any WireDriveNodesRepositoryProtocol,
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
        self.cellName = cellName
        self.isBrowsing = isBrowsing
        self.isRecycleBin = isRecycleBin
        self.triggerReload = triggerReload
        self.networkMonitor = networkMonitor
        self.filesListLoader = .init(networkMonitor: networkMonitor)
        filesListLoader.loader.state = isCellsStatePending ? .pending : .loading
    }

    // MARK: setup

    func setup() async {
        setupFilesLoader()
        fetchConversations()
        fetchTemplates()
        bindSearch()
        Task { await reload() }
    }

    func setupFilesLoader() {
        filesListLoader.onFetchOnlineFiles = { [weak self] offset in
            guard let self else { return (items: [], isLastPage: true) }

            let (nodes, isLastPage) = try await useCases.fetchNodes.invoke(
                searchTerm: searchText.isEmpty ? nil : searchText,
                metafilter: filtersSelection.toDomainModel(selfUserID: selfUserID),
                sortField: sortingSelection.sortingKey?.sortField,
                sortDirDesc: sortingSelection.sortingOrder == .descending,
                offset: offset
            )

            let items: [FilesViewItem] = nodes.compactMap(FilesViewItem.fromNode(_:))

            return (items, isLastPage)
        }

        filesListLoader.onFetchOfflineFiles = { [weak self] in
            guard let self else { return [] }

            let actionInput = LoadOfflineAvailableFilesUIAction.Input(
                conversationName: cellName != nil ? conversations.first?.name : nil,
                assetsPath: navigationPath.last?.filePath,
                getAsset: useCases.getAsset,
                getOfflineAvailableAssets: useCases.getOfflineAvailableAssets
            )

            return try await LoadOfflineAvailableFilesUIAction(input: actionInput)()
        }

        filesListLoader.onErrorToPresent = { [weak self] _ in
            self?.alert = .unknownError
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

    // MARK: fetch general data

    private func fetchTemplates() {
        Task {
            do {
                templates = try await useCases.getFileTemplates.invoke()
            } catch {
                WireLogger.wireDrive.error("Failed to fetch templates: \(error)", attributes: .safePublic)
            }
        }
    }

    private func fetchConversations() {
        Task {
            let allDriveConversations = await useCases.getDriveConversations.invoke()

            if let cellName {
                conversations = allDriveConversations.filter { $0.id == cellName }
            } else {
                conversations = allDriveConversations
            }
        }
    }

    // MARK: load files

    func reload(refreshing: Bool = false) async {
        guard networkMonitor.currentStatus != nil else { return }

        await filesListLoader.loader.reload(refreshing: refreshing)
    }

    func loadMoreIfNeeded(index: Int) async {
        await filesListLoader.loader.loadMoreIfNeeded(index: index)
    }

    // MARK: folders

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

    // MARK: open file/folder

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
        guard cellName != nil else { return }
        sheetNavigation = .create(target: target)
    }

    // MARK: recycle bin

    func deleteItem(_ asset: FilesViewItem, permanently: Bool) async {
        guard state.isLoaded else {
            WireLogger.wireDrive.error("Attempt to delete asset while not visible", attributes: .safePublic)
            return
        }

        await filesListLoader.removeItem(asset) { [weak self] in
            try await self?.useCases.deleteNodes.invoke(nodeIDs: [asset.id], deletePermanently: permanently)
        }
    }

    func restoreItem(_ asset: FilesViewItem) async {
        guard state.isLoaded else {
            WireLogger.wireDrive.error("Attempt to restore asset while not visible", attributes: .safePublic)
            return
        }

        await filesListLoader.removeItem(asset) { [weak self] in
            guard let self else { return }
            let nodeIdToRestore = navigationPath.last?.recycleBinTopFolderId ?? asset.id
            try await useCases.restoreNodes.invoke(nodeIDs: [nodeIdToRestore])
            setNavigation([])
        }
    }

    // MARK: search

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

    // MARK: filters

    func onUpdate(of filters: FilesFilteringViewModel.FiltersSelection) {
        guard filters != filtersSelection else { return }
        filtersSelection = filters
        Task { await reload() }
    }

    func resetFilters() {
        filtersSelection = .empty
        sortingSelection = .default
    }

    // MARK: offline mode

    var networkStatus: NetworkMonitor.NetworkStatus? {
        networkMonitor.currentStatus
    }

    var isOffline: Bool {
        networkMonitor.currentStatus == .disconnected
    }

    var shouldShowOfflineBar: Bool {
        isOffline && !state.items.isEmpty
    }

    func makeAssetAvailableOffline(item: FilesViewItem) {
        Task {
            do {
                try await useCases.makeAssetAvailableOffline.invoke(nodeID: item.id)
            } catch {
                WireLogger.wireDrive.error("Failed to make asset available offline: \(String(describing: error))")
            }
        }
    }

    func removeAssetAvailableOffline(item: FilesViewItem) {
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
