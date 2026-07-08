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

import SwiftUI
import WireFoundation
package import WireMessagingDomain
package import WireMessagingData

package struct RecycleBinContainer: View {
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

    package init(
        cellName: String,
        nodesAPI: NodesAPI,
        nodesRepository: any WireDriveNodesRepositoryProtocol,
        isCellsStatePending: Bool,
        localAssetStore: any WireDriveLocalAssetStoreProtocol,
        localAssetRepository: any WireDriveLocalAssetRepositoryProtocol,
        nodeCache: any WireDriveNodeCacheProtocol,
        nodeRenameNotifier: WireDriveNodeRenameNotifier,
        fileCache: any FileCache
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
    }

    var body: some View {
        NavigationStack(path: $path) {
            FilesView(viewModel: makeViewModel(), onDismissContainer: { dismiss() })
                .navigationDestination(for: FilesViewItem.self) { _ in
                    FilesView(viewModel: makeViewModel(), onDismissContainer: { dismiss() })
                }
        }
    }

    private func makeViewModel() -> FilesViewModel {
        FilesViewModel(
            useCases: .init(
                fetchNodesPage: WireDriveFetchNodesPageUseCase(
                    repository: nodesRepository
                ),
                fetchNodes: WireDriveFetchNodesUseCase(
                    state: WireDriveNodesCollection(),
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
                createFile: WireDriveCreateFileUseCase(nodesRepository: nodesAPI),
                fetchNodeVersions: WireDriveFetchNodeVersionsUseCase(repository: nodesRepository),
                restoreNodeVersion: WireDriveRestoreNodeVersionUseCase(
                    repository: nodesRepository,
                    localAssetsRepository: localAssetRepository,
                    nodeCache: nodeCache
                ),
                getEditingURL: WireDriveGetEditingURLUseCase(editingURLRepository: nodesAPI),
                getAsset: WireDriveGetAssetUseCase(
                    localAssetRepository: localAssetRepository,
                    fileCache: fileCache
                ),
                getPublicLinkData: WireDriveGetPublicLinkDataUseCase(nodesAPI: nodesAPI),
                createPublicLink: WireDriveCreatePublicLinkUseCase(nodesAPI: nodesAPI),
                deletePublicLink: WireDriveDeletePublicLinkUseCase(nodesAPI: nodesAPI),
                updatePublicLinkExpiration: WireDriveUpdatePublicLinkExpirationUseCase(nodesAPI: nodesAPI),
                updatePublicLinkPassword: WireDriveUpdatePublicLinkPasswordUseCase(nodesAPI: nodesAPI),
                getDriveConversations: WireDriveGetConversationsUseCase(nodesAPI: nodesAPI),
                getFileTemplates: WireDriveFetchFileTemplatesUseCase(repository: nodesRepository),
                makeAssetAvailableOffline: WireDriveMakeAssetAvailableOfflineUseCase(
                    localAssetRepository: localAssetRepository
                ),
                removeAssetAvailableOffline: WireDriveRemoveAssetAvailableOfflineUseCase(
                    localAssetRepository: localAssetRepository
                ),
                getOfflineAvailableAssets: WireDriveFetchOfflineAvailableAssetsUseCase(
                    localAssetRepository: localAssetRepository
                ),
                observeAsset: WireDriveObserveAssetUseCase(
                    localAssetRepository: localAssetRepository
                ),
                moveNode: WireDriveMoveNodeUseCase(
                    nodesRepository: nodesRepository,
                    localAssetRepository: localAssetRepository
                )
            ),
            title: path.last?.name,
            navigationPath: path,
            setNavigation: { items in
                path = items
            },
            isCellsStatePending: isCellsStatePending,
            cellName: cellName,
            isBrowsing: false,
            isRecycleBin: true
        )
    }
}
