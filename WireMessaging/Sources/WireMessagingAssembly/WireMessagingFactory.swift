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

public import Foundation
public import UIKit
import SwiftUI
public import WireData
public import WireFoundation
public import WireMessagingDomain
import WireMessagingData
public import WireMessagingUI

public struct WireMessagingFactory {

    public typealias DriveURLResolver = @Sendable () throws -> URL
    public typealias DriveAnalyticsProvider = @Sendable () -> (any AnalyticsEventTrackerProtocol)?

    private let nodesAPI: NodesAPI
    private let uploadManager: WireDriveNodeUploadManager
    private let draftsRepository: DraftsRepository
    private let fileCache: any FileCache
    private let localAssetStore: any WireDriveLocalAssetStoreProtocol
    private let localAssetRepository: WireDriveLocalAssetRepository
    private let filenameGenerator = FilenameGenerator()
    private let lastOpenRequest: WireDriveLastOpenRequest
    private let nodeCache: WireDriveNodeCache
    private let nodeRenameNotifier: WireDriveNodeRenameNotifier
    private let analyticsProvider: DriveAnalyticsProvider

    @MainActor var lastOpenRequestNodeID: UUID?

    @MainActor
    public init(
        driveURLResolver: @escaping DriveURLResolver,
        driveConversationLocalStore: any WireDriveConversationsLocalStoreProtocol,
        accessToken: any AccessTokenProvider,
        fileCache: any FileCache,
        contextProvider: any ManagedObjectContextProvider,
        analyticsProvider: @escaping DriveAnalyticsProvider
    ) {
        self.nodeCache = WireDriveNodeCache()
        self.nodesAPI = NodesAPI(
            serverURLResolver: driveURLResolver,
            localStore: driveConversationLocalStore,
            accessToken: accessToken
        )
        self.uploadManager = WireDriveNodeUploadManager(nodesAPI: nodesAPI)
        self.draftsRepository = DraftsRepository(uploadManager: uploadManager, nodesAPI: nodesAPI)
        self.fileCache = fileCache
        self.localAssetStore = WireDriveLocalAssetStore(contextProvider: contextProvider)
        self.localAssetRepository = WireDriveLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileCache: fileCache,
            store: localAssetStore
        )
        self.lastOpenRequest = WireDriveLastOpenRequest()
        self.nodeRenameNotifier = WireDriveNodeRenameNotifier()
        self.analyticsProvider = analyticsProvider
    }

    public func makeUploadDraftUseCase(cellName: String) -> any WireDriveUploadDraftUseCaseProtocol {
        UploadDraftUseCase(
            cellName: cellName,
            draftRepository: draftsRepository,
            uploadManager: uploadManager,
            nodesAPI: nodesAPI,
            metadataRepository: WireDriveDraftMetadataRepository(),
            filenameGenerator: filenameGenerator
        )
    }

    public func makeObserveDraftsUseCase(cellName: String) -> any WireDriveObserveDraftsUseCaseProtocol {
        ObserveDraftsUseCase(cellName: cellName, draftRepository: draftsRepository)
    }

    public func makePublishDraftsUseCase(cellName: String) -> any WireDrivePublishDraftsUseCaseProtocol {
        PublishDraftsUseCase(
            cellName: cellName,
            draftRepository: draftsRepository,
            analyticsProvider: analyticsProvider
        )
    }

    public func makeClearPublishedDraftsUseCase(cellName: String) -> any WireDriveClearPublishedDraftsUseCaseProtocol {
        ClearPublishedDraftsUseCase(cellName: cellName, draftRepository: draftsRepository)
    }

    public func makeDeleteDraftUseCase(cellName: String) -> any WireDriveDeleteDraftUseCaseProtocol {
        DeleteDraftUseCase(
            cellName: cellName,
            draftRepository: draftsRepository,
            uploadManager: uploadManager,
            nodesAPI: nodesAPI
        )
    }

    public func makeRetryUploadDraftUseCase(cellName: String) -> any WireDriveRetryUploadDraftUseCaseProtocol {
        UploadDraftUseCase(
            cellName: cellName,
            draftRepository: draftsRepository,
            uploadManager: uploadManager,
            nodesAPI: nodesAPI,
            metadataRepository: WireDriveDraftMetadataRepository(),
            filenameGenerator: filenameGenerator
        )
    }

    public func makeDeleteNodesUseCase() -> any WireDriveDeleteNodesUseCaseProtocol {
        WireDriveDeleteNodesUseCase(
            repository: nodesAPI,
            fileCache: fileCache,
            localAssetStore: localAssetStore
        )
    }

    public func makeUpdateTagsUseCase() -> some WireDriveUpdateTagsUseCaseProtocol {
        WireDriveUpdateTagsUseCase(nodesAPI: nodesAPI)
    }

    public func makeFetchNodeUseCase() -> any WireDriveFetchNodeUseCaseProtocol {
        WireDriveFetchNodeUseCase(
            repository: nodesAPI,
            cache: nodeCache
        )
    }

    public func makeFetchCachedNodeUseCase() -> any WireDriveFetchCachedNodeUseCaseProtocol {
        nodeCache
    }
}

public extension WireMessagingFactory {

    @MainActor
    func makeFilesView(
        cellName: String,
        isCellsStatePending: Bool,
        accentColorProvider: @escaping () -> WireAccentColor
    ) -> UIViewController {
        UIHostingController(
            rootView: FilesViewContainer(
                cellName: cellName,
                nodesAPI: nodesAPI,
                nodesRepository: nodesAPI,
                isCellsStatePending: isCellsStatePending,
                localAssetStore: localAssetStore,
                localAssetRepository: localAssetRepository,
                nodeCache: nodeCache,
                nodeRenameNotifier: nodeRenameNotifier,
                fileCache: fileCache
            )
            .environment(\.wireAccentColor, accentColorProvider())
        )
    }

    @MainActor
    func makeFilesBrowserView(
        accentColorProvider: @escaping () -> WireAccentColor
    ) -> UIViewController {
        UIHostingController(
            rootView: FilesBrowserView(
                viewModel: FilesViewModel(
                    useCases: .init(
                        fetchNodes: WireDriveFetchNodesPageUseCase(
                            configuration: .filesBrowserView,
                            repository: nodesAPI
                        ),
                        deleteNodes: WireDriveDeleteNodesUseCase(
                            repository: nodesAPI,
                            fileCache: fileCache,
                            localAssetStore: localAssetStore
                        ),
                        restoreNodes: WireDriveRestoreNodesUseCase(
                            repository: nodesAPI,
                            fileCache: fileCache,
                            localAssetStore: localAssetStore
                        ),
                        renameNode: WireDriveRenameNodeUseCase(
                            nodesRepository: nodesAPI,
                            localAssetsRepository: localAssetRepository,
                            nodeCache: nodeCache,
                            nodeRenameNotifier: nodeRenameNotifier
                        ),
                        updateTags: WireDriveUpdateTagsUseCase(nodesAPI: nodesAPI),
                        getTagSuggestions: WireDriveGetTagSuggestionsUseCase(nodesAPI: nodesAPI),
                        createFile: WireDriveCreateFileUseCase(nodesRepository: nodesAPI),
                        fetchNodeVersions: WireDriveFetchNodeVersionsUseCase(repository: nodesAPI),
                        restoreNodeVersion: WireDriveRestoreNodeVersionUseCase(
                            repository: nodesAPI,
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
                        getFileTemplates: WireDriveFetchFileTemplatesUseCase(repository: nodesAPI),
                        makeAssetAvailableOffline: WireDriveMakeAssetAvailableOfflineUseCase(
                            localAssetRepository: localAssetRepository
                        ),
                        removeAssetAvailableOffline: WireDriveRemoveAssetAvailableOfflineUseCase(
                            localAssetRepository: localAssetRepository
                        ),
                        getOfflineAvailableAssets: WireDriveFetchOfflineAvailableAssetsUseCase(
                            localAssetRepository: localAssetRepository
                        )
                    ),
                    isCellsStatePending: false,
                    localAssetRepository: localAssetRepository,
                    nodesRepository: nodesAPI,
                    isBrowsing: true
                )
            )
            .environment(\.wireAccentColor, accentColorProvider())
        )
    }

    func makeConversationCellProvider(
        insetsProvider: @escaping () -> ConversationCellInsets
    ) -> ConversationCellProvider {
        ConversationCellProvider(
            fetchCachedNodeUseCase: nodeCache,
            fetchNodeUseCase: WireDriveFetchNodeUseCase(
                repository: nodesAPI,
                cache: nodeCache
            ),
            getAssetUseCase: WireDriveGetAssetUseCase(
                localAssetRepository: localAssetRepository,
                fileCache: fileCache
            ),
            localAssetRepository: localAssetRepository,
            lastOpenRequest: lastOpenRequest,
            nodeRenameNotifier: nodeRenameNotifier,
            insetsProvider: insetsProvider
        )
    }

    @MainActor
    func makeConversationSharedDrivedOptionsViewController(
        participants: [WireDriveParticipant],
        onClose: @escaping () -> Void
    ) -> UIViewController {
        let viewModel = ConversationSharedDriveOptionsViewModel(participants: participants)
        let view = ConversationSharedDriveOptionsView(viewModel: viewModel, onClose: onClose)
        return UIHostingController(rootView: view)
    }

}
