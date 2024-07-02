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

    private let conversationContainers: [ConversationContainer]

    public init(conversationContainers: [ConversationContainer]) {
        self.conversationContainers = conversationContainers
    }

    public func invoke(searchText: String) -> [ConversationContainer] {

        let searchText = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if searchText.isEmpty {
            return conversationContainers
        }

        // create a copy, since conversations to be filtered are removed
        var conversationContainers = conversationContainers

        // iterate through all containers and all conversations and remove those who don't match the search text
        for containerIndex in conversationContainers.indices {
        conversationLoop:
            for conversationIndex in conversationContainers[containerIndex].conversations.indices.reversed() {

                let conversation = conversationContainers[containerIndex].conversations[conversationIndex]

                // check if conversation name matches
                if conversation.searchableName.lowercased().contains(searchText) {
                    continue
                }

                // check if any participant's name matches
                for participant in conversation.searchableParticipants where participant.searchableName.lowercased().contains(searchText) {
                    continue conversationLoop
                }

                // no match, remove conversation from results
                conversationContainers[containerIndex].removeConversation(at: conversationIndex)
            }
        }

        return conversationContainers
    }
}
