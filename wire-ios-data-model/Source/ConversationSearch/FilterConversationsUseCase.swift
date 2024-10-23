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

import WireUtilities

/// This use case takes grouped conversations as input and returns the same groups with their conversations
/// filtered by the search text `query`.
///
/// The search text is compared to the name of conversations as well as the names of the conversation's participants.
public struct FilterConversationsUseCase<ConversationContainer>: FilterConversationsUseCaseProtocol
where ConversationContainer: MutableConversationContainer {

    private let conversationContainers: [ConversationContainer]

    public init(conversationContainers: [ConversationContainer]) {
        self.conversationContainers = conversationContainers
    }

    public func invoke(query: String) -> [ConversationContainer] {

        let query = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .normalizedForSearch() as String

        if query.isEmpty {
            return conversationContainers
        }

        // Iterate through the grouped conversations and remove the conversations which don't match the query.
        // Empty containers (conversation groups) will be kept in the result.
        var conversationContainers = conversationContainers
        for containerIndex in conversationContainers.indices {
        conversationLoop:
            for conversationIndex in conversationContainers[containerIndex].conversations.indices.reversed() {

                let conversation = conversationContainers[containerIndex].conversations[conversationIndex]

                // don't remove the conversation from the results if conversation name matches
                let conversationSearchableName = conversation.searchableName.normalizedForSearch() as String
                if conversationSearchableName.lowercased().contains(query) {
                    continue
                }

                // don't remove the conversation from the results if any participant's name matches
                for participant in conversation.searchableParticipants {
                    let participantSearchableName = participant.searchableName.normalizedForSearch() as String
                    if participantSearchableName.lowercased().contains(query) {
                        continue conversationLoop
                    }
                }

                // no match, remove conversation from results
                conversationContainers[containerIndex].removeConversation(at: conversationIndex)
            }
        }
        return conversationContainers
    }
}
