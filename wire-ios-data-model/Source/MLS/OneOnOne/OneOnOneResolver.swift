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
import WireLogging

// sourcery: AutoMockable
public protocol OneOnOneResolverInterface {

    func resolveAllOneOnOneConversations(in context: NSManagedObjectContext) async throws

    @discardableResult
    func resolveOneOnOneConversation(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution

}

private extension WireLogger {
    static let conversationResolver = WireLogger(tag: "conversationResolver")
}

public final class OneOnOneResolver: OneOnOneResolverInterface {

    // MARK: - Dependencies

    private let protocolSelector: OneOnOneProtocolSelectorInterface
    private let migrator: OneOnOneMigratorInterface?
    private let isMLSEnabled: Bool

    // MARK: - Initializer

    public init(
        protocolSelector: OneOnOneProtocolSelectorInterface = OneOnOneProtocolSelector(),
        migrator: OneOnOneMigratorInterface?,
        isMLSEnabled: Bool
    ) {
        self.protocolSelector = protocolSelector
        self.migrator = migrator
        self.isMLSEnabled = isMLSEnabled
    }

    // MARK: - Resolve

    public func resolveAllOneOnOneConversations(in context: NSManagedObjectContext) async throws {
        let usersIDs = try await fetchUserIdsWithOneOnOneConversation(in: context)

        await withTaskGroup(of: Void.self) { group in
            for userID in usersIDs {
                group.addTask {
                    do {
                        try await self.resolveOneOnOneConversation(with: userID, in: context)
                    } catch {
                        // skip conversation migration for this user
                        WireLogger.conversation.error("resolve 1-1 conversation with userID \(userID) failed: \(error)")
                    }
                }
            }
        }
    }

    // Make sure to call after user update event
    @discardableResult
    public func resolveOneOnOneConversation(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution {
        WireLogger.conversation.debug("resolving 1-1 conversation with user: \(userID)")



        // - Maybe multiple 1-1 conversations
        // - User just wants 1
        // - May or may not be the connected conversation
        // - Should not rely on connection

        // Types of conversations:
        // - Pending connection (proteus)
        // - Established connection (proteus)
        // - MLS 1:1
        // - Fake team 1:1 (proteus)
        // - Nothing - just return early



        let messageProtocol = try await protocolSelector.getProtocolForUser(with: userID, in: context)

        switch messageProtocol {
        case .none where isMLSEnabled: // This check is probably not necessary
            return try await resolveCommonUserProtocolNone(with: userID, in: context)
        case .mls where isMLSEnabled:
            return try await resolveCommonUserProtocolMLS(with: userID, in: context)
        case .proteus:
            return try await resolveCommonUserProtocolProteus(with: userID, in: context)
        case .mixed:
            // This should never happen:
            // Users can only support proteus and mls protocols.
            // Mixed protocol is used by conversations to represent
            // the migration state when migrating from proteus to mls.
            assertionFailure("users should not have mixed protocol")
            return .noAction
        default:
            // if mls not enabled, there is nothing to take action
            // fixes locked conversations
            return .noAction
        }
    }

    // MARK: Resolve - None

    private func resolveCommonUserProtocolNone(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution {
        WireLogger.conversation.debug("no common protocols found")

        return try await context.perform {
            guard let user = ZMUser.fetch(with: userID, in: context) else { throw OneOnOneResolverError.userNotFound }

            let selfUser = ZMUser.selfUser(in: context)

            let predicate = NSPredicate.any(of: [
                .mlsOneOnOne(otherUser: user),
                .fakeProteusTeamOneOnOne(selfUser: selfUser, otherUser: user),
                .proteusOneOnOne(otherUser: user),
                .pendingProteusOneOnOne(otherUser: user)
            ])

            let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
            fetchRequest.predicate = predicate

            let conversations = try context.fetch(fetchRequest)
            guard !conversations.isEmpty else { return .noAction }

            let oneOnOneConversation = Self.bestOneOnOneFrom(
                conversations: conversations,
                selfUser: selfUser,
                otherUser: user
            )

            for conversation in conversations where conversation != oneOnOneConversation {
                oneOnOneConversation.mutableMessages.union(conversation.allMessages)
                oneOnOneConversation.needsToBeUpdatedFromBackend = true // Is this necessary?
            }

            user.oneOnOneConversation = oneOnOneConversation


            self.makeConversationReadOnly(
                selfUser: ZMUser.selfUser(in: context),
                otherUser: user,
                conversation: oneOnOneConversation
            )

            return .archivedAsReadOnly
        }
    }

    private func makeConversationReadOnly(
        selfUser: ZMUser,
        otherUser: ZMUser,
        conversation: ZMConversation
    ) {
        if conversation.isForcedReadOnly { return }

        if !selfUser.supportedProtocols.contains(.mls) {
            conversation.appendMLSMigrationMLSNotSupportedForSelfUser(user: selfUser)
        } else if !otherUser.supportedProtocols.contains(.mls) {
            conversation.appendMLSMigrationMLSNotSupportedForOtherUser(user: otherUser)
        }

        conversation.isForcedReadOnly = true
    }

    // MARK: Resolve - MLS

    private func resolveCommonUserProtocolMLS(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution {
        WireLogger.conversation.debug("should resolve to mls 1-1 conversation")

        guard let migrator else {
            throw OneOnOneResolverError.migratorNotFound
        }

        do {
            let mlsGroupID = try await migrator.migrateToMLS(
                userID: userID,
                in: context
            )
            await setReadOnly(to: false, forOneOnOneWithUser: userID, in: context)
            return .migratedToMLSGroup(identifier: mlsGroupID)
        } catch let MigrateMLSOneOnOneConversationError.failedToEstablishGroup(error) {
            await setReadOnly(to: true, forOneOnOneWithUser: userID, in: context)
            throw MigrateMLSOneOnOneConversationError.failedToEstablishGroup(error)
        } catch {
            throw error
        }
    }

    private func setReadOnly(
        to readOnly: Bool,
        forOneOnOneWithUser userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async {
        await context.perform {
            guard
                let otherUser = ZMUser.fetch(with: userID, in: context),
                let conversation = otherUser.oneOnOneConversation, // Check this isn't called until ready
                conversation.isForcedReadOnly != readOnly
            else {
                return
            }

            conversation.isForcedReadOnly = readOnly
        }
    }

    // MARK: Resolve - Proteus

    private func resolveCommonUserProtocolProteus(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution {
        // TODO: Question - Do we need to guard against userID being self user?

        try await context.perform { [context] in
            guard let user = ZMUser.fetch(with: userID, in: context) else {
                throw OneOnOneResolverError.userNotFound
            }

            // 1. Find conversations excluding MLS (fake team 1:1, proteus 1:1, proteus 1:1 pending)

            let selfUser = ZMUser.selfUser(in: context)
            let predicate = NSPredicate.any(of: [
                .fakeProteusTeamOneOnOne(selfUser: selfUser, otherUser: user),
                .proteusOneOnOne(otherUser: user),
                .pendingProteusOneOnOne(otherUser: user)
            ])

            let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
            fetchRequest.predicate = predicate

            let conversations = try context.fetch(fetchRequest)
            if !conversations.isEmpty {

                // 2. Pick the best conversation

                let oneOnOneConversation = Self.bestOneOnOneFrom(
                    conversations: conversations,
                    selfUser: selfUser,
                    otherUser: user
                )

                // 3. Move messages into picked conversation

                for conversation in conversations where conversation != oneOnOneConversation {
                    oneOnOneConversation.mutableMessages.union(conversation.allMessages)
                    oneOnOneConversation.needsToBeUpdatedFromBackend = true // Is this necessary?
                }

                // 4. Assign the conversation to the user

                user.oneOnOneConversation = oneOnOneConversation
            }
        }

        WireLogger.conversation.debug("should resolve to proteus 1-1 conversation")
        await setReadOnly(to: false, forOneOnOneWithUser: userID, in: context)
        return .noAction
    }

    // MARK: - Helpers

    private static func bestOneOnOneFrom(
        conversations: [ZMConversation],
        selfUser: ZMUser,
        otherUser: ZMUser
    ) -> ZMConversation {
        var mls: [ZMConversation] = []
        var fakeProteusTeam: [ZMConversation] = []
        var proteusOnOnOne: [ZMConversation] = []
        var pendingProteusOneOnOne: [ZMConversation] = []

        for conversation in conversations {
            if NSPredicate.mlsOneOnOne(otherUser: otherUser).evaluate(with: conversation) {
                mls.append(conversation)
            } else if NSPredicate.fakeProteusTeamOneOnOne(selfUser: selfUser, otherUser: otherUser).evaluate(with: conversation) {
                fakeProteusTeam.append(conversation)
            } else if NSPredicate.proteusOneOnOne(otherUser: otherUser).evaluate(with: conversation) {
                proteusOnOnOne.append(conversation)
            } else if NSPredicate.pendingProteusOneOnOne(otherUser: otherUser).evaluate(with: conversation) {
                pendingProteusOneOnOne.append(conversation)
            }
        }

        return bestOneOnOneFrom(
            mls: mls,
            fakeProteusTeam: fakeProteusTeam,
            proteusOnOnOne: proteusOnOnOne,
            pendingProteusOneOnOne: pendingProteusOneOnOne
        )
    }

    private static func bestOneOnOneFrom(
        mls: [ZMConversation],
        fakeProteusTeam: [ZMConversation],
        proteusOnOnOne: [ZMConversation],
        pendingProteusOneOnOne: [ZMConversation]
    ) -> ZMConversation {
        if mls.count > 0 {
            return mls[0]
        } else if fakeProteusTeam.count > 0 {
            return fakeProteusTeam[0]
        } else if proteusOnOnOne.count > 0 {
            return proteusOnOnOne.sorted { $0.primaryKey < $1.primaryKey }[0]
        } else if pendingProteusOneOnOne.count > 0 {
            return pendingProteusOneOnOne[0]
        } else {
            fatalError("No 1-1 conversation found")
        }
    }

    private func fetchUserIdsWithOneOnOneConversation(in context: NSManagedObjectContext) async throws
        -> [QualifiedID] {
        try await context.perform {
            let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
            // Fetch all users that are not self
            request.predicate = ZMUser.predicateForUsersWithOneOnOneConversation()

            return try context
                .fetch(request)
                .compactMap { user in
                    guard let userID = user.qualifiedID else {
                        WireLogger.conversation.error("missing user's qualifiedID to resolve 1-1 conversation!")
                        return nil
                    }
                    return userID
                }
        }
    }
}

private extension NSPredicate {

    // TODO: OPTIMIZATION:
    // As far as I know it is better to run one fetch for a 1000 items then 1000 fetches for one item. E.g. we should
    // limit fetches. Therefore, wouldn't it be better to modify our predicates to remove the user constraint, fetch all
    // conversations that match the updated predicates then loop over the result and put into some data structure with
    // fast access by user id. We could do this once in `resolveAllOneOnOneConversations` and pass this data structure
    // through to it's sub calls.

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

    static let hasTwoParticipants = NSPredicate(format: "%K.@count == 2", ZMConversationParticipantRolesKey)

    static func hasParticipant(user: ZMUser) -> NSPredicate {
        NSPredicate(format: "ANY %K.user == %@", ZMConversationParticipantRolesKey, user)
    }

}
