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

import WireDataModel

// sourcery: AutoMockable
/// Facilitate access to message related domain objects.
public protocol MessageLocalStoreProtocol {

    func addSystemMessageToConversation(
        messageType: MessageType,
        conversationID: UUID,
        conversationDomain: String?
    ) async

}

public final class MessageLocalStore: MessageLocalStoreProtocol {

    // MARK: - Properties

    let context: NSManagedObjectContext
    let conversationLocalStore: any ConversationLocalStoreProtocol

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        conversationLocalStore: any ConversationLocalStoreProtocol
    ) {
        self.context = context
        self.conversationLocalStore = conversationLocalStore
    }

    // MARK: - Public

    public func addSystemMessageToConversation(
        messageType: MessageType,
        conversationID: UUID,
        conversationDomain: String?
    ) async {
        guard let conversation = await conversationLocalStore.fetchConversation(
            id: conversationID,
            domain: conversationDomain
        ) else { return }

        let systemMessages = await createSystemMessages(
            from: messageType,
            conversation: conversation
        )

        await addSystemMessages(
            systemMessages,
            to: conversation
        )
    }

    // MARK: - Private

    private func createSystemMessages(
        from messageType: MessageType,
        conversation: ZMConversation
    ) async -> Set<ZMSystemMessage> {
        switch messageType {
        case .federationTermination(let domains, let date):
            let selfUser = await fetchSelfUser()

            let systemMessage = await createSystemMessage(
                messageType: .domainsStoppedFederating,
                sender: selfUser,
                timestamp: date,
                domains: domains
            )

            return [systemMessage]

        case .participantsRemovedAnonymously(let participants, let date):

            let removedUsers = await context.perform {
                participants.compactMap { id, domain in
                    let existing = conversation.localParticipants

                    return existing.first(where: {
                        $0.remoteIdentifier == id && $0.domain == domain
                    })
                }
            }

            let selfUser = await fetchSelfUser()

            let systemMessage = await createSystemMessage(
                messageType: .participantsRemoved,
                sender: selfUser,
                users: Set(removedUsers),
                timestamp: date,
                removedReason: .federationTermination
            )

            return [systemMessage]

        case .mlsMigrationMLSNotSupportedForSelfUser:

            let selfUser = await fetchSelfUser()

            let systemMessage = await createSystemMessage(
                messageType: .mlsNotSupportedSelfUser,
                sender: selfUser,
                users: Set([selfUser])
            )

            return [systemMessage]

        case .mlsMigrationMLSNotSupportedForOtherUser(let otherUser):

            guard let otherUser = await fetchUser(
                id: otherUser.id,
                domain: otherUser.domain
            ) else { return [] }

            let selfUser = await fetchSelfUser()

            let systemMessage = await createSystemMessage(
                messageType: .mlsNotSupportedOtherUser,
                sender: selfUser,
                users: Set([otherUser])
            )

            return [systemMessage]

        case .teamMemberRemoved(let member, let date):

            guard let removedMember = await fetchUser(
                id: member.id,
                domain: member.domain
            ) else { return [] }

            let systemMessage = await createSystemMessage(
                messageType: .teamMemberLeave,
                sender: removedMember,
                users: Set([removedMember]),
                timestamp: date
            )

            return [systemMessage]

        case .participantRemoved(let participant, let sender, let date):

            guard let removedParticipant = await fetchUser(
                id: participant.id,
                domain: participant.domain
            ) else { return [] }

            let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            )

            let systemMessage = await createSystemMessage(
                messageType: .participantsRemoved,
                sender: sender ?? removedParticipant,
                users: Set([removedParticipant]),
                timestamp: date
            )

            return [systemMessage]

        case .newConversationCreated(let date):

            let selfUser = await fetchSelfUser()

            let (creator, localParticipants, userDefinedName) = await context.perform {
                (conversation.creator,
                 conversation.localParticipants,
                 conversation.userDefinedName)
            }

            let newConversationMessage = await createSystemMessage(
                messageType: .newConversation,
                sender: creator,
                users: localParticipants,
                timestamp: date
            )

            await context.perform {
                newConversationMessage.text = userDefinedName

                guard let selfUserTeam = selfUser.team,
                      conversation.team == selfUserTeam else { return }

                let members = selfUserTeam.members.compactMap(\.user)
                let guests = localParticipants.filter {
                    !$0.isServiceUser && $0.membership == nil
                }

                newConversationMessage.allTeamUsersAdded = localParticipants.isSuperset(of: members)
                newConversationMessage.numberOfGuestsAdded = Int16(guests.count)
            }

            let hasReadReceiptsEnabled = await context.perform {
                conversation.hasReadReceiptsEnabled
            }

            guard hasReadReceiptsEnabled else {
                return [newConversationMessage]
            }

            let nextNearestTimestamp = Date(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate.nextUp)

            let receiptModeIsOnMessage = await createSystemMessages(
                from: .receiptModeIsOn(date: nextNearestTimestamp),
                conversation: conversation
            )

            let systemMessages = [newConversationMessage] + receiptModeIsOnMessage

            return Set(systemMessages)

        case .mlsMigrationStarted(let sender, let date):

            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .mlsMigrationStarted,
                sender: sender,
                timestamp: date
            )

            return [systemMessage]

        case .mlsMigrationPotentialGap(let sender, let date):

            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .mlsMigrationPotentialGap,
                sender: sender,
                timestamp: date
            )

            let previousLastMessage = await context.perform {
                conversation.lastMessage
            }

            await context.perform { [context] in
                let lastMessage = previousLastMessage as? ZMSystemMessage
                let isPotentialGapMigration = lastMessage?.systemMessageType == .mlsMigrationPotentialGap
                let lastMessageTimestamp = lastMessage?.serverTimestamp

                if let lastMessage, isPotentialGapMigration {
                    if let lastMessageTimestamp, lastMessageTimestamp <= date {
                        context.delete(lastMessage)
                    }
                }
            }

            return [systemMessage]

        case .mlsMigrationFinalized(let sender, let date):

            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .mlsMigrationFinalized,
                sender: sender,
                timestamp: date
            )

            return [systemMessage]

        case .receiptModeIsOn(let date):

            let creator = await context.perform {
                conversation.creator
            }

            let systemMessage = await createSystemMessage(
                messageType: .readReceiptsOn,
                sender: creator,
                timestamp: date
            )

            return [systemMessage]
        }
    }

    private func createSystemMessage(
        messageType: ZMSystemMessageType,
        sender: ZMUser,
        users: Set<ZMUser>? = nil,
        addedUsers: Set<ZMUser> = Set(),
        clients: Set<UserClient>? = nil,
        timestamp: Date = .now,
        duration: TimeInterval? = nil,
        messageTimer: Double? = nil,
        relevantForStatus: Bool = true,
        removedReason: ZMParticipantsRemovedReason = .none,
        domains: [String]? = nil
    ) async -> ZMSystemMessage {
        await context.perform { [context] in
            let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: context)
            systemMessage.systemMessageType = messageType
            systemMessage.sender = sender
            systemMessage.users = users ?? Set()
            systemMessage.addedUsers = addedUsers
            systemMessage.clients = clients ?? Set()
            systemMessage.serverTimestamp = timestamp

            if let duration {
                systemMessage.duration = duration
            }

            if let messageTimer {
                systemMessage.messageTimer = NSNumber(value: messageTimer)
            }

            systemMessage.relevantForConversationStatus = relevantForStatus
            systemMessage.participantsRemovedReason = removedReason
            systemMessage.domains = domains

            return systemMessage
        }
    }

    private func addSystemMessages(
        _ messages: Set<ZMSystemMessage>,
        to conversation: ZMConversation
    ) async {
        await context.perform {
            for message in messages {
                conversation.append(message)
            }
        }
    }

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: Use UserLocalStore when related PRs are merged.
    private func fetchUser(
        id: UUID,
        domain: String?
    ) async -> ZMUser? {
        await context.perform { [context] in
            ZMUser.fetch(
                with: id,
                domain: domain,
                in: context
            )
        }
    }

    private func fetchSelfUser() async -> ZMUser {
        await context.perform { [context] in
            ZMUser.selfUser(in: context)
        }
    }
}
