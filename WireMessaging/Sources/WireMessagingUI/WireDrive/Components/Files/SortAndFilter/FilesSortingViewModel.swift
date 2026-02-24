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

    enum SortingOrder: CaseIterable {
        case ascending
        case descending

        func title(forKey key: SortingKey) -> String {
            switch key {
            case .date:
                return self == .descending ? Strings.Order.Date.recentFirst : Strings.Order.Date.oldestFirst
            case .name:
                return self == .descending ? Strings.Order.Name.za : Strings.Order.Name.az
            case .size:
                return self == .descending ? Strings.Order.Size.largestFirst : Strings.Order.Size.smallestFirst
            }
        }

        var iconName: String {
            switch self {
            case .ascending:
                "arrow.down"
            case .descending:
                "arrow.up"
            }
        }
    }

    enum SortingKey: CaseIterable {
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
    }

    struct SortingSelection {
        var sortingKey: SortingKey?
        var sortingOrder: SortingOrder?
    }

    @Published var sortingSelection: SortingSelection = .default

    let isBrowsing: Bool
    private let onUpdate: (SortingSelection) -> Void

    var sortingOrders: [SortingOrder] {
        switch sortingSelection.sortingKey {
        case .name, .size:
            SortingOrder.allCases
        default:
            [.descending, .ascending]
        }
    }

    init(
        sortingSelection: SortingSelection = .default,
        isBrowsing: Bool,
        onUpdate: @escaping (SortingSelection) -> Void
    ) {
        self.sortingSelection = sortingSelection
        self.isBrowsing = isBrowsing
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
}

extension FilesSortingViewModel.SortingSelection {
    /// no sorting criterion applied
    static let `default` = Self(sortingKey: nil, sortingOrder: nil)
}
