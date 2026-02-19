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

extension FilesFilterBy.TypeView {
    @MainActor
    final class ViewModel: ObservableObject {
        typealias Item = FileType

        @Published var selectedItems: Set<Item> = []

        var presentedItems: [Item] = [
            .pdf,
            .document,
            .image,
            .spreadsheet,
            .presentation,
            .video,
            .audio,
            .code,
            .archive,
            //.folder,
            //.other,
        ]

        private let initiallySelectedItems: Set<Item>

        init(includeFolders: Bool, selectedItems: some Collection<Item>) {
            let items = Set(selectedItems)
            self.selectedItems = items
            self.initiallySelectedItems = items
            if !includeFolders {
                presentedItems.removeAll { $0 == .folder }
            }
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
                selectedItems.insert(item)
            }
        }

        func clearAll() {
            selectedItems = []
        }
    }
}
