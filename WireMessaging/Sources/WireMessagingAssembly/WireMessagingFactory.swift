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

public import Foundation
public import UIKit
public import SwiftUI
public import WireData
import WireFoundation
public import WireMessagingDomain
import WireMessagingData
public import WireMessagingUI

public struct WireMessagingFactory {

    private let nodesAPI: NodesAPI
    private let uploadManager: WireCellsNodeUploadManager
    private let draftsRepository: DraftsRepository
    private let fileCache: any FileCache
    private let localAssetStore: any WireCellsLocalAssetStoreProtocol
    private let localAssetRepository: WireCellsLocalAssetRepository
    private let filenameGenerator = FilenameGenerator()
    private let lastOpenRequest: WireCellsLastOpenRequest
    private let nodeCache = WireCellsNodeCache()
    private let nodeRenameNotifier: WireCellsNodeRenameNotifier

    @MainActor var lastOpenRequestNodeID: UUID?

    @MainActor
    public init(
        serverURL: URL,
        accessToken: any AccessTokenProvider,
        fileCache: any FileCache,
        contextProvider: any ManagedObjectContextProvider
    ) {
        // TODO: [WPB-18798] Remove serverURL temporary override when there exists a method to obtain the correct URL.
        let serverURL = switch serverURL.host {
        case "prod-nginz-https.wire.com": // Production
            URL(string: "https://cells-beta.wire.com")!
        case "staging-nginz-https.zinfra.io": // Staging
            URL(string: "https://cells.staging.zinfra.io")!
        case "nginz-https.fulu.wire.link": // Fulu
            URL(string: "https://cells.fulu.wire.link")!
        case "nginz-https.imai.wire.link": // Imai
            URL(string: "https://cells.imai.wire.link")!
        default:
            serverURL
        }

        self.nodesAPI = NodesAPI(serverURL: serverURL, accessToken: accessToken)
        self.uploadManager = WireCellsNodeUploadManager(nodesAPI: nodesAPI)
        self.draftsRepository = DraftsRepository(uploadManager: uploadManager, nodesAPI: nodesAPI)
        self.fileCache = fileCache
        self.localAssetStore = WireCellsLocalAssetStore(contextProvider: contextProvider)
        self.localAssetRepository = WireCellsLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileCache: fileCache,
            store: localAssetStore
        )
        self.lastOpenRequest = WireCellsLastOpenRequest()
        self.nodeRenameNotifier = WireCellsNodeRenameNotifier()
    }

    public func makeUploadDraftUseCase(cellName: String) -> any WireCellsUploadDraftUseCaseProtocol {
        UploadDraftUseCase(
            cellName: cellName,
            draftRepository: draftsRepository,
            uploadManager: uploadManager,
            nodesAPI: nodesAPI,
            metadataRepository: WireCellsDraftMetadataRepository(),
            filenameGenerator: filenameGenerator
        )
    }

    public func makeObserveDraftsUseCase(cellName: String) -> any WireCellsObserveDraftsUseCaseProtocol {
        ObserveDraftsUseCase(cellName: cellName, draftRepository: draftsRepository)
    }

    public func makePublishDraftsUseCase(cellName: String) -> any WireCellsPublishDraftsUseCaseProtocol {
        PublishDraftsUseCase(cellName: cellName, draftRepository: draftsRepository)
    }

    public func makeClearPublishedDraftsUseCase(cellName: String) -> any WireCellsClearPublishedDraftsUseCaseProtocol {
        ClearPublishedDraftsUseCase(cellName: cellName, draftRepository: draftsRepository)
    }

    public func makeDeleteDraftUseCase(cellName: String) -> any WireCellsDeleteDraftUseCaseProtocol {
        DeleteDraftUseCase(
            cellName: cellName,
            draftRepository: draftsRepository,
            uploadManager: uploadManager,
            nodesAPI: nodesAPI
        )
    }

    public func makeRetryUploadDraftUseCase(cellName: String) -> any WireCellsRetryUploadDraftUseCaseProtocol {
        UploadDraftUseCase(
            cellName: cellName,
            draftRepository: draftsRepository,
            uploadManager: uploadManager,
            nodesAPI: nodesAPI,
            metadataRepository: WireCellsDraftMetadataRepository(),
            filenameGenerator: filenameGenerator
        )
    }

    public func makeDeleteNodesUseCase() -> any WireCellsDeleteNodesUseCaseProtocol {
        WireCellsDeleteNodesUseCase(
            repository: nodesAPI,
            fileCache: fileCache,
            localAssetStore: localAssetStore
        )
    }

    public func makeRenameNodeUseCase() -> any WireCellsRenameNodeUseCaseProtocol {
        WireCellsRenameNodeUseCase(
            nodesRepository: nodesAPI,
            localAssetsRepository: localAssetRepository,
            nodeCache: nodeCache,
            nodeRenameNotifier: nodeRenameNotifier
        )
    }

}

public extension WireMessagingFactory {

    @MainActor
    func makeFilesView(
        cellName: String,
        isCellsStatePending: Bool,
        nodeIDs: [UUID]
    ) -> UIViewController {
        let configuration: WireCellsFetchNodesUseCase.Configuration = nodeIDs
            .isEmpty ? .conversationFileView(root: .path(cellName)) :
            .nodesFileView(nodeIDs: nodeIDs)

        let filesView: UIHostingController<FilesView>

        filesView = makeFilesHostingController(
            configuration: configuration,
            isCellsStatePending: isCellsStatePending
        )

        return filesView
    }

    @MainActor
    func makeFilesBrowserView() -> UIViewController {
        let configuration: WireCellsFetchNodesUseCase.Configuration = .filesBrowserView()
        let filesBrowserView: UIHostingController<FilesBrowserView>
        filesBrowserView = makeFilesHostingController(
            configuration: configuration
        )
        return filesBrowserView
    }

    @MainActor
    private func makeFilesHostingController<T: FilesViewProtocol>(
        configuration: WireCellsFetchNodesUseCase.Configuration,
        isCellsStatePending: Bool = false
    ) -> UIHostingController<T> {
        let viewModel = FilesViewModel(
            fetchNodesUseCase: WireCellsFetchNodesUseCase(
                configuration: configuration,
                repository: nodesAPI
            ),
            deleteNodesUseCase: WireCellsDeleteNodesUseCase(
                repository: nodesAPI,
                fileCache: fileCache,
                localAssetStore: localAssetStore
            ),
            renameNodeUseCase: makeRenameNodeUseCase(),
            isCellsStatePending: isCellsStatePending,
            localAssetRepository: localAssetRepository,
            fileCache: fileCache
        )

        return UIHostingController(rootView: T(viewModel: viewModel))
    }

    @MainActor
    func makeAttachmentsPreviewView(
        attachments: [WireCellsMessageAttachment],
        alignment: HorizontalAlignment
    ) -> UIViewController {
        let viewController = UIHostingController(
            rootView: WireCellsAttachmentsPreviewView(
                viewModel: WireCellsAttachmentsPreviewViewModel(
                    attachments: attachments,
                    alignment: alignment,
                    fetchNodeUseCase: WireCellsFetchNodeUseCase(
                        repository: nodesAPI,
                        cache: nodeCache
                    ),
                    getAssetUseCase: WireCellsGetAssetUseCase(
                        localAssetRepository: localAssetRepository,
                        fileCache: fileCache
                    ),
                    localAssetRepository: localAssetRepository,
                    lastOpenRequest: lastOpenRequest,
                    nodeRenameNotifier: nodeRenameNotifier
                )
            ).environment(\.wireTextStyleMapping, WireTextStyleMapping())
        )
        viewController.view.backgroundColor = .clear
        return viewController
    }

    func makeConversationCellProvider(
        insetsProvider: @escaping () -> ConversationCellInsets
    ) -> ConversationCellProvider {
        ConversationCellProvider(
            fetchNodeUseCase: WireCellsFetchNodeUseCase(
                repository: nodesAPI,
                cache: nodeCache
            ),
            getAssetUseCase: WireCellsGetAssetUseCase(
                localAssetRepository: localAssetRepository,
                fileCache: fileCache
            ),
            localAssetRepository: localAssetRepository,
            lastOpenRequest: lastOpenRequest,
            nodeRenameNotifier: nodeRenameNotifier,
            insetsProvider: insetsProvider
        )
    }

}
