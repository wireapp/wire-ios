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
        case descending
        case ascending

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
        case owner
        case size
        case name
        case lastModified

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
            }
        }
    }

    struct SortingModel {
        let sortingKey: SortingKey
        let sortingOrder: SortingOrder
    }

    @Published var model: SortingModel
    private let onSelect: (SortingKey, SortingOrder) -> Void

    init(
        model: SortingModel,
        onSelect: @escaping (SortingKey, SortingOrder) -> Void
    ) {
        self.model = model
        self.onSelect = onSelect
    }

    func select(sortingKey: SortingKey) {
        onSelect(sortingKey, model.sortingOrder)
    }

    func select(sortingOrder: SortingOrder) {
        onSelect(model.sortingKey, sortingOrder)
    }

}
