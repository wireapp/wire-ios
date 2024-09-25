//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireUIFoundation

extension ConversationListViewController: MainConversationListProtocol {
    var conversationFilter: ConversationFilter? {
        get { listContentController.listViewModel.selectedFilter }
        set { listContentController.listViewModel.selectedFilter = newValue }
    }
}

// MARK: - ConversationFilter + MainConversationFilterRepresentable

extension ConversationFilter: MainConversationFilterRepresentable {

    init(_ mainConversationFilter: MainConversationFilter) {
        switch mainConversationFilter {
        case .favorites: self = .favorites
        case .groups: self = .groups
        case .oneOnOne: self = .oneOnOne
        }
    }

    func mapToMainConversationFilter() -> MainConversationFilter {
        switch self {
        case .favorites: .favorites
        case .groups: .groups
        case .oneOnOne: .oneOnOne
        }
    }
}
