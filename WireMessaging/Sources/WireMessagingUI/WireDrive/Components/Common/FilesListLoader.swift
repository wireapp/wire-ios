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
import Foundation
import Observation
import WireLogging

/// Loads and manages a paginated list of `FilesViewItem` elements.
@MainActor
class FilesListLoader: Observable, ObservableObject {
    typealias Loader = IncrementalListLoader<FilesViewItem>

    @Published private(set) var networkMonitor: NetworkMonitor
    @Published private(set) var loader: Loader

    var onFetchOnlineFiles: ((Int) async throws -> (items: [FilesViewItem], isLastPage: Bool))?
    var onFetchOfflineFiles: (() async throws -> [FilesViewItem])?
    var onErrorToPresent: ((any Error) -> Void)?

    init(networkMonitor: NetworkMonitor = .shared) {
        self.networkMonitor = networkMonitor

        self.loader = .init()
        loader.onFetch = { [weak self] offset in
            guard let self else { return (items: [], isLastPage: true) }

            if isOffline {
                let items = try await onFetchOfflineFiles?() ?? []
                return (items: items, isLastPage: true)
            } else {
                let (items, isLastPage) = try await onFetchOnlineFiles?(offset) ?? ([], true)
                return (items: items.latestModified(), isLastPage: isLastPage)
            }
        }
        loader.onError = { [weak self] error in
            guard let self else { return }

            if isOffline {
                WireLogger.wireDrive.error("Error fetching offline assets:\n\(error)")
                onErrorToPresent?(error)
            } else {
                if loader.state.items.isEmpty {
                    loader.state = .error(isConnectionError: error.isNoInternetError)
                } else {
                    if !error.isNoInternetError {
                        WireLogger.wireDrive.error("Error fetching online files:\n\(error)")
                        onErrorToPresent?(error)
                    }
                }
            }
        }
    }

    private var isOffline: Bool {
        networkMonitor.currentStatus == .disconnected
    }

    /// Removes an item from the list, then performs an async action.
    /// If the action fails, restores the list to how it was before removing the item.
    func removeItem(_ item: FilesViewItem, withAction action: @escaping () async throws -> Void) async {
        let items = loader.state.items
        let changedItems = items.filter { $0.id != item.id }
        loader.state = .received(items: changedItems)

        do {
            try await action()
        } catch {
            guard loader.state.isLoaded else { return }

            // set items to how they were before the change:
            loader.state = .received(items: items)
        }
    }
}

private extension Collection<FilesViewItem> {
    /// Removes items with duplicate IDs keeping the latest modified if known, otherwise the first.
    func latestModified() -> [FilesViewItem] {
        var latestByID: [UUID: FilesViewItem] = [:]
        for item in self {
            if let existing = latestByID[item.id] {
                let existingDate = existing.modifiedAt ?? .distantPast
                let newDate = item.modifiedAt ?? .distantPast
                if newDate > existingDate {
                    latestByID[item.id] = item
                }
            } else {
                latestByID[item.id] = item
            }
        }

        var results: [FilesViewItem] = []
        for item in self where item == latestByID[item.id] {
            results.append(item)
        }

        return results
    }
}
