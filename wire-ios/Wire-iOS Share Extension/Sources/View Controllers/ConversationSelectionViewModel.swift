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
import WireShareEngine

final class ConversationSelectionViewModel {

    struct DisplayState {
        let rows: [Row]
        let emptyState: EmptyState?
    }

    struct Row {
        let title: String?
    }

    struct EmptyState {}

    enum Route {
        case selectConversation(Conversation)
    }

    private let allConversations: [Conversation]
    private(set) var visibleConversations: [Conversation]

    var displayState: DisplayState {
        DisplayState(
            rows: visibleConversations.map { conversation in
                Row(title: conversation.name)
            },
            emptyState: visibleConversations.isEmpty ? EmptyState() : nil
        )
    }

    init(conversations: [Conversation]) {
        self.allConversations = conversations
        self.visibleConversations = conversations
    }

    func updateSearchText(_ searchText: String?) {
        guard let searchText, !searchText.isEmpty else {
            visibleConversations = allConversations
            return
        }

        visibleConversations = allConversations.filter { conversation in
            conversation.name?.range(of: searchText, options: [.diacriticInsensitive, .caseInsensitive]) != nil
        }
    }

    func routeForSelectingRow(at index: Int) -> Route? {
        guard visibleConversations.indices.contains(index) else { return nil }

        return .selectConversation(visibleConversations[index])
    }
}
