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

        var title: String {
            switch self {
            case .ascending:
                Strings.Order.ascending
            case .descending:
                Strings.Order.descending
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
        case lastModified
        case name
        case size
        case owner
        case conversation

        var title: String {
            switch self {
            case .lastModified:
                Strings.Key.lastModified
            case .name:
                Strings.Key.name
            case .size:
                Strings.Key.size
            case .owner:
                Strings.Key.owner
            case .conversation:
                Strings.Key.conversation
            }
        }
    }

    struct SortingSelection {
        var sortingKey: SortingKey
        var sortingOrder: SortingOrder
    }

    @Published var sortingSelection: SortingSelection

    let isBrowsing: Bool
    private let onUpdate: (SortingSelection) -> Void

    var availableSortingKeys: [SortingKey] {
        if isBrowsing {
            SortingKey.allCases
        } else {
            [.lastModified, .name, .size, .owner] // omit `conversation` key
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
        sortingSelection.sortingKey = sortingKey
        onUpdate(sortingSelection)
    }

    func select(sortingOrder: SortingOrder) {
        sortingSelection.sortingOrder = sortingOrder
        onUpdate(sortingSelection)
    }

}

extension FilesSortingViewModel.SortingSelection {
    static let `default` = Self(sortingKey: .lastModified, sortingOrder: .ascending)
}
