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
import UniformTypeIdentifiers
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport

// MARK: - View models

extension FilesViewModel {

    /// A stubbed instance of `FilesViewModel` for SwiftUI previews.
    static func preview() -> FilesViewModel {
        let cache = mockFileCache()
        let localAssetStore = MockWireDriveLocalAssetStoreProtocol()
        localAssetStore.assetNodeID_MockValue = nil
        localAssetStore.deleteAssetsNodeIDs_MockMethod = { _ in }
        let localAssetRepository = MockWireDriveLocalAssetRepositoryProtocol()

        return FilesViewModel(
            useCases: .init(
                fetchNodes: WireDriveFetchNodesPageUseCase(
                    configuration: .conversationFileView(root: .path("root")),
                    repository: previewNodesRepository()
                ),
                deleteNodes: WireDriveDeleteNodesUseCase(
                    repository: previewNodesRepository(),
                    fileCache: cache,
                    localAssetStore: localAssetStore
                ),
                restoreNodes: WireDriveRestoreNodesUseCase(
                    repository: previewNodesRepository(),
                    fileCache: cache,
                    localAssetStore: localAssetStore
                ),
                renameNode: WireDriveRenameNodeUseCase(
                    nodesRepository: previewNodesRepository(),
                    localAssetsRepository: localAssetRepository,
                    nodeCache: MockWireDriveNodeCacheProtocol(),
                    nodeRenameNotifier: WireDriveNodeRenameNotifier()
                ),
                updateTags: WireDriveUpdateTagsUseCase(
                    nodesAPI: previewTagsApi()
                ),
                getTagSuggestions: WireDriveGetTagSuggestionsUseCase(
                    nodesAPI: previewTagsApi()
                ),
                createFileUseCase: WireDriveCreateFileUseCase(
                    nodesRepository: previewNodesRepository()
                ),
                fetchNodeVersions: WireDriveFetchNodeVersionsUseCase(
                    repository: previewNodesRepository()
                ),
                restoreNodeVersion: WireDriveRestoreNodeVersionUseCase(
                    repository: previewNodesRepository(),
                    localAssetsRepository: localAssetRepository,
                    nodeCache: MockWireDriveNodeCacheProtocol()
                ),
                getEditingURL: WireDriveGetEditingURLUseCase(
                    editingURLRepository: previewEditingURLRepository()
                ),
                getAssetUseCase: WireDriveGetAssetUseCase(
                    localAssetRepository: localAssetRepository, fileCache: cache
                ),
                getPublicLinkData: WireDriveGetPublicLinkDataUseCase(
                    nodesAPI: previewPublicLinkApi()
                ),
                createPublicLink: WireDriveCreatePublicLinkUseCase(
                    nodesAPI: previewPublicLinkApi()
                ),
                deletePublicLink: WireDriveDeletePublicLinkUseCase(
                    nodesAPI: previewPublicLinkApi()
                ),
                updatePublicLinkExpiration: WireDriveUpdatePublicLinkExpirationUseCase(
                    nodesAPI: previewPublicLinkApi()
                ),
                updatePublicLinkPassword: WireDriveUpdatePublicLinkPasswordUseCase(
                    nodesAPI: previewPublicLinkApi()
                )
            ),
            setNavigation: { _ in },
            isCellsStatePending: false,
            localAssetRepository: localAssetRepository,
            nodesRepository: previewNodesRepository(),
            fileCache: cache,
            cellName: "2b7d1f2c-74bf-4256-a746-8112e006dcd6",
            isBrowsing: false,
            accentColorProvider: { .default }
        )
    }
}

extension FileRenameViewModel {
    /// A stubbed instance of `FileRenameViewModel` for SwiftUI previews.
    static func preview(kind: FilesViewItem.Kind) -> FileRenameViewModel {
        let localAssetStore = MockWireDriveLocalAssetStoreProtocol()
        localAssetStore.assetNodeID_MockValue = nil
        localAssetStore.deleteAssetsNodeIDs_MockMethod = { _ in }

        return FileRenameViewModel(
            renameNodeUseCase: WireDriveRenameNodeUseCase(
                nodesRepository: previewNodesRepository(),
                localAssetsRepository: MockWireDriveLocalAssetRepositoryProtocol(),
                nodeCache: MockWireDriveNodeCacheProtocol(),
                nodeRenameNotifier: WireDriveNodeRenameNotifier()
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
    static func preview(
        kind: FilesViewItem.Kind = .file,
        icon: FileIcon = .image,
        tags: [String] = [],
        publicLinkID: String? = nil
    ) -> FilesItemViewModel {
        FilesItemViewModel(
            item: FilesViewItem(
                id: UUID(),
                eTag: "eTag",
                kind: kind,
                name: "foo.jpg",
                filePath: "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Image foo.jpg",
                ownedBy: "Viola",
                modifiedAt: Date(),
                icon: icon,
                tags: tags,
                isEditable: false,
                publicLinkID: publicLinkID,
                conversationName: "Conversation 1",
            ),
            conversationName: "Test",
            localAssetRepository: PreviewLocalAssetRepository(),
            onItemAction: { _, _ in },
            isBrowsing: false,
            isInRecycleBin: false,
        )
    }

}

extension FileVersionItemViewModel {
    /// A stubbed instance of `FileVersionItemViewModel` for SwiftUI previews.
    static func preview() -> FileVersionItemViewModel {
        FileVersionItemViewModel(
            nodeID: UUID(),
            item: .init(
                id: UUID(),
                title: "5:46AM",
                subtitle: "Deniz Agha · 13MB"
            ),
            accentColor: .default,
            onRestore: { _ in }
        )
    }
}

extension FilterByTagsView.ViewModel {

    /// A stubbed instance for SwiftUI previews.
    static func preview() -> FilterByTagsView.ViewModel {
        let nodesAPI = MockNodesAPIProtocol()
        nodesAPI.getAllTags_MockValue = mockTags

        return FilterByTagsView.ViewModel(
            fetchTagsUseCase: WireDriveGetTagSuggestionsUseCase(
                nodesAPI: nodesAPI
            ),
            selectedTags: []
        )
    }

}

extension FileVersioningViewModel {

    /// A stubbed instance of `FileVersioningViewModel` for SwiftUI previews.
    static func preview() -> FileVersioningViewModel {
        let repository = MockWireDriveNodesRepositoryProtocol()
        repository.getVersionsNodeID_MockValue = WireDriveNodeVersion.mock

        let useCase = WireDriveFetchNodeVersionsUseCase(repository: repository)
        let localAssetsRepository = PreviewLocalAssetRepository()
        repository.restoreVersionNodeIDVersionID_MockMethod = { _, _ in }

        return FileVersioningViewModel(
            nodeID: UUID(),
            name: "foo.jpg",
            eTag: nil,
            fetchNodeVersionsUseCase: useCase,
            restoreNodeVersionUseCase: WireDriveRestoreNodeVersionUseCase(
                repository: repository,
                localAssetsRepository: localAssetsRepository,
                nodeCache: MockWireDriveNodeCacheProtocol()
            ),
            getAssetUseCase: WireDriveGetAssetUseCase(
                localAssetRepository: localAssetsRepository,
                fileCache: MockFileCache()
            ),
            accentColorProvider: { .default }
        )
    }
}

// MARK: - Dependencies

private func previewNodesRepository() -> any WireDriveNodesRepositoryProtocol {
    let repository = MockWireDriveNodesRepositoryProtocol()
    let nodes = (0 ... 150).map { index in
        WireDriveNode(
            uuid: UUID(),
            conversation: .init(id: UUID().uuidString, name: "Conversation 1", participants: []),
            path: "root/foo-\(index).jpg",
            modified: Date().addingTimeInterval(Double(-index * 60)),
            mimeType: "image/jpeg",
            ownerUserName: "Person \(index)",
        )
    }
    repository.getVersionsNodeID_MockValue = WireDriveNodeVersion.mock
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

private func previewEditingURLRepository() -> any WireDriveEditingURLRepositoryProtocol {
    let mock = MockWireDriveEditingURLRepositoryProtocol()
    mock.getEditorURLId_MockValue = nil
    return mock
}

private func previewPublicLinkApi() -> some NodesAPIProtocol {
    let mock = MockNodesAPIProtocol()
    let publicLink = WireDrivePublicLink(
        linkID: "aaa",
        url: URL(string: "https://wire.com")!,
        requiresPassword: true,
        expirationDate: Date()
    )

    mock.getPublicLinkLinkID_MockMethod = { _ in
        publicLink
    }

    mock.updatePublicLinkPasswordLinkIDPassword_MockValue = publicLink

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

private final class PreviewLocalAssetRepository: WireDriveLocalAssetRepositoryProtocol, @unchecked Sendable {

    var failIndex = 0
    var publishers: [UUID: CurrentValueSubject<WireDriveLocalAsset?, Never>] = [:]

    func asset(nodeID: UUID) throws -> WireMessagingDomain.WireDriveLocalAsset? {
        publishers[nodeID]?.value
    }

    func refreshAssetMetadata(
        nodeID: UUID
    ) async throws -> (node: WireDriveNode, asset: WireDriveLocalAsset) {
        let node = WireDriveNode(
            uuid: .init(),
            conversation: .init(
                id: UUID().uuidString,
                name: "Conversation 1",
                participants: []
            ),
            path: ""
        )

        let localAsset = WireDriveLocalAsset(
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
            let downloadState: WireDriveLocalAsset.DownloadState = if shouldFail, progress > 0.1 {
                .failed(error: URLError(.notConnectedToInternet))
            } else if progress < 1 {
                .downloading(progress: Double(progress))
            } else {
                .downloaded(cacheKey: "cacheKey")
            }

            try await Task.sleep(for: .milliseconds(200))
            let update = WireDriveLocalAsset(
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

    func observeAsset(nodeID: UUID) -> AnyPublisher<WireMessagingDomain.WireDriveLocalAsset?, Never> {
        let publisher = publishers[nodeID] ?? CurrentValueSubject<WireDriveLocalAsset?, Never>(nil)
        publishers[nodeID] = publisher
        return publisher.eraseToAnyPublisher()
    }

    func cancelDownload(nodeID: UUID) {}

}

extension CreateFileViewModel {
    /// A stubbed instance of `CreateFileViewModel` for SwiftUI previews.
    static func preview() -> CreateFileViewModel {
        let createFileUseCase = MockWireDriveCreateFileUseCaseProtocol()

        return CreateFileViewModel(
            creationTarget: .file(.init(
                kind: .document,
                editable: true,
                label: "Microsoft Word",
                id: "01-Microsoft Word.docx"
            )),
            path: "Test-1/Test-2",
            createFileUseCase: createFileUseCase
        )
    }
}

extension ExpirationDatePickerView.ViewModel {
    static func preview(date: Date?) -> ExpirationDatePickerView.ViewModel {
        ExpirationDatePickerView.ViewModel(
            linkID: "",
            expirationDate: date,
            didSave: { _ in },
            updatePublicLinkExpiration: .init(nodesAPI: previewTagsApi())
        )
    }
}

extension ShareLinkPasswordView.ViewModel {
    static func preview(password: String?, requiresPassword: Bool) -> ShareLinkPasswordView.ViewModel {
        let nodesAPI = previewPublicLinkApi()
        let keychain = Keychain()

        let useCases = UseCases(
            updatePublicLinkPassword: WireDriveUpdatePublicLinkPasswordUseCase(nodesAPI: nodesAPI),
            storePublicLinkPasswordUseCase: WireDriveStorePublicLinkPasswordUseCase(keychain: keychain),
            deletePublicLinkPasswordUseCase: WireDriveDeletePublicLinkPasswordUseCase(keychain: keychain)
        )

        return ShareLinkPasswordView.ViewModel(
            password: password,
            requiresPassword: requiresPassword,
            linkID: "aaa",
            useCases: useCases,
            didSave: { _, _ in }
        )
    }
}

extension WireDriveNodeVersion {
    static let mock: [WireDriveNodeVersion] = [
        .init(
            id: UUID(),
            ownerName: "foo1",
            modified: .init(timeIntervalSince1970: 1_759_311_973),
            eTag: "something",
            size: 2_158_877,
            downloadUrl: URL(string: "https://wire.com")
        ),
        .init(
            id: UUID(),
            ownerName: "foo2",
            modified: .init(timeIntervalSince1970: 1_759_311_973),
            eTag: "something",
            size: 172_493,
            downloadUrl: URL(string: "https://wire.com")
        ),
        .init(
            id: UUID(),
            ownerName: "foo3",
            modified: .init(timeIntervalSince1970: 1_761_663_940),
            eTag: "something",
            size: 2_216_387,
            downloadUrl: URL(string: "https://wire.com")
        ),
        .init(
            id: UUID(),
            ownerName: "foo4",
            modified: .init(timeIntervalSince1970: 1_761_663_393),
            eTag: "something",
            size: 2_216_387,
            downloadUrl: URL(string: "https://wire.com")
        ),
        .init(
            id: UUID(),
            ownerName: "foo5",
            modified: .init(timeIntervalSince1970: 1_759_241_119),
            eTag: "something",
            size: 27_808,
            downloadUrl: URL(string: "https://wire.com")
        ),
        .init(
            id: UUID(),
            ownerName: "foo6",
            modified: .init(timeIntervalSince1970: 1_759_369_815),
            eTag: "something",
            size: 27_808,
            downloadUrl: URL(string: "https://wire.com")
        ),
        .init(
            id: UUID(),
            ownerName: "foo7",
            modified: .init(timeIntervalSince1970: 1_759_401_599),
            eTag: "something",
            size: 27_808,
            downloadUrl: URL(string: "https://wire.com")
        ),
        .init(
            id: UUID(),
            ownerName: "foo8",
            modified: .init(timeIntervalSince1970: 1_761_681_900),
            eTag: "something",
            size: 27_808,
            downloadUrl: URL(string: "https://wire.com")
        ),
        .init(
            id: UUID(),
            ownerName: "foo9",
            modified: .init(timeIntervalSince1970: 1_761_628_800),
            eTag: "something",
            size: 27_808,
            downloadUrl: URL(string: "https://wire.com")
        )
    ]
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
