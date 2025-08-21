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

import UniformTypeIdentifiers
import SwiftUI
import WireFoundation
package import WireMessagingDomain

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

    package init(fetchNodesUseCase: WireCellsFetchNodesUseCase) {
        self.fetchNodesUseCase = fetchNodesUseCase
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

@MainActor
/// A view model for a single item in the `FilesView`.
///
/// A view model is needed as the item is _live_ - it can be updated remotely, it's file downloaded locally, and so on.
/// A locally downloaded file may also become out of date and need to be re-downloaded. Using a view model allows us to
/// have granular subscriptions to events that are cancelled when the view is no longer in view.
final class FilesItemViewModel: ObservableObject {

    let fileName: String
    let subtitle: String?
    let icon: FileIcon

    init(item: FilesViewItem) {
        self.fileName = item.filename
        self.subtitle = Self.subtitle(from: item)
        self.icon = item.icon
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
