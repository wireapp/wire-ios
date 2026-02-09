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

final class FilesFilteringViewModel: ObservableObject {

    typealias ID = String

    enum Filtering: CaseIterable {
        case tags
        case type
        case conversation
        case owner
        case sharedByMe
        case removeAllFilters

        var title: String {
            switch self {
            case .tags:
                "Tags"
            case .type:
                "Type"
            case .conversation:
                "Conversation"
            case .owner:
                "Owner"
            case .sharedByMe:
                "Shared by me"
            case .removeAllFilters:
                "Remove all filters"
            }
        }
    }

    struct FiltersSelection {
        let tags: Set<ID>
        let types: Set<ID>
        let conversations: Set<ID>
        let owners: Set<ID>
        let sharedByMe: Bool

        var hasFilterSelected: Bool {
            !tags.isEmpty || !types.isEmpty || !conversations.isEmpty || !owners.isEmpty || sharedByMe
        }
    }

    @Published var filtersSelection: FiltersSelection

    init() {
        self.filtersSelection = .init(
            tags: [UUID().uuidString],
            types: [],
            conversations: [],
            owners: [],
            sharedByMe: false
        )
    }

    var hasFiltersSelected: Bool {
        filtersSelection.hasFilterSelected
    }

    func isFilterSelected(_ filter: Filtering) -> Bool {
        switch filter {
        case .tags:
            !filtersSelection.tags.isEmpty
        case .type:
            !filtersSelection.types.isEmpty
        case .conversation:
            !filtersSelection.conversations.isEmpty
        case .owner:
            !filtersSelection.owners.isEmpty
        case .sharedByMe:
            filtersSelection.sharedByMe
        case .removeAllFilters:
            false
        }
    }

    func filtersCount(for filter: Filtering) -> Int? {
        switch filter {
        case .tags:
            isFilterSelected(filter) ? filtersSelection.tags.count : nil
        case .type:
            isFilterSelected(filter) ? filtersSelection.types.count : nil
        case .conversation:
            isFilterSelected(filter) ? filtersSelection.conversations.count : nil
        case .owner:
            isFilterSelected(filter) ? filtersSelection.owners.count : nil
        case .sharedByMe:
            isFilterSelected(filter) ? 1 : nil
        case .removeAllFilters:
            nil
        }
    }

}
