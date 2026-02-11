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
package import WireFoundation
package import WireMessagingDomain
package import WireMessagingData

package struct FilesViewContainer: View {
    @Environment(\.dismiss) private var dismiss

    @State private var path: [FilesViewItem] = []

    private let cellName: String
    private let nodesAPI: NodesAPI
    private let nodesRepository: any WireDriveNodesRepositoryProtocol
    private let isCellsStatePending: Bool
    private let localAssetStore: any WireDriveLocalAssetStoreProtocol
    private let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol
    private let nodeCache: any WireDriveNodeCacheProtocol
    private let nodeRenameNotifier: WireDriveNodeRenameNotifier
    private let fileCache: any FileCache
    private let accentColorProvider: () -> WireAccentColor

    private let triggerReloadFiles: PassthroughSubject<Void, Never> = .init()

    enum FullScreenCoverNavigation: String, Identifiable {
        case recycleBin

        var id: String { rawValue }
    }

    @State private var fullScreenCoverNavigation: FullScreenCoverNavigation?

    package init(
        cellName: String,
        nodesAPI: NodesAPI,
        nodesRepository: any WireDriveNodesRepositoryProtocol,
        isCellsStatePending: Bool,
        localAssetStore: any WireDriveLocalAssetStoreProtocol,
        localAssetRepository: any WireDriveLocalAssetRepositoryProtocol,
        nodeCache: any WireDriveNodeCacheProtocol,
        nodeRenameNotifier: WireDriveNodeRenameNotifier,
        fileCache: any FileCache,
        accentColorProvider: @escaping () -> WireAccentColor
    ) {
        self.cellName = cellName
        self.nodesAPI = nodesAPI
        self.nodesRepository = nodesRepository
        self.isCellsStatePending = isCellsStatePending
        self.localAssetStore = localAssetStore
        self.localAssetRepository = localAssetRepository
        self.nodeCache = nodeCache
        self.nodeRenameNotifier = nodeRenameNotifier
        self.fileCache = fileCache
        self.accentColorProvider = accentColorProvider
    }

    var body: some View {
        let onOpenRecycleBin: () -> Void = {
            fullScreenCoverNavigation = .recycleBin
        }

        NavigationStack(path: $path) {
            FilesView(viewModel: makeViewModel(), onOpenRecycleBin: onOpenRecycleBin, onDismissContainer: { dismiss() })
                .navigationDestination(for: FilesViewItem.self) { _ in
                    FilesView(
                        viewModel: makeViewModel(),
                        onOpenRecycleBin: onOpenRecycleBin,
                        onDismissContainer: { dismiss() }
                    )
                }
        }
        .fullScreenCover(
            item: $fullScreenCoverNavigation,
            onDismiss: { triggerReloadFiles.send() },
            content: { navigationItem in
                switch navigationItem {
                case .recycleBin:
                    RecycleBinContainer(
                        cellName: cellName,
                        nodesAPI: nodesAPI,
                        nodesRepository: nodesRepository,
                        isCellsStatePending: isCellsStatePending,
                        localAssetStore: localAssetStore,
                        localAssetRepository: localAssetRepository,
                        nodeCache: nodeCache,
                        nodeRenameNotifier: nodeRenameNotifier,
                        fileCache: fileCache,
                        accentColorProvider: accentColorProvider
                    )
                }
            }
        )
    }

    private func makeViewModel() -> FilesViewModel {
        FilesViewModel(
            useCases: .init(
                fetchNodes: WireDriveFetchNodesPageUseCase(
                    configuration: .conversationFileView(
                        root: path.last.map { .id($0.id) } ?? .path(cellName),
                    ),
                    repository: nodesRepository
                ),
                deleteNodes: WireDriveDeleteNodesUseCase(
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
                    nodesRepository: nodesRepository,
                    localAssetsRepository: localAssetRepository,
                    nodeCache: nodeCache,
                    nodeRenameNotifier: nodeRenameNotifier
                ),
                updateTags: WireDriveUpdateTagsUseCase(nodesAPI: nodesAPI),
                getTagSuggestions: WireDriveGetTagSuggestionsUseCase(nodesAPI: nodesAPI),
                createFileUseCase: WireDriveCreateFileUseCase(nodesRepository: nodesAPI),
                fetchNodeVersions: WireDriveFetchNodeVersionsUseCase(repository: nodesAPI),
                restoreNodeVersion: WireDriveRestoreNodeVersionUseCase(
                    repository: nodesAPI,
                    localAssetsRepository: localAssetRepository,
                    nodeCache: nodeCache
                ),
                getEditingURL: WireDriveGetEditingURLUseCase(editingURLRepository: nodesAPI),
                getAssetUseCase: WireDriveGetAssetUseCase(
                    localAssetRepository: localAssetRepository,
                    fileCache: fileCache
                ),
                getPublicLinkData: WireDriveGetPublicLinkDataUseCase(nodesAPI: nodesAPI),
                createPublicLink: WireDriveCreatePublicLinkUseCase(nodesAPI: nodesAPI),
                deletePublicLink: WireDriveDeletePublicLinkUseCase(nodesAPI: nodesAPI),
                updatePublicLinkExpiration: WireDriveUpdatePublicLinkExpirationUseCase(nodesAPI: nodesAPI),
                updatePublicLinkPassword: WireDriveUpdatePublicLinkPasswordUseCase(nodesAPI: nodesAPI),
                getConversations: WireDriveGetConversationsUseCase(nodesAPI: nodesAPI)
            ),
            title: path.last?.name,
            navigationPath: path,
            setNavigation: { items in
                path = items
            },
            isCellsStatePending: isCellsStatePending,
            localAssetRepository: localAssetRepository,
            nodesRepository: nodesRepository,
            fileCache: fileCache,
            cellName: cellName,
            isBrowsing: false,
            isRecycleBin: false,
            triggerReload: triggerReloadFiles,
            accentColorProvider: accentColorProvider
        )
    }
}
