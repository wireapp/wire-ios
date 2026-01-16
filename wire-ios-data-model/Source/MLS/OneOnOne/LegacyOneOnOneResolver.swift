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

public final class LegacyOneOnOneResolver: OneOnOneResolverInterface {

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
                        switch error {
                        case MigrateMLSOneOnOneConversationError.alreadyMigrated:
                            WireLogger.conversation.warn(
                                "Skipping conversation migration: the 1-1 conversation for this user is already migrated.",
                                attributes: [.senderUserId: userID.safeForLoggingDescription]
                            )
                        default:
                            WireLogger.conversation.error(
                                "resolve 1-1 conversation failed: \(error)",
                                attributes: [.senderUserId: userID.safeForLoggingDescription]
                            )
                        }
                    }
                }
            }
        }
    }

    @discardableResult
    public func resolveOneOnOneConversation(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution {
        WireLogger.conversation.debug(
            "resolving 1-1 conversation",
            attributes: [.senderUserId: userID.safeForLoggingDescription]
        )

        let messageProtocol = try await protocolSelector.getProtocolForUser(with: userID, in: context)

        let action: OneOnOneConversationResolution
        switch messageProtocol {
        case .none where isMLSEnabled:
            action = try await resolveCommonUserProtocolNone(with: userID, in: context)
        case .mls where isMLSEnabled:
            action = try await resolveCommonUserProtocolMLS(with: userID, in: context)
        case .proteus:
            action = try await resolveCommonUserProtocolProteus(with: userID, in: context)
        case .mixed:
            // This should never happen:
            // Users can only support proteus and mls protocols.
            // Mixed protocol is used by conversations to represent
            // the migration state when migrating from proteus to mls.
            assertionFailure("users should not have mixed protocol")
            action = .noAction
        default:
            // if mls not enabled, there is nothing to take action
            // fixes locked conversations
            action = .noAction
        }

        try await context.perform {
            try context.save()
        }

        return action
    }

    // MARK: Resolve - None

    private func resolveCommonUserProtocolNone(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution {
        WireLogger.conversation.debug(
            "no common protocols found",
            attributes: [.senderUserId: userID.safeForLoggingDescription]
        )

        return try await context.perform {
            guard let user = ZMUser.fetch(with: userID, in: context) else { throw OneOnOneResolverError.userNotFound }

            let source = OneOnOneSource(context: context)
            guard let conversations = try source.fetchOneOnOnesWithCandidate(
                user: user,
                types: [.mls, .fake, .proteus, .proteusPending]
            ) else {
                return .noAction
            }

            let best = conversations.candidate
            for conversation in conversations.others {
                best.migrateMessages(from: conversation)
                best.needsToBeUpdatedFromBackend = true
            }

            user.oneOnOneConversation = best

            self.makeConversationReadOnly(
                selfUser: ZMUser.selfUser(in: context),
                otherUser: user,
                conversation: best
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
        WireLogger.conversation.debug(
            "should resolve to mls 1-1 conversation",
            attributes: [.senderUserId: userID.safeForLoggingDescription]
        )

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
                let conversation = otherUser.oneOnOneConversation,
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
        try await context.perform { [context] in
            guard let user = ZMUser.fetch(with: userID, in: context) else {
                throw OneOnOneResolverError.userNotFound
            }

            let source = OneOnOneSource(context: context)
            if let conversations = try source.fetchOneOnOnesWithCandidate(
                user: user,
                types: [.fake, .proteus, .proteusPending]
            ) {
                let best = conversations.candidate
                for conversation in conversations.others {
                    best.mutableMessages.union(conversation.allMessages)
                    best.needsToBeUpdatedFromBackend = true
                }

                user.oneOnOneConversation = best
            }
        }

        WireLogger.conversation.debug(
            "should resolve to proteus 1-1 conversation",
            attributes: [.senderUserId: userID.safeForLoggingDescription]
        )
        await setReadOnly(to: false, forOneOnOneWithUser: userID, in: context)
        return .noAction
    }

    // MARK: - Helpers

    private func fetchUserIdsWithOneOnOneConversation(in context: NSManagedObjectContext) async throws
        -> [QualifiedID] {
        try await context.perform {
            let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
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
