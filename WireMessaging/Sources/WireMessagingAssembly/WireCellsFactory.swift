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
public import WireMessagingDomain
import WireMessagingData
import WireMessagingUI

public struct WireCellsFactory {

    private let nodesAPI: NodesAPI
    private let uploadManager: WireCellsNodeUploadManager
    private let draftsRepository: DraftsRepository
    private let fileCache = FakeFileCache()
    private let localAssetRepository: WireCellsLocalAssetRepository

    public init(serverURL: URL, accessToken: any AccessTokenProvider) {
        // TODO: [WPB-18798] Remove serverURL temporary override when there exists a method to obtain the correct URL.
        let serverURL = switch serverURL.host {
        case "nginz-https.fulu.wire.link":
            URL(string: "https://cells.fulu.wire.link")!
        case "nginz-https.imai.wire.link":
            URL(string: "https://cells.imai.wire.link")!
        default:
            serverURL
        }

        self.nodesAPI = NodesAPI(serverURL: serverURL, accessToken: accessToken)
        self.uploadManager = WireCellsNodeUploadManager(nodesAPI: nodesAPI)
        self.draftsRepository = DraftsRepository(uploadManager: uploadManager, nodesAPI: nodesAPI)
        self.localAssetRepository = WireCellsLocalAssetRepository(
            nodesAPI: nodesAPI,
            fileCache: fileCache,
            store: FakeWireCellsLocalAssetMetadataStore()
        )
    }

    public func makeUploadDraftUseCase(cellName: String) -> any WireCellsUploadDraftUseCaseProtocol {
        UploadDraftUseCase(
            cellName: cellName,
            draftRepository: draftsRepository,
            uploadManager: uploadManager,
            nodesAPI: nodesAPI
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
            nodesAPI: nodesAPI
        )
    }

}

public extension WireCellsFactory {

    @MainActor
    func makeFilesView(cellName: String) -> UIViewController {
        let viewModel = FilesViewModel(
            fetchNodesUseCase: WireCellsFetchNodesUseCase(
                configuration: .conversationFileView(root: .path(cellName)),
                repository: nodesAPI
            ),
            localAssetRepository: localAssetRepository,
            fileCache: fileCache
        )

        return FilesHostingController(
            viewModel: viewModel
        )
    }
}

// MARK: - Temporary

// FIXME: Implement real
final class FakeFileCache: FileCache {

    private let directory = URL.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)

    init() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func saveFile(at url: URL, key: String) async throws {
        let destination = directory.appending(component: key, directoryHint: .notDirectory)
        try FileManager.default.moveItem(at: url, to: destination)
    }

    func deleteFile(forKey key: String) async throws {
        let fileURL = directory.appending(component: key, directoryHint: .notDirectory)
        try FileManager.default.removeItem(at: fileURL)
    }

    func fileURL(forKey key: String) -> URL? {
        directory.appending(component: key, directoryHint: .notDirectory)
    }

}

// FIXME: Implement real
final class FakeWireCellsLocalAssetMetadataStore: WireCellsLocalAssetMetadataStore {

    private var storage: [UUID: WireMessagingDomain.WireCellsLocalAssetMetadata] = [:]

    func assetMetadata(nodeID: UUID) throws -> WireMessagingDomain.WireCellsLocalAssetMetadata? {
        storage[nodeID]
    }

    func upsertAssetMetadata(_ metadata: WireMessagingDomain.WireCellsLocalAssetMetadata) throws {
        storage[metadata.nodeID] = metadata
    }

}
