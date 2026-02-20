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

private typealias Strings = L10n.Localizable.Conversation.WireCells.Filtering

final class FilesFilteringViewModel: ObservableObject {

    enum Filtering: CaseIterable {
        case tags
        case type
        case conversation
        case owner
        case sharedLink

        var title: String {
            switch self {
            case .tags:
                Strings.tags
            case .type:
                Strings.type
            case .conversation:
                Strings.conversation
            case .owner:
                Strings.owner
            case .sharedLink:
                Strings.sharedLink
            }
        }
    }

    struct FiltersSelection: Hashable {
        var tags: Set<String>
        var types: Set<WireDriveFileType>
        var conversations: Set<WireDriveConversation>
        var owners: Set<WireDriveConversation.Participant>
        
        /// Meaning of values:
        /// - `true`: show only files with links
        /// - `false`: show only files without links
        /// - `nil`: show all files regardless of links
        ///
        /// For now, the backend only supports the first and the last.
        var sharedLink: Bool?

        var hasFilterSelected: Bool {
            !tags.isEmpty || !types.isEmpty || !conversations.isEmpty || !owners.isEmpty || sharedLink != nil
        }
    }

    enum SheetNavigation: String, Identifiable {
        case tags
        case types
        case conversations
        case owners
        case sharedLink // currently not used, but probably will be later when the backend capability is expanded

        var id: String {
            rawValue
        }
    }

    struct UseCases {
        let fetchTagsUseCase: any WireDriveGetTagSuggestionsUseCaseProtocol
    }

    @Published var filtersSelection: FiltersSelection {
        didSet {
            onUpdate(filtersSelection)
        }
    }

    @Published var sheetNavigation: SheetNavigation?

    private let onUpdate: (FiltersSelection) -> Void
    let useCases: UseCases
    let isBrowsing: Bool

    var availableFilters: [Filtering] {
        if isBrowsing {
            Filtering.allCases
        } else {
            Filtering.allCases.filter { $0 != .conversation }
        }
    }

    init(
        useCases: UseCases,
        filtersSelection: FiltersSelection,
        isBrowsing: Bool,
        onUpdate: @escaping (FiltersSelection) -> Void
    ) {
        self.useCases = useCases
        self.filtersSelection = filtersSelection
        self.isBrowsing = isBrowsing
        self.onUpdate = onUpdate
    }

    // MARK: - Actions

    func select(filter: Filtering) {
        switch filter {
        case .tags:
            sheetNavigation = .tags
        case .type:
            sheetNavigation = .types
        case .conversation:
            sheetNavigation = .conversations
        case .owner:
            sheetNavigation = .owners
        case .sharedLink:
            if filtersSelection.sharedLink == true {
                filtersSelection.sharedLink = nil
            } else {
                filtersSelection.sharedLink = true
            }
        }
    }

    func removeAllFilters() {
        filtersSelection = .empty
    }

    // MARK: - UI

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
        case .sharedLink:
            filtersSelection.sharedLink != nil
        }
    }

    func badge(for filter: Filtering) -> String? {
        let filtersCount: Int? = switch filter {
        case .tags:
            isFilterSelected(filter) ? filtersSelection.tags.count : nil
        case .type:
            isFilterSelected(filter) ? filtersSelection.types.count : nil
        case .conversation:
            isFilterSelected(filter) ? filtersSelection.conversations.count : nil
        case .owner:
            isFilterSelected(filter) ? filtersSelection.owners.count : nil
        case .sharedLink:
            nil
        }

        return filtersCount.map(String.init)
    }

}

extension FilesFilteringViewModel.FiltersSelection {
    static let empty = Self(
        tags: [],
        types: [],
        conversations: [],
        owners: [],
        sharedLink: nil
    )
}

extension FilesFilteringViewModel.FiltersSelection {
    func toDomainModel() -> Set<WireDriveNodesMetaFilter> {
        var metafilter = Set<WireDriveNodesMetaFilter>()
        
        if !tags.isEmpty {
            metafilter.insert(.tags(tags))
        }
        
        if !types.isEmpty {
            metafilter.insert(.types(types))
        }
        
        if !conversations.isEmpty {
            metafilter.insert(.conversations(conversations))
        }
        
        if !owners.isEmpty {
            metafilter.insert(.owners(owners))
        }
        
        return metafilter
    }
}
