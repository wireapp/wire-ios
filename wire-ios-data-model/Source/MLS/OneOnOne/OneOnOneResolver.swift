//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

// sourcery: AutoMockable
public protocol OneOnOneResolverInterface {

    func resolveAllOneOnOneConversations(in context: NSManagedObjectContext) async throws

    @discardableResult
    func resolveOneOnOneConversation(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution

}

enum OneOnOneResolverError: Error {

    case migratorNotFound

}

public final class OneOnOneResolver: OneOnOneResolverInterface {

    // MARK: - Dependencies

    private let protocolSelector: OneOnOneProtocolSelectorInterface
    private let mlsService: MLSServiceInterface?
    private let migrator: OneOnOneMigratorInterface?

    // MARK: - Life cycle

    public convenience init(syncContext: NSManagedObjectContext) {
        let mlsService = syncContext.performAndWait {
            syncContext.mlsService
        }

        self.init(
            mlsService: mlsService,
            migrator: mlsService.map(OneOnOneMigrator.init)
        )
    }

    public convenience init(mlsService: MLSServiceInterface) {
        self.init(
            mlsService: mlsService,
            migrator: OneOnOneMigrator(mlsService: mlsService)
        )
    }

    public init(
        protocolSelector: OneOnOneProtocolSelectorInterface = OneOnOneProtocolSelector(),
        mlsService: MLSServiceInterface?,
        migrator: OneOnOneMigratorInterface?
    ) {
        self.protocolSelector = protocolSelector
        self.mlsService = mlsService
        self.migrator = migrator
    }

    // MARK: - Methods

    public func resolveAllOneOnOneConversations(in context: NSManagedObjectContext) async throws {
        let usersIDs = try await fetchUserIdsWithOneOnOneConversation(in: context)

        await withTaskGroup(of: Void.self) { group in
            for userID in usersIDs {
                group.addTask {
                    do {
                        try await self.resolveOneOnOneConversation(with: userID, in: context)
                    } catch {
                        // skip conversation migration for this user
                        WireLogger.conversation.error("resolve 1-1 conversation with userID \(userID) failed!")
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
        WireLogger.conversation.debug("resolving 1-1 conversation with user: \(userID)")

        let messageProtocol = try await protocolSelector.getProtocolForUser(with: userID, in: context)

        switch messageProtocol {
        case .none:
            return await resolveCommonUserProtocolNone(with: userID, in: context)
        case .mls:
            return try await resolveCommonUserProtocolMLS(with: userID, in: context)
        case .proteus:
            return resolveCommonUserProtocolProteus()
        case .mixed:
            return resolveCommonUserProtocolMixed()
        }
    }

    private func resolveCommonUserProtocolNone(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async -> OneOnOneConversationResolution {
        WireLogger.conversation.debug("no common protocols found")

        await context.perform {
            guard
                let otherUser = ZMUser.fetch(with: userID, in: context),
                let conversation = otherUser.oneOnOneConversation
            else {
                return
            }

            let selfUser = ZMUser.selfUser(in: context)

            // The reason we need to add this first if check here is so to avoid running the same code path again
            // if conversation has been marked as read only before.
            if !conversation.isForcedReadOnly {
                if !selfUser.supportedProtocols.contains(.mls) {
                    conversation.appendMLSMigrationMLSNotSupportedForSelfUser(user: selfUser)
                } else if !otherUser.supportedProtocols.contains(.mls) {
                    conversation.appendMLSMigrationMLSNotSupportedForOtherUser(user: otherUser)
                }
            }

            conversation.isForcedReadOnly = true
        }

        return .archivedAsReadOnly
    }

    private func resolveCommonUserProtocolMLS(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution {
        //        let conversationMessageProtocol: MessageProtocol? = await context.perform {
        //            guard
        //                let otherUser = ZMUser.fetch(with: userID, in: context),
        //                let conversation = otherUser.oneOnOneConversation
        //            else {
        //                return nil
        //            }
        //
        //            return conversation.messageProtocol
        //        }
        //
        //        guard case .proteus = conversationMessageProtocol else {
        //            // Only proteus conversations should be migrated once
        //            return .noAction
        //        }

        WireLogger.conversation.debug("should resolve to mls 1-1 conversation")

        guard let mlsService, let migrator else {
            throw OneOnOneResolverError.migratorNotFound
        }

        let mlsGroupID = try await syncMLSConversationFromBackend(
            userID: userID,
            in: context
        )

        if await mlsService.conversationExists(groupID: mlsGroupID) {
            return .noAction
        }

        // if epoch = 0

        try await migrator.migrateToMLS(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: context
        )

        // else

        // join via external commit
        // try await mlsService.joinGroup(with: mlsGroupID)

        return .migratedToMLSGroup(identifier: mlsGroupID)
    }

    private func resolveCommonUserProtocolProteus() -> OneOnOneConversationResolution {
        WireLogger.conversation.debug("should resolve to proteus 1-1 conversation")
        return .noAction
    }

    private func resolveCommonUserProtocolMixed() -> OneOnOneConversationResolution {
        // This should never happen:
        // Users can only support proteus and mls protocols.
        // Mixed protocol is used by conversations to represent
        // the migration state when migrating from proteus to mls.
        assertionFailure("users should not have mixed protocol")
        return .noAction
    }

    // MARK: Sync

    private func syncMLSConversationFromBackend(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> MLSGroupID {
        var action = SyncMLSOneToOneConversationAction(
            userID: userID.uuid,
            domain: userID.domain
        )

        do {
            return try await action.perform(in: context.notificationContext)
        } catch {
            throw MigrateMLSOneOnOneConversationError.failedToFetchConversation(error)
        }
    }

    // MARK: Helpers

    private func fetchUserIdsWithOneOnOneConversation(in context: NSManagedObjectContext) async throws -> [QualifiedID] {
        try await context.perform {
            let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
            request.predicate = ZMUser.predicateForUsersWithOneOnOneConversation()

            return try context
                .fetch(request)
                .compactMap { user in
                    guard let userID = user.qualifiedID else {
                        WireLogger.conversation.error("required to have a user's qualifiedID to resolve 1-1 conversation!")
                        return nil
                    }
                    return userID
                }
        }
    }
}
