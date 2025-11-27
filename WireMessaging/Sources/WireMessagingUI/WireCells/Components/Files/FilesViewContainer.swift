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

import SwiftUI
package import WireFoundation
package import WireMessagingDomain
package import WireMessagingData

package struct FilesViewContainer: View {
    @Environment(\.dismiss) private var dismiss

    @State private var path: [FilesViewItem] = []

    private let cellName: String
    private let nodesAPI: NodesAPI
    private let nodesRepository: any WireCellsNodesRepositoryProtocol
    private let isCellsStatePending: Bool
    private let localAssetStore: any WireCellsLocalAssetStoreProtocol
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private let nodeCache: any WireCellsNodeCacheProtocol
    private let nodeRenameNotifier: WireCellsNodeRenameNotifier
    private let fileCache: any FileCache
    private let isFoldersEnabled: Bool
    private let accentColorProvider: () -> WireAccentColor

    enum FullScreenCoverNavigation: String, Identifiable {
        case recycleBin
        
        var id: String { rawValue }
    }
    
    @State private var fullScreenCoverNavigation: FullScreenCoverNavigation?
    
    package init(
        cellName: String,
        nodesAPI: NodesAPI,
        nodesRepository: any WireCellsNodesRepositoryProtocol,
        isCellsStatePending: Bool,
        localAssetStore: any WireCellsLocalAssetStoreProtocol,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        nodeCache: any WireCellsNodeCacheProtocol,
        nodeRenameNotifier: WireCellsNodeRenameNotifier,
        fileCache: any FileCache,
        isFoldersEnabled: Bool,
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
        self.isFoldersEnabled = isFoldersEnabled
        self.accentColorProvider = accentColorProvider
    }

    var body: some View {
        let onOpenRecycleBin: () -> Void = {
            fullScreenCoverNavigation = .recycleBin
        }
        
        NavigationStack(path: $path) {
            FilesView(viewModel: makeViewModel(), onOpenRecycleBin: onOpenRecycleBin, onDismissContainer: { dismiss() })
                .navigationDestination(for: FilesViewItem.self) { _ in
                    FilesView(viewModel: makeViewModel(), onOpenRecycleBin: onOpenRecycleBin, onDismissContainer: { dismiss() })
                }
        }
        .fullScreenCover(item: $fullScreenCoverNavigation) { navigationItem in
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
                    isFoldersEnabled: isFoldersEnabled,
                    accentColorProvider: accentColorProvider
                )
            }
        }
    }

    private func makeViewModel() -> FilesViewModel {
        FilesViewModel(
            useCases: .init(
                fetchNodes: WireCellsFetchNodesUseCase(
                    configuration: .conversationFileView(
                        root: path.last.map { .id($0.id) } ?? .path(cellName),
                        isFoldersEnabled: isFoldersEnabled
                    ),
                    repository: nodesRepository
                ),
                deleteNodes: WireCellsDeleteNodesUseCase(
                    repository: nodesRepository,
                    fileCache: fileCache,
                    localAssetStore: localAssetStore
                ),
                restoreNodes: WireCellsRestoreNodesUseCase(
                    repository: nodesRepository,
                    fileCache: fileCache,
                    localAssetStore: localAssetStore
                ),
                renameNode: WireCellsRenameNodeUseCase(
                    nodesRepository: nodesRepository,
                    localAssetsRepository: localAssetRepository,
                    nodeCache: nodeCache,
                    nodeRenameNotifier: nodeRenameNotifier
                ),
                updateTags: WireCellsUpdateTagsUseCase(nodesAPI: nodesAPI),
                getTagSuggestions: WireCellsGetTagSuggestionsUseCase(nodesAPI: nodesAPI),
                createFolder: WireCellsCreateFolderUseCase(nodesRepository: nodesAPI),
            ),
            title: path.last?.name,
            navigationPath: path,
            setNavigation: { items in
                path = items
            },
            isCellsStatePending: isCellsStatePending,
            localAssetRepository: localAssetRepository,
            fileCache: fileCache,
            cellName: cellName,
            isFoldersEnabled: isFoldersEnabled,
            isRecycleBin: false,
            accentColorProvider: accentColorProvider
        )
    }
}
