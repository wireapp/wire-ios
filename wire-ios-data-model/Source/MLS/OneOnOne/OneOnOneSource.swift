//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class OneOnOneSource {

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
        let predicate = NSPredicate.all(
            of: types.map { Self.predicate(type: $0, selfUser: selfUser, otherUser: user) }
        )

        let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "primaryKey", ascending: true)]

        let conversations = try context.fetch(fetchRequest)
        guard !conversations.isEmpty else { return nil }

        var conversationsByType: [OneOnOneType: [ZMConversation]] = [:]
        for conversation in conversations {
            let type = Self.oneOnOneType(for: conversation, selfUser: user, otherUser: user)
            conversationsByType[type, default: []].append(conversation)
        }

        var candidate: ZMConversation?
        for type in types {
            if let conversation = conversationsByType[type]?.first {
                candidate = conversation
                break
            }
        }

        guard let candidate = candidate else { fatalError("No candidate found") }

        return Result(
            candidate: candidate,
            others: conversations.filter { $0 != candidate }
        )
    }

    func fetchOneOnOnes(user: ZMUser, types: [OneOnOneType]) throws -> [ZMConversation] {
        let selfUser = ZMUser.selfUser(in: context)
        let predicate = NSPredicate.all(
            of: types.map { Self.predicate(type: $0, selfUser: user, otherUser: user) }
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

    private static func oneOnOneType(
        for conversation: ZMConversation,
        selfUser: ZMUser,
        otherUser: ZMUser
    ) -> OneOnOneType {
        if NSPredicate.mlsOneOnOne(otherUser: otherUser).evaluate(with: conversation) {
            return .mls
        } else if NSPredicate.fakeProteusTeamOneOnOne(selfUser: selfUser, otherUser: otherUser).evaluate(with: conversation) {
            return .fake
        } else if NSPredicate.proteusOneOnOne(otherUser: otherUser).evaluate(with: conversation) {
            return .proteus
        } else if NSPredicate.pendingProteusOneOnOne(otherUser: otherUser).evaluate(with: conversation) {
            return .proteusPending
        }
        fatalError("OneOnOneType")
    }
}

private extension NSPredicate {

    static func mlsOneOnOne(otherUser: ZMUser) -> NSPredicate {
        let isOneOnOne = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)")
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
        let isOneOnOne = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)")
        let isProteus = NSPredicate(format: "\(ZMConversation.messageProtocolKey) == \(MessageProtocol.proteus.int16Value)")

        return .all(of: [
            isOneOnOne,
            isProteus,
            hasTwoParticipants,
            hasParticipant(user: otherUser)
        ])
    }

    static func pendingProteusOneOnOne(otherUser: ZMUser) -> NSPredicate {
        let isConnection = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue)")
        let isProteus = NSPredicate(format: "\(ZMConversation.messageProtocolKey) == \(MessageProtocol.proteus.int16Value)")

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
