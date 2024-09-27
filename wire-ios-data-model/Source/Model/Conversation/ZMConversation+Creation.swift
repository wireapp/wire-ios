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

import Foundation

extension ZMConversation {
    /// Fetch an existing conversation or create a new one if it doesn't already exist.
    ///
    /// - Parameters:
    ///     - remoteIdentifier: UUID assigned to the conversation.
    ///     - domain: domain assigned to the conversation.
    ///     - context: `NSManagedObjectContext` on which to fetch or create the conversation.
    ///                NOTE that this **must** be the sync context.

    @objc
    public static func fetchOrCreate(
        with remoteIdentifier: UUID,
        domain: String?,
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        var created = false
        return fetchOrCreate(with: remoteIdentifier, domain: domain, in: context, created: &created)
    }

    /// Fetch an existing conversation or create a new one if it doesn't already exist.
    ///
    /// - Parameters:
    ///     - remoteIdentifier: UUID assigned to the conversation.
    ///     - domain: domain assigned to the conversation.
    ///     - context: `NSManagedObjectContext` on which to fetch or create the conversation.
    ///                NOTE that this **must** be the sync context.
    ///     - created: Will be set `true` if a new user was created.

    @objc
    public static func fetchOrCreate(
        with remoteIdentifier: UUID,
        domain: String?,
        in context: NSManagedObjectContext,
        created: UnsafeMutablePointer<Bool>
    ) -> ZMConversation {
        // We must only ever call this on the sync context. Otherwise, there's a race condition
        // where the UI and sync contexts could both insert the same user (same UUID) and we'd end up
        // having two duplicates of that user, and we'd have a really hard time recovering from that.
        require(context.zm_isSyncContext, "Users are only allowed to be created on sync context")

        let domain: String? = BackendInfo.isFederationEnabled ? domain : nil

        if let conversation = fetch(with: remoteIdentifier, domain: domain, in: context) {
            return conversation
        } else {
            created.pointee = true
            let conversation = ZMConversation.insertNewObject(in: context)
            conversation.remoteIdentifier = remoteIdentifier
            conversation.domain =
                if let domain, !domain.isEmpty {
                    domain
                } else {
                    .none
                }
            return conversation
        }
    }

    /// FOR TESTS ONLY.
    /// To create new conversations see ConversationService.

    @objc(insertGroupConversationIntoManagedObjectContext:withParticipants:)
    public static func insertGroupConversation(
        moc: NSManagedObjectContext,
        participants: [ZMUser]
    ) -> ZMConversation? {
        insertGroupConversation(moc: moc, participants: participants, name: nil)
    }

    /// FOR TESTS ONLY.
    /// To create new conversations see ConversationService.

    @objc
    public static func insertGroupConversation(
        session: ContextProvider,
        participants: [UserType],
        name: String? = nil,
        team: Team? = nil,
        allowGuests: Bool = true,
        allowServices: Bool = true,
        readReceipts: Bool = false,
        participantsRole: Role? = nil
    ) -> ZMConversation? {
        insertGroupConversation(
            moc: session.viewContext,
            participants: participants.materialize(in: session.viewContext),
            name: name,
            team: team,
            allowGuests: allowGuests,
            allowServices: allowServices,
            readReceipts: readReceipts,
            participantsRole: participantsRole
        )
    }

    /// FOR TESTS ONLY.
    /// To create new conversations see ConversationService.

    @objc
    public static func insertGroupConversation(
        moc: NSManagedObjectContext,
        participants: [ZMUser],
        name: String? = nil,
        team: Team? = nil,
        allowGuests: Bool = true,
        allowServices: Bool = true,
        readReceipts: Bool = false,
        participantsRole: Role? = nil
    ) -> ZMConversation? {
        insertConversation(
            moc: moc,
            participants: participants,
            name: name,
            team: team,
            allowGuests: allowGuests,
            allowServices: allowServices,
            readReceipts: readReceipts,
            participantsRole: participantsRole,
            type: .group
        )
    }

    /// FOR TESTS ONLY.
    /// To create new conversations see ConversationService.

    public static func insertConversation(
        moc: NSManagedObjectContext,
        participants: [ZMUser],
        name: String? = nil,
        team: Team? = nil,
        allowGuests: Bool = true,
        allowServices: Bool = true,
        readReceipts: Bool = false,
        participantsRole: Role? = nil,
        type: ZMConversationType,
        messageProtocol: MessageProtocol = .proteus
    ) -> ZMConversation? {
        let selfUser = ZMUser.selfUser(in: moc)

        if team != nil, !selfUser.canCreateConversation(type: type) {
            return nil
        }

        let conversation = ZMConversation.insertNewObject(in: moc)
        conversation.messageProtocol = messageProtocol
        conversation.lastModifiedDate = Date()
        conversation.conversationType = type
        conversation.creator = selfUser
        conversation.team = team
        conversation.userDefinedName = name

        if team != nil {
            conversation.allowGuests = allowGuests
            conversation.allowServices = allowServices
            conversation.hasReadReceiptsEnabled = readReceipts
        }

        let participantsIncludingSelf = Set(participants + [selfUser])

        // Add the new conversation system message
        conversation.appendNewConversationSystemMessage(at: Date(), users: Set(participantsIncludingSelf))

        // Add the participants
        conversation.addParticipantsAndUpdateConversationState(users: participantsIncludingSelf, role: participantsRole)

        // We need to check if we should add a 'secure' system message in case all participants are trusted
        conversation.increaseSecurityLevelIfNeededAfterTrusting(
            clients: Set(participantsIncludingSelf.flatMap(\.clients))
        )

        return conversation
    }
}
