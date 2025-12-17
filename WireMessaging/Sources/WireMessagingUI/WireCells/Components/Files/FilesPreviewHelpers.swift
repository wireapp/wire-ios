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

import Combine
import SwiftUI
import UniformTypeIdentifiers
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport

// MARK: - View models

extension FilesViewModel {

    /// A stubbed instance of `FilesViewModel` for SwiftUI previews.
    static func preview(isFoldersEnabled: Bool = false) -> FilesViewModel {
        let cache = mockFileCache()
        let localAssetStore = MockWireCellsLocalAssetStoreProtocol()
        localAssetStore.assetNodeID_MockValue = nil
        localAssetStore.deleteAssetsNodeIDs_MockMethod = { _ in }
        let localAssetRepository = MockWireCellsLocalAssetRepositoryProtocol()

        return FilesViewModel(
            useCases: .init(
                fetchNodes: WireCellsFetchNodesPageUseCase(
                    configuration: .conversationFileView(root: .path("root"), isFoldersEnabled: true),
                    repository: previewNodesRepository()
                ),
                deleteNodes: WireCellsDeleteNodesUseCase(
                    repository: previewNodesRepository(),
                    fileCache: cache,
                    localAssetStore: localAssetStore
                ),
                restoreNodes: WireCellsRestoreNodesUseCase(
                    repository: previewNodesRepository(),
                    fileCache: cache,
                    localAssetStore: localAssetStore
                ),
                renameNode: WireCellsRenameNodeUseCase(
                    nodesRepository: previewNodesRepository(),
                    localAssetsRepository: localAssetRepository,
                    nodeCache: MockWireCellsNodeCacheProtocol(),
                    nodeRenameNotifier: WireCellsNodeRenameNotifier()
                ),
                updateTags: WireCellsUpdateTagsUseCase(
                    nodesAPI: previewTagsApi()
                ),
                getTagSuggestions: WireCellsGetTagSuggestionsUseCase(
                    nodesAPI: previewTagsApi()
                ),
                createFolder: WireCellsCreateFolderUseCase(
                    nodesRepository: previewNodesRepository()
                ),
                getEditingURL: WireCellsGetEditingURLUseCase(
                    editingURLRepository: previewEditingURLRepository()
                ),
                getAssetUseCase: WireCellsGetAssetUseCase(
                    localAssetRepository: localAssetRepository, fileCache: cache
                )
            ),
            setNavigation: { _ in },
            isCellsStatePending: false,
            localAssetRepository: PreviewLocalAssetRepository(),
            nodesRepository: previewNodesRepository(),
            fileCache: cache,
            cellName: "2b7d1f2c-74bf-4256-a746-8112e006dcd6",
            isFoldersEnabled: isFoldersEnabled,
            isCollaboraEnabled: false,
            accentColorProvider: { .default }
        )
    }

}

extension FileRenameViewModel {
    /// A stubbed instance of `FileRenameViewModel` for SwiftUI previews.
    static func preview(kind: FilesViewItem.Kind) -> FileRenameViewModel {
        let localAssetStore = MockWireCellsLocalAssetStoreProtocol()
        localAssetStore.assetNodeID_MockValue = nil
        localAssetStore.deleteAssetsNodeIDs_MockMethod = { _ in }

        return FileRenameViewModel(
            renameNodeUseCase: WireCellsRenameNodeUseCase(
                nodesRepository: previewNodesRepository(),
                localAssetsRepository: MockWireCellsLocalAssetRepositoryProtocol(),
                nodeCache: MockWireCellsNodeCacheProtocol(),
                nodeRenameNotifier: WireCellsNodeRenameNotifier()
            ),
            model: Model(
                nodeID: .init(),
                filename: "foo.jpg",
                filepath: "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Image PNG-TEST3.png"
            ),
            kind: kind
        )
    }
}

extension FilesItemViewModel {

    /// A stubbed instance of `FilesItemViewModel` for SwiftUI previews.
    static func preview(tags: [String] = []) -> FilesItemViewModel {
        FilesItemViewModel(
            item: FilesViewItem(
                id: UUID(),
                eTag: "eTag",
                kind: .file,
                name: "foo.jpg",
                filePath: "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Image foo.jpg",
                ownedBy: "Viola",
                modifiedAt: Date(),
                icon: .image,
                tags: tags,
                isEditable: false
            ),
            localAssetRepository: PreviewLocalAssetRepository(),
            onItemAction: { _, _ in },
            isInRecycleBin: false,
            isFoldersEnabled: false,
        )
    }

}

extension FilesFiltersViewModel {

    /// A stubbed instance of `FilesFiltersViewModel` for SwiftUI previews.
    static func preview() -> FilesFiltersViewModel {
        let nodesAPI = MockNodesAPIProtocol()
        nodesAPI.getAllTags_MockValue = mockTags

        return FilesFiltersViewModel(
            fetchTagsUseCase:
            WireCellsGetTagSuggestionsUseCase(
                nodesAPI: nodesAPI
            ),
            savedTags: nil,
            accentColorProvider: { .default }
        )
    }

}

// MARK: - Dependencies

private func previewNodesRepository() -> any WireCellsNodesRepositoryProtocol {
    let repository = MockWireCellsNodesRepositoryProtocol()
    let nodes = (0 ... 150).map { index in
        WireCellsNode(
            uuid: UUID(),
            path: "root/foo-\(index).jpg",
            modified: Date().addingTimeInterval(Double(-index * 60)),
            mimeType: "image/jpeg",
            ownerUserName: "Person \(index)",
        )
    }
    repository.getNodes_MockMethod = { request in
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay

        let end = min(request.offset + request.limit, nodes.count)
        let page = request.offset < nodes.count ? Array(nodes[request.offset ..< end]) : []
        let nextOffset = end < nodes.count ? end : nil
        return (page, nextOffset)
    }
    return repository
}

private func previewTagsApi() -> some NodesAPIProtocol {
    let mock = MockNodesAPIProtocol()
    mock.getAllTags_MockMethod = {
        mockTags
    }
    mock.updateTagsNodeIDTags_MockMethod = { _, _ in }
    return mock
}

private func previewEditingURLRepository() -> any WireCellsEditingURLRepositoryProtocol {
    let mock = MockWireCellsEditingURLRepositoryProtocol()
    mock.getEditorURLId_MockValue = nil
    return mock
}

private func mockFileCache() -> any FileCache {
    let fileURL = URL.temporaryDirectory.appendingPathComponent("mock-file.txt")
    let file = Data("Some text file content".utf8)
    try? file.write(to: fileURL)

    let cache = MockFileCache()
    cache.fileURLForKey_MockValue = fileURL

    return cache
}

private final class PreviewLocalAssetRepository: WireCellsLocalAssetRepositoryProtocol, @unchecked Sendable {

    var failIndex = 0
    var publishers: [UUID: CurrentValueSubject<WireCellsLocalAsset?, Never>] = [:]

    func asset(nodeID: UUID) throws -> WireMessagingDomain.WireCellsLocalAsset? {
        publishers[nodeID]?.value
    }

    func refreshAssetMetadata(
        nodeID: UUID
    ) async throws -> (node: WireCellsNode, asset: WireCellsLocalAsset) {
        let node = WireCellsNode(uuid: .init(), path: "")

        let localAsset = WireCellsLocalAsset(
            nodeID: nodeID,
            eTag: "something",
            path: "some/path.jpg",
            contentType: nil,
            size: nil,
            downloadState: .pending
        )

        return (node, localAsset)
    }

    func downloadAsset(nodeID: UUID) async throws {
        failIndex += 1
        // Fail every 3rd download
        let shouldFail = failIndex % 3 == 0

        for progress in stride(from: 0.0, to: 1.1, by: 0.1) {
            let downloadState: WireCellsLocalAsset.DownloadState = if shouldFail, progress > 0.1 {
                .failed(error: URLError(.notConnectedToInternet))
            } else if progress < 1 {
                .downloading(progress: Double(progress))
            } else {
                .downloaded(cacheKey: "cacheKey")
            }

            try await Task.sleep(for: .milliseconds(200))
            let update = WireCellsLocalAsset(
                nodeID: nodeID,
                eTag: "something",
                path: "some/path.jpg",
                contentType: nil,
                size: nil,
                downloadState: downloadState
            )

            publishers[nodeID]?.send(update)

            if shouldFail, progress > 0.1 {
                break
            }
        }
    }

    func observeAsset(nodeID: UUID) -> AnyPublisher<WireMessagingDomain.WireCellsLocalAsset?, Never> {
        let publisher = publishers[nodeID] ?? CurrentValueSubject<WireCellsLocalAsset?, Never>(nil)
        publishers[nodeID] = publisher
        return publisher.eraseToAnyPublisher()
    }

    func cancelDownload(nodeID: UUID) {}

}

extension CreateFolderViewModel {
    /// A stubbed instance of `CreateFolderViewModel` for SwiftUI previews.
    static func preview() -> CreateFolderViewModel {
        let createFolderUseCase = MockWireCellsCreateFolderUseCaseProtocol()

        return CreateFolderViewModel(
            createFolderUseCase: createFolderUseCase,
            folderPath: "Test-1/Test-2"
        )
    }
}

let mockTags = [
    "Urgent",
    "Marketing",
    "screenshot",
    "",
    "charles-files-are-no-fun",
    "accessibility",
    "product",
    "autumn",
    "happy",
    "Technical Docs",
    "Lorem Ipsum",
    "Android",
    "some tag",
    "Some Tag ",
    "Some Tag",
    "tag some... ",
    "Pictures",
    "Test",
    "Test ",
    "QA Review",
    "Done",
    "In Progress",
    "To Do",
    "Pending Ticket",
    "jira",
    "Urgent ",
    "Android ",
    "ttaagg",
    "ttaagg2",
    "confirmation email investigations",
    "Testing Data",
    "play",
    "jira ",
    "tag1",
    "tag12",
    "cute",
    "cute ",
    " cute",
    "conference",
    "food",
    "Never",
    "gonna",
    "give",
    "you",
    "up",
    "screenshot ",
    "nothing",
    "QM",
    "Marketing ",
    "nothing ",
    "Sam",
    "cells",
    "roadmap",
    "apps",
    "troubleshooting",
    "network",
    "merkblatt",
    "charles-files-are-no-fun ",
    "🐝 "
]
