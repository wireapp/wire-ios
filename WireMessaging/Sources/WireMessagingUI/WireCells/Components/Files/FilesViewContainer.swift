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
package import WireMessagingDomain

package struct FilesViewContainer: View {

    @State private var path: [FilesViewItem] = []

    private let cellName: String
    private let nodesRepository: any WireCellsNodesRepositoryProtocol
    private let isCellsStatePending: Bool
    private let localAssetStore: any WireCellsLocalAssetStoreProtocol
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private let fileCache: any FileCache
    private let isFoldersEnabled: Bool

    package init(
        cellName: String,
        nodesRepository: any WireCellsNodesRepositoryProtocol,
        isCellsStatePending: Bool,
        localAssetStore: any WireCellsLocalAssetStoreProtocol,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        fileCache: any FileCache,
        isFoldersEnabled: Bool
    ) {
        self.cellName = cellName
        self.nodesRepository = nodesRepository
        self.isCellsStatePending = isCellsStatePending
        self.localAssetStore = localAssetStore
        self.localAssetRepository = localAssetRepository
        self.fileCache = fileCache
        self.isFoldersEnabled = isFoldersEnabled
    }

    var body: some View {
        NavigationStack(path: $path) {
            FilesView(viewModel: makeViewModel())
                .navigationDestination(for: FilesViewItem.self) { _ in
                    FilesView(viewModel: makeViewModel())
                }
        }
    }

    private func makeViewModel() -> FilesViewModel {
        FilesViewModel(
            title: path.last?.filename,
            navigationPath: path,
            setNavigation: { items in
                path = items
            },
            fetchNodesUseCase: WireCellsFetchNodesUseCase(
                configuration: .conversationFileView(
                    root: path.last.map { .id($0.id) } ?? .path(cellName),
                    isFoldersEnabled: isFoldersEnabled
                ),
                repository: nodesRepository
            ),
            deleteNodesUseCase: WireCellsDeleteNodesUseCase(
                repository: nodesRepository,
                fileCache: fileCache,
                localAssetStore: localAssetStore
            ),
            isCellsStatePending: isCellsStatePending,
            localAssetRepository: localAssetRepository,
            fileCache: fileCache
        )
    }
}
