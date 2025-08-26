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
package import WireMessagingDomain
import WireMessagingDomainSupport

/// An item in the `FilesView`.
struct FilesViewItem: Identifiable, Equatable {

    /// Identifier of this item on the wire cells backend.
    let id: UUID

    /// The filename of the file including its extension.
    let filename: String

    /// The name of the user who owns (uploaded) this file.
    let ownedBy: String?

    /// The date when the file was last modified.
    let modifiedAt: Date?

    /// The icon representing the file type.
    let icon: FileIcon
}

@MainActor
/// View model for the `FilesView`.
package final class FilesViewModel: ObservableObject {

    private typealias LoadItemsTask = Task<(items: [FilesViewItem], nextPage: WireCellsPageToken?), any Error>

    private enum Constants {

        /// How close to the end of the list before loading more items.
        static let loadMoreThreshold = 5
    }

    private let fetchNodesUseCase: WireCellsFetchNodesUseCase
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol

    package init(
        fetchNodesUseCase: WireCellsFetchNodesUseCase,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    ) {
        self.fetchNodesUseCase = fetchNodesUseCase
        self.localAssetRepository = localAssetRepository
    }

    @Published private(set) var items: [FilesViewItem] = []
    @Published private var nextPageToken: WireCellsPageToken?
    @Published private var loadMoreTask: LoadItemsTask?
    @Published var alert: AlertModel?

    /// Whether there are more items to load.
    var hasMore: Bool {
        nextPageToken != nil
    }

    /// Whether the view model is currently loading items.
    var isLoading: Bool {
        loadMoreTask != nil
    }

    /// Reloads the items, clearing any previously loaded items.
    ///
    /// This method cancels any ongoing load operation and starts a new one.
    func reload() async {
        cancelLoad()
        items = []
        nextPageToken = nil

        await loadMore()
    }

    /// Loads more items if available and `index` is towards the end of the list.
    ///
    /// This method checks if the `index` is within the threshold for loading more items. For example given a threshold
    /// of 5, when 10 items are loaded, it will load more when the index is 5 or above - i.e. when one of the last 5
    /// items is being displayed.
    ///
    /// - Parameter index: The index of the item which requested load more.
    func loadMoreIfNeeded(index: Int) async {
        let remaining = items.count - index - 1
        if remaining < Constants.loadMoreThreshold, nextPageToken != nil {
            await loadMore()
        }
    }

    /// Returns a `FilesItemViewModel` for the item at the given index.
    func itemViewModel(index: Int) -> FilesItemViewModel {
        FilesItemViewModel(item: items[index], localAssetRepository: localAssetRepository)
    }

    // MARK: - Private

    private func cancelLoad() {
        loadMoreTask?.cancel()
        loadMoreTask = nil
    }

    private func loadMore() async {
        guard loadMoreTask == nil else { return }

        let task = Task { try await fetchItems(token: nextPageToken) }

        loadMoreTask = task
        do {
            let (newItems, nextPage) = try await task.value
            items.append(contentsOf: newItems)
            nextPageToken = nextPage
        } catch URLError.notConnectedToInternet, URLError.networkConnectionLost {
            alert = .noInternet
        } catch {
            alert = .unknownError
        }
        loadMoreTask = nil
    }

    private nonisolated func fetchItems(
        token: WireCellsPageToken?
    ) async throws -> (items: [FilesViewItem], nextPage: WireCellsPageToken?) {
        let (nodes, nextPage) = try await fetchNodesUseCase.invoke(searchTerm: nil, token: token)

        let items = nodes.map { node in
            let url = URL(string: node.path)
            return FilesViewItem(
                id: node.id,
                filename: url?.lastPathComponent ?? node.path,
                ownedBy: node.ownerUserName,
                modifiedAt: node.modified,
                icon: .make(
                    type: node.mimeType.map { UTType(mimeType: $0) } ?? nil,
                    fileExtension: url?.pathExtension
                )
            )
        }

        try Task.checkCancellation()
        return (items, nextPage)
    }

}

// MARK: - Stubs

extension FilesViewModel {

    /// A stubbed instance of `FilesViewModel` for SwiftUI previews.
    static func stub() -> FilesViewModel {
        FilesViewModel(
            fetchNodesUseCase: WireCellsFetchNodesUseCase(
                configuration: .conversationFileView(root: .path("root")),
                repository: makeNodesRepository()
            ),
            localAssetRepository: makeLocalAssetRepository()
        )
    }

    private static func makeNodesRepository() -> any WireCellsNodesRepositoryProtocol {
        let repository = MockWireCellsNodesRepositoryProtocol()
        repository.getNodes_MockMethod = { request in
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay

            if request.offset >= 120 {
                throw URLError(.notConnectedToInternet)
            }

            let nodes = (request.offset ..< request.offset + 30).map { index in
                WireCellsNode(
                    uuid: UUID(),
                    path: "root/foo-\(index).jpg",
                    modified: Date(),
                    mimeType: "image/jpeg",
                    ownerUserName: "Person \(index)",
                )
            }
            let nextOffset = request.offset + 30
            return (nodes, nextOffset)
        }
        return repository
    }

    private static func makeLocalAssetRepository() -> any WireCellsLocalAssetRepositoryProtocol {
        class State {
            var failIndex = 0
            var assets: [UUID: CurrentValueSubject<WireCellsLocalAsset?, Never>] = [:]
        }

        let state = State()

        let repository = MockWireCellsLocalAssetRepositoryProtocol()
        repository.assetNodeID_MockMethod = { nodeID in
            state.assets[nodeID]?.value
        }
        repository.downloadAssetNodeID_MockMethod = { nodeID in
            state.failIndex += 1
            // Fail every 3rd download
            let shouldFail = state.failIndex % 3 == 0

            for progress in 0...100 {
                let downloadState: WireCellsLocalAsset.DownloadState = if shouldFail && progress > 10 {
                    .failed(error: URLError(.notConnectedToInternet))
                } else if progress < 100 {
                    .downloading(progress: Double(progress))
                } else {
                    .downloaded(cacheKey: "cacheKey")
                }

                try await Task.sleep(nanoseconds: 50_000_000)
                state.assets[nodeID]?.send(
                    WireCellsLocalAsset(
                        nodeID: nodeID,
                        eTag: "something",
                        path: "some/path.jpg",
                        contentType: nil,
                        size: nil,
                        downloadState: downloadState
                    )
                )
                if shouldFail && progress > 10 {
                    break
                }
            }
        }
        repository.observeAssetNodeID_MockMethod = { nodeID in
            let publisher = state.assets[nodeID] ?? CurrentValueSubject<WireCellsLocalAsset?, Never>(nil)
            state.assets[nodeID] = publisher
            return publisher.eraseToAnyPublisher()
        }

        return repository
    }

}

private class FakeLocalAssetRepository: WireCellsLocalAssetRepositoryProtocol {

    private var failIndex = 0
    private var publishers: [UUID: CurrentValueSubject<WireCellsLocalAsset?, Never>] = [:]

    func asset(nodeID: UUID) throws -> WireMessagingDomain.WireCellsLocalAsset? {
        publishers[nodeID]?.value
    }

    func refreshMetadata(nodeID: UUID) async throws {}

    func downloadAsset(nodeID: UUID) async throws {
        failIndex += 1
        // Fail every 3rd download
        let shouldFail = failIndex % 3 == 0

        for progress in 0...100 {
            let downloadState: WireCellsLocalAsset.DownloadState = if shouldFail && progress > 10 {
                .failed(error: URLError(.notConnectedToInternet))
            } else if progress < 100 {
                .downloading(progress: Double(progress))
            } else {
                .downloaded(cacheKey: "cacheKey")
            }

            try await Task.sleep(nanoseconds: 50_000_000)
            publishers[nodeID]?.send(
                WireCellsLocalAsset(
                    nodeID: nodeID,
                    eTag: "something",
                    path: "some/path.jpg",
                    contentType: nil,
                    size: nil,
                    downloadState: downloadState
                )
            )
            if shouldFail && progress > 10 {
                break
            }
        }
    }

    func observeAsset(nodeID: UUID) -> AnyPublisher<WireCellsLocalAsset?, Never> {
        let publisher = publishers[nodeID] ?? CurrentValueSubject<WireCellsLocalAsset?, Never>(nil)
        publishers[nodeID] = publisher
        return publisher.eraseToAnyPublisher()
    }

    func cancelDownload(nodeID: UUID) {}

}
