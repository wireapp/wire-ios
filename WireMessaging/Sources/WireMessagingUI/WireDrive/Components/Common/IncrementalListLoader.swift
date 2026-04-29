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
import Observation

/// A generic loader for paginated lists of items.
@MainActor
class IncrementalListLoader<Item: Identifiable & Hashable & Sendable>: Observable, ObservableObject {
    private typealias LoadTask = Task<(items: [Item], isLastPage: Bool), any Error>
    typealias ItemsData = (items: [Item], isLastPage: Bool)

    enum State: Hashable {
        case loading
        case received(items: [Item])
        case pending
        case error(isConnectionError: Bool)

        var items: [Item] {
            switch self {
            case let .received(items):
                items
            default:
                []
            }
        }

        var isLoaded: Bool {
            switch self {
            case .loading, .pending, .error:
                false
            case .received:
                true
            }
        }
    }

    /// How close to the end of the list before loading more items.
    var loadMoreThreshold = 5

    @Published var state: State = .pending
    @Published var hasMore = true

    private var loadTask: LoadTask?

    var onFetch: ((Int) async throws -> ItemsData)?
    var onError: ((any Error) -> Void)?

    /// Reloads the items, clearing any previously loaded items.
    /// - Parameters:
    ///   - refreshing: Whether the reload was triggered by a pull-to-refresh action.
    ///
    /// Cancels any ongoing load operation and starts a new one.
    /// When `refreshing` is `true`, the current state is preserved since loading is managed by the system.
    func reload(refreshing: Bool = false) async {
        cancelLoad()
        state = refreshing ? state : .loading
        hasMore = !refreshing

        await loadMore(refreshing: refreshing)
    }

    /// Loads more items if available and `index` is towards the end of the list.
    ///
    /// This method checks if the `index` is within the threshold for loading more items. For example given a threshold
    /// of 5, when 10 items are loaded, it will load more when the index is 5 or above - i.e. when one of the last 5
    /// items is being displayed.
    ///
    /// - Parameter index: The index of the item which requested load more.
    func loadMoreIfNeeded(index: Int) async {
        let remaining = state.items.count - index - 1
        if remaining < loadMoreThreshold, hasMore {
            await loadMore()
        }
    }

    var isLoading: Bool {
        loadTask != nil
    }
}

private extension IncrementalListLoader {
    func cancelLoad() {
        loadTask?.cancel()
        loadTask = nil
    }

    func loadMore(refreshing: Bool = false) async {
        guard loadTask == nil else { return }

        let offset = refreshing ? 0 : state.items.count
        let task = Task {
            try await fetchItems(offset: offset)
        }

        loadTask = task
        defer { loadTask = nil }

        do {
            let (newItems, isLastPage) = try await task.value
            let receivedItems = refreshing ? newItems : state.items + newItems
            state = .received(items: receivedItems)
            hasMore = !isLastPage
        } catch is CancellationError {
            return // developer-driven error, discard
        } catch {
            hasMore = state.items.isEmpty ? true : hasMore
            onError?(error)
        }
    }

    func fetchItems(offset: Int) async throws -> ItemsData {
        if let onFetch {
            let itemsData = try await onFetch(offset)
            try Task.checkCancellation()
            return itemsData
        } else {
            return (items: [], isLastPage: true)
        }
    }
}
