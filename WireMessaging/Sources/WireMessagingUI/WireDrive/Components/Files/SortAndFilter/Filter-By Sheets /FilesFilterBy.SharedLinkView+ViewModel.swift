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

extension FilesFilterBy.SharedLinkView {
    @MainActor
    final class ViewModel: ObservableObject {
        enum Item: CaseIterable, Hashable {
            case withSharedLink
            case withoutSharedLink
        }

        @Published var selectedItems: Set<Item> = []

        @Published var presentedItems: [Item] = []

        private let initiallySelectedItems: Set<Item>

        init(selectedItems: some Collection<Item>) {
            let items = Set(selectedItems)
            self.selectedItems = items
            self.initiallySelectedItems = items
            self.presentedItems = Item.allCases.filter { $0 != .withoutSharedLink } // withoutSharedLink is currently not supported by the backend API. This might change in the future.
        }

        var hasChanges: Bool {
            selectedItems != initiallySelectedItems
        }

        func isItemSelected(_ item: Item) -> Bool {
            selectedItems.contains(item)
        }

        func toggleItemSelection(_ item: Item) {
            if selectedItems.contains(item) {
                selectedItems.remove(item)
            } else {
                selectedItems = []
                selectedItems.insert(item)
            }
        }

        func clearAll() {
            selectedItems = []
        }
    }
}

extension Collection<FilesFilterBy.SharedLinkView.ViewModel.Item> {
    static func fromBool(_ value: Bool?) -> Set<Element> {
        switch value {
        case true:
            [.withSharedLink]
        case false:
            [.withoutSharedLink]
        case nil:
            []
        }
    }

    func toBool() -> Bool? {
        if contains(.withSharedLink) {
            true
        } else if contains(.withoutSharedLink) {
            false
        } else {
            nil
        }
    }
}
