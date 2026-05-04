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

        var containers: [ConversationContainer] = []
        for container in conversationContainers {
            var oneOnOneMatches: [ConversationContainer.Conversation] = []
            var nameMatches: [ConversationContainer.Conversation] = []
            var participantMatches: [ConversationContainer.Conversation] = []

            for conversation in container.conversations {
                if conversation.nameMatches(query: query) {
                    if conversation.isOneOnOne {
                        oneOnOneMatches.append(conversation)
                    } else {
                        nameMatches.append(conversation)
                    }
                } else if conversation.participantsMatch(query: query) {
                    if conversation.isOneOnOne {
                        oneOnOneMatches.append(conversation)
                    } else {
                        participantMatches.append(conversation)
                    }
                }
            }

            var filteredContainer = container
            filteredContainer.conversations = oneOnOneMatches + nameMatches + participantMatches
            containers.append(filteredContainer)
        }

        return containers
    }
}

private extension FilterableConversation {
    func nameMatches(query: String) -> Bool {
        let conversationName = name.normalizedForSearch() as String
        return conversationName.lowercased().contains(query)
    }

    func participantsMatch(query: String) -> Bool {
        otherParticipants.contains { participant in
            let participantName = participant.name.normalizedForSearch() as String
            return participantName.lowercased().contains(query)
        }
    }
}
