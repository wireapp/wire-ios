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

public struct SearchConversationsUseCase<ConversationContainer>: SearchConversationsUseCaseProtocol
where ConversationContainer: SearchableConversationContainer {

    var conversationContainers: [ConversationContainer]

    public init(conversationContainers: [ConversationContainer]) {
        self.conversationContainers = conversationContainers
    }

    public func invoke(searchText: String) -> [ConversationContainer] {
        fatalError()

        /*

        // TODO: make use case

        // filter based on search text
        guard !appliedSearchText.isEmpty else { return sections }
        for s in sections.indices {
            sections[s].items = sections[s].items.filter { item in
                guard let conversation = item.item as? ZMConversation else { return true }

                // group name matches
                if let conversationName = conversation.name?.lowercased(), conversationName.contains(appliedSearchText) {
                    return true
                }

                // participant's name contains search text
                for participant in conversation.participants {
                    if let participantName = participant.name?.lowercased(), participantName.contains(appliedSearchText) {
                        return true
                    }
                }

                return false
            }
        }
        return sections

         */
    }
}
