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
import WireFoundation
package import WireMessagingDomain

struct FilesViewItem: Identifiable {
    let id: UUID
    let filename: String
    let ownedBy: String?
    let modifiedAt: Date?
}

@MainActor
class FilesItemViewModel: ObservableObject {

    let fileName: String
    let subtitle: String?

    init(item: FilesViewItem) {
        self.fileName = item.filename
        self.subtitle = Self.subtitle(from: item)
    }

    private static func subtitle(from item: FilesViewItem) -> String? {
        let modifiedAt = item.modifiedAt.map { $0.formatted(date: .abbreviated, time: .shortened) }
        return if let modifiedAt, let ownedBy = item.ownedBy {
            L10n.Localizable.Conversation.WireCells.Files.Item.subtitle(modifiedAt, ownedBy)
        } else {
            [modifiedAt, item.ownedBy].compactMap(\.self).first
        }
    }

}

@MainActor
package class FilesViewModel: ObservableObject {

    private typealias LoadItemsTask = Task<(items: [FilesViewItem], nextPage: WireCellsPageToken?), any Error>

    private enum Constants {

        /// How close to the end of the list before loading more items.
        static let loadMoreThreshold = 5
    }

    enum Alert {
        case noInternet
        case unknownError
    }

    private let fetchNodesUseCase: WireCellsFetchNodesUseCase

    package init(fetchNodesUseCase: WireCellsFetchNodesUseCase) {
        self.fetchNodesUseCase = fetchNodesUseCase
    }

    @Published private(set) var items: [FilesViewItem] = []
    @Published private var nextPageToken: WireCellsPageToken?
    @Published private var loadMoreTask: LoadItemsTask?
    @Published var alert: Alert?

    var hasMore: Bool {
        nextPageToken != nil
    }

    var isLoading: Bool {
        loadMoreTask != nil
    }

    func reload() async {
        cancelLoad()
        items = []
        nextPageToken = nil

        await loadMore()
    }

    func loadMoreIfNeeded(index: Int) async {
        let remaining = items.count - index - 1
        if remaining < Constants.loadMoreThreshold, nextPageToken != nil {
            await loadMore()
        }
    }

    func itemViewModel(index: Int) -> FilesItemViewModel {
        FilesItemViewModel(item: items[index])
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
            FilesViewItem(
                id: node.id,
                filename: URL(string: node.path)?.lastPathComponent ?? node.path,
                ownedBy: node.ownerUserName,
                modifiedAt: node.modified
            )
        }

        try Task.checkCancellation()
        return (items, nextPage)
    }

}
