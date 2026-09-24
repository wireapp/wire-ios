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

import Foundation
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells.Sorting

final class FilesSortingViewModel: ObservableObject {

    enum SortingOrder: String, CaseIterable {
        case ascending
        case descending

        func title(forKey key: SortingKey) -> String {
            switch key {
            case .date:
                self == .descending ? Strings.Order.Date.recentFirst : Strings.Order.Date.oldestFirst
            case .name:
                self == .descending ? Strings.Order.Name.za : Strings.Order.Name.az
            case .size:
                self == .descending ? Strings.Order.Size.largestFirst : Strings.Order.Size.smallestFirst
            }
        }

        var iconName: String {
            switch self {
            case .ascending:
                "arrow.up"
            case .descending:
                "arrow.down"
            }
        }
    }

    enum SortingKey: String, CaseIterable {
        case date
        case name
        case size

        var title: String {
            switch self {
            case .date:
                Strings.Key.date
            case .name:
                Strings.Key.name
            case .size:
                Strings.Key.size
            }
        }

        var sortField: String {
            switch self {
            case .date:
                "mtime"
            case .name:
                "name"
            case .size:
                "size"
            }
        }
    }

    struct SortingSelection {
        var sortingKey: SortingKey?
        var sortingOrder: SortingOrder?
    }

    @Published var sortingSelection: SortingSelection

    let isBrowsing: Bool
    private let onUpdate: (SortingSelection) -> Void
    private let subfolderName: String?

    var sortingOrders: [SortingOrder] {
        switch sortingSelection.sortingKey {
        case .name, .size:
            SortingOrder.allCases
        default:
            [.descending, .ascending]
        }
    }

    init(
        isBrowsing: Bool,
        subfolderName: String? = nil,
        onUpdate: @escaping (SortingSelection) -> Void
    ) {
        self.sortingSelection = isBrowsing ? .defaultDrive : .defaultSharedDrive
        self.isBrowsing = isBrowsing
        self.subfolderName = subfolderName
        self.onUpdate = onUpdate
    }

    // MARK: - Actions

    func select(sortingKey: SortingKey) {
        sortingSelection.sortingOrder = switch sortingKey {
        case .date: .descending
        case .name, .size: .ascending
        }
        sortingSelection.sortingKey = sortingKey
        onUpdate(sortingSelection)
    }

    func select(sortingOrder: SortingOrder) {
        if sortingSelection.sortingKey == nil {
            sortingSelection.sortingKey = .date
        }
        sortingSelection.sortingOrder = sortingOrder
        onUpdate(sortingSelection)
    }

    // MARK: - UI

    var menuLabel: String {
        if let sortingOrder = sortingSelection.sortingOrder, let sortingKey = sortingSelection.sortingKey {
            sortingOrder.title(forKey: sortingKey)
        } else {
            Strings.title
        }
    }

    var resultsInTitle: String {
        if let subfolderName {
            Strings.Subfolder.results(subfolderName)
        } else {
            Strings.results
        }
    }
}

extension FilesSortingViewModel.SortingSelection {
    /// newest first
    static let defaultDrive = Self(sortingKey: .date, sortingOrder: .descending)

    /// none
    static let defaultSharedDrive = Self(sortingKey: nil, sortingOrder: nil)
}
