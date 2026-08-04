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

import WireMessagingData
import WireMessagingDomain

extension FilesViewModel {
    struct Dependencies {
        let nodesAPI: NodesAPI
        let nodesRepository: any WireDriveNodesRepositoryProtocol
        let fileCache: any FileCache
        let localAssetStore: any WireDriveLocalAssetStoreProtocol
        let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol
        let nodeRenameNotifier: WireDriveNodeRenameNotifier
        let nodeCache: any WireDriveNodeCacheProtocol
    }

    static func makeUseCases(dependencies: FilesViewModel.Dependencies) -> FilesViewModel.UseCases {
        FilesViewModel.UseCases(
            fetchNodesPage: WireDriveFetchNodesPageUseCase(
                repository: dependencies.nodesRepository
            ),
            fetchNodes: WireDriveFetchNodesUseCase(
                state: WireDriveNodesCollection(),
                repository: dependencies.nodesRepository
            ),
            deleteNodes: WireDriveDeleteNodesUseCase(
                repository: dependencies.nodesRepository,
                fileCache: dependencies.fileCache,
                localAssetStore: dependencies.localAssetStore
            ),
            restoreNodes: WireDriveRestoreNodesUseCase(
                repository: dependencies.nodesRepository,
                fileCache: dependencies.fileCache,
                localAssetStore: dependencies.localAssetStore
            ),
            renameNode: WireDriveRenameNodeUseCase(
                nodesRepository: dependencies.nodesRepository,
                localAssetsRepository: dependencies.localAssetRepository,
                nodeCache: dependencies.nodeCache,
                nodeRenameNotifier: dependencies.nodeRenameNotifier
            ),
            updateTags: WireDriveUpdateTagsUseCase(nodesAPI: dependencies.nodesAPI),
            getTagSuggestions: WireDriveGetTagSuggestionsUseCase(nodesAPI: dependencies.nodesAPI),
            createFile: WireDriveCreateFileUseCase(nodesRepository: dependencies.nodesAPI),
            fetchNodeVersions: WireDriveFetchNodeVersionsUseCase(repository: dependencies.nodesRepository),
            restoreNodeVersion: WireDriveRestoreNodeVersionUseCase(
                repository: dependencies.nodesRepository,
                localAssetsRepository: dependencies.localAssetRepository,
                nodeCache: dependencies.nodeCache
            ),
            getEditingURL: WireDriveGetEditingURLUseCase(editingURLRepository: dependencies.nodesAPI),
            getAsset: WireDriveGetAssetUseCase(
                localAssetRepository: dependencies.localAssetRepository,
                fileCache: dependencies.fileCache
            ),
            getPublicLinkData: WireDriveGetPublicLinkDataUseCase(nodesAPI: dependencies.nodesAPI),
            createPublicLink: WireDriveCreatePublicLinkUseCase(nodesAPI: dependencies.nodesAPI),
            deletePublicLink: WireDriveDeletePublicLinkUseCase(nodesAPI: dependencies.nodesAPI),
            updatePublicLinkExpiration: WireDriveUpdatePublicLinkExpirationUseCase(nodesAPI: dependencies.nodesAPI),
            updatePublicLinkPassword: WireDriveUpdatePublicLinkPasswordUseCase(nodesAPI: dependencies.nodesAPI),
            getDriveConversations: WireDriveGetConversationsUseCase(nodesAPI: dependencies.nodesAPI),
            getFileTemplates: WireDriveFetchFileTemplatesUseCase(repository: dependencies.nodesRepository),
            makeAssetAvailableOffline: WireDriveMakeAssetAvailableOfflineUseCase(
                localAssetRepository: dependencies.localAssetRepository
            ),
            removeAssetAvailableOffline: WireDriveRemoveAssetAvailableOfflineUseCase(
                localAssetRepository: dependencies.localAssetRepository
            ),
            getOfflineAvailableAssets: WireDriveFetchOfflineAvailableAssetsUseCase(
                localAssetRepository: dependencies.localAssetRepository
            ),
            observeAsset: WireDriveObserveAssetUseCase(
                localAssetRepository: dependencies.localAssetRepository
            ),
            moveNode: WireDriveMoveNodeUseCase(
                nodesRepository: dependencies.nodesRepository,
                localAssetRepository: dependencies.localAssetRepository
            )
        )
    }
}
