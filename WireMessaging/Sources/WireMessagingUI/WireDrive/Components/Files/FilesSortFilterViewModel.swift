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

import WireMessagingDomain
import Foundation

package final class FilesSortFilterViewModel: ObservableObject {
    enum QueryOptions: Hashable, Equatable {
        case sorting(Sorting)
        case filtering([Filtering])
        
        struct Sorting: Hashable, Equatable {
            let sortKey: [SortKey]
            let sortOrder: [SortOrder]
            
            struct SortOrder: Hashable, Equatable {
                enum Order: Hashable, Equatable {
                    case ascending
                    case descending
                }
                
                let order: Order
                let isSelected: Bool
            }
            
            struct SortKey: Hashable, Equatable {
                enum Key: Hashable, Equatable {
                    case lastModified
                    case name
                    case size
                }
                
                let key: Key
                let isSelected: Bool
            }
        }
        
        enum Filtering: Hashable, Equatable {
            case tags([Tag])
            case type
            case conversation([Conversation])
            case owner([Owner])
            
            struct Tag: Hashable, Equatable {
                let name: String
                let isSelected: Bool
            }
            
            struct Conversation: Hashable, Equatable {
                let name: String
                let isSelected: Bool
            }
            
            struct Owner: Hashable, Equatable {
                let name: String
                let isSelected: Bool
            }
        }
    }
    
    struct Model {
        let operation: Operation
        let hidden: Bool
    }
    
    @Published var queryOptions: [QueryOptions]
    
    init() {
        let sorting: QueryOptions.Sorting = .init(
            sortKey: [
                .init(key: .lastModified, isSelected: false),
                .init(key: .name, isSelected: true),
                .init(key: .size, isSelected: false)
            ],
            sortOrder: [
                .init(order: .ascending, isSelected: true),
                .init(order: .descending, isSelected: false)
            ]
        )
        
        let filtering: [QueryOptions.Filtering] = [
            .tags([]),
            .conversation([])
        ]
        
        self.queryOptions = [
            .sorting(sorting),
            .filtering(filtering)
        ]
    }
    
    // MARK: UI
    
    func title(for sortKey: QueryOptions.Sorting.SortKey.Key) -> String {
        switch sortKey {
        case .lastModified:
            "Last modified"
        case .name:
            "Name"
        case .size:
            "Size"
        }
    }
    
    func title(for sortOrder: QueryOptions.Sorting.SortOrder.Order) -> String {
        switch sortOrder {
        case .ascending:
            "Ascending"
        case .descending:
            "Descending"
        }
    }
    
    func title(for filtering: QueryOptions.Filtering) -> String {
        switch filtering {
        case .tags:
            "Tags"
        case .type:
            "Type"
        case .conversation:
            "Conversation name"
        case .owner:
            "Owner name"
        }
    }
    
    func title(for sorting: QueryOptions.Sorting) -> String {
        let sortingKey = sorting.sortKey.first(where: \.isSelected)?.key
        return title(for: sortingKey ?? .lastModified)
    }
    
}
