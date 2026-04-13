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

enum OneOnOneType: Hashable {
    case mls
    case fake
    case proteus
    case proteusPending
}

public final class OneOnOneSource {

    struct Result {
        let candidate: ZMConversation
        let others: [ZMConversation]
    }

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Fetches all one-on-one conversations for `user` which match one of the given `types`.
    ///
    /// The result includes the best candidate conversation. This is determined by the order of the given types and the
    /// `primaryKeys` of the conversations.
    ///
    /// - warning: This method must be called within a `NSManagedObjectContext.perform` block.

    func fetchOneOnOnesWithCandidate(user: ZMUser, types: [OneOnOneType]) throws -> Result? {
        let selfUser = ZMUser.selfUser(in: context)

        var candidate: ZMConversation?
        var allConversations: [ZMConversation] = []
        for type in types {
            let conversations = try sortedConversations(type: type, selfUser: selfUser, otherUser: user)
            if candidate == nil {
                candidate = conversations.first
            }

            allConversations.append(contentsOf: conversations)
        }

        guard let candidate else { return nil }

        return Result(
            candidate: candidate,
            others: allConversations.filter { $0 != candidate }
        )
    }

    /// Fetches all one-on-one conversations for `user` which match one of the given `types`.
    ///
    /// - warning: This method must be called within a `NSManagedObjectContext.perform` block.

    func fetchOneOnOnes(user: ZMUser, types: [OneOnOneType]) throws -> [ZMConversation] {
        let selfUser = ZMUser.selfUser(in: context)
        let predicate = NSPredicate.any(
            of: types.map { Self.predicate(type: $0, selfUser: selfUser, otherUser: user) }
        )

        let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        fetchRequest.predicate = predicate

        return try context.fetch(fetchRequest)
    }

    // MARK: - Private

    private static func predicate(type: OneOnOneType, selfUser: ZMUser, otherUser: ZMUser) -> NSPredicate {
        switch type {
        case .mls:
            .mlsOneOnOne(otherUser: otherUser)
        case .fake:
            .fakeProteusTeamOneOnOne(selfUser: selfUser, otherUser: otherUser)
        case .proteus:
            .proteusOneOnOne(otherUser: otherUser)
        case .proteusPending:
            .pendingProteusOneOnOne(otherUser: otherUser)
        }
    }

    private func sortedConversations(
        type: OneOnOneType,
        selfUser: ZMUser,
        otherUser: ZMUser
    ) throws -> [ZMConversation] {
        let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        fetchRequest.predicate = Self.predicate(type: type, selfUser: selfUser, otherUser: otherUser)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "primaryKey", ascending: true)]

        return try context.fetch(fetchRequest)
    }

    public static func migrate(
        toMLSConversation mlsConversation: ZMConversation,
        for otherUser: ZMUser,
        in context: NSManagedObjectContext
    ) throws {

        // Note on proteus, it's possible to have duplicate 1-1 conversations, so we need to fetch all relevant
        // 1-1 conversations here.
        let source = OneOnOneSource(context: context)
        var proteusConversations: [ZMConversation] = []
        // NOTE: querying for all types at once triggers a table scan which is very expensive
        for type in [OneOnOneType.fake, OneOnOneType.proteus, OneOnOneType.proteusPending] {
            let conversations = try source.fetchOneOnOnes(
                user: otherUser,
                types: [type]
            )
            proteusConversations.append(contentsOf: conversations)
        }

        // Move local messages from all proteus conversations
        for proteusConversation in proteusConversations {
            // Since ZMMessages only have a single conversation connected,
            // forming this union also removes the relationship to the proteus conversation.
            mlsConversation.migrateMessages(from: proteusConversation)
        }

        if !proteusConversations.isEmpty {
            // insert system message that we moved from proteus to MLS
            let sender = ZMUser.selfUser(in: context)
            mlsConversation.appendMLSMigrationFinalizedSystemMessageIfNeeded(sender: sender, at: .now)

            // update just to be sure
            mlsConversation.needsToBeUpdatedFromBackend = true
        }
        // switch active conversation
        otherUser.oneOnOneConversation = mlsConversation

        mlsConversation.migratedToMLS = true
    }
}

private extension NSPredicate {

    static func mlsOneOnOne(otherUser: ZMUser) -> NSPredicate {
        let isOneOnOne =
            NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)")
        let isMLS = NSPredicate(format: "\(ZMConversation.messageProtocolKey) == \(MessageProtocol.mls.int16Value)")

        return .all(of: [
            isOneOnOne,
            isMLS,
            hasTwoParticipants,
            hasParticipant(user: otherUser)
        ])
    }

    static func fakeProteusTeamOneOnOne(selfUser: ZMUser, otherUser: ZMUser) -> NSPredicate {
        guard let selfTeam = selfUser.team, selfUser != otherUser else {
            return NSPredicate(value: false)
        }

        let sameTeam = NSPredicate(format: "team == %@", selfTeam)
        let groupConversation = NSPredicate(
            format: "%K == %d",
            ZMConversationConversationTypeKey,
            ZMConversationType.group.rawValue
        )
        let noUserDefinedName = NSPredicate(format: "%K == NULL", ZMConversationUserDefinedNameKey)

        return .all(of: [
            sameTeam,
            groupConversation,
            noUserDefinedName,
            hasTwoParticipants,
            hasParticipant(user: selfUser),
            hasParticipant(user: otherUser)
        ])
    }

    static func proteusOneOnOne(otherUser: ZMUser) -> NSPredicate {
        let isOneOnOne =
            NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)")
        let isProteus =
            NSPredicate(format: "\(ZMConversation.messageProtocolKey) == \(MessageProtocol.proteus.int16Value)")

        return .all(of: [
            isOneOnOne,
            isProteus,
            hasTwoParticipants,
            hasParticipant(user: otherUser)
        ])
    }

    static func pendingProteusOneOnOne(otherUser: ZMUser) -> NSPredicate {
        let isConnection =
            NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue)")
        let isProteus =
            NSPredicate(format: "\(ZMConversation.messageProtocolKey) == \(MessageProtocol.proteus.int16Value)")

        return .all(of: [
            isConnection,
            isProteus,
            hasParticipant(user: otherUser)
        ])
    }

    // MARK: - Helpers

    private static let hasTwoParticipants = NSPredicate(format: "%K.@count == 2", ZMConversationParticipantRolesKey)

    private static func hasParticipant(user: ZMUser) -> NSPredicate {
        NSPredicate(format: "ANY %K.user == %@", ZMConversationParticipantRolesKey, user)
    }

}
