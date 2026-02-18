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

extension FilesFilterBy.ConversationView {
    @MainActor
    final class ViewModel: ObservableObject {
        typealias Item = WireDriveConversation

        @Published var selectedItems: Set<Item> = []
        @Published var presentedItems: [Item] = []
        
        @Published var searchText = "" {
            didSet {
                updatePresentedItems()
            }
        }

        private let initiallySelectedItems: Set<Item>
        private let availableItems: [Item]

        init(availableItems: some Collection<Item>, selectedItems: some Collection<Item>) {
            let items = Set(selectedItems)
            self.selectedItems = items
            self.initiallySelectedItems = items
            self.availableItems = availableItems.sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            updatePresentedItems()
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
                selectedItems = [] // TODO: remove later when we have multi-select
                selectedItems.insert(item)
            }
        }

        func clearAll() {
            selectedItems = []
        }

        private func updatePresentedItems() {
            let searchText = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            presentedItems = availableItems.filter { item in
                if searchText.isEmpty {
                    true
                } else {
                    item.name.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
}
