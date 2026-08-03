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

package import WireMessagingDomain

package extension FilesViewModel {
    struct UseCases {
        let fetchNodesPage: WireDriveFetchNodesPageUseCase
        let fetchNodes: WireDriveFetchNodesUseCase
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
        let observeAsset: WireDriveObserveAssetUseCase
        let moveNode: WireDriveMoveNodeUseCase

        package init(
            fetchNodesPage: WireDriveFetchNodesPageUseCase,
            fetchNodes: WireDriveFetchNodesUseCase,
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
            getOfflineAvailableAssets: WireDriveFetchOfflineAvailableAssetsUseCase,
            observeAsset: WireDriveObserveAssetUseCase,
            moveNode: WireDriveMoveNodeUseCase
        ) {
            self.fetchNodesPage = fetchNodesPage
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
            self.observeAsset = observeAsset
            self.moveNode = moveNode
        }
    }
}
