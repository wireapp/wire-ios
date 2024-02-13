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

public enum OneOnOneResolverError: Error {

    case migratorNotFound

}

public final class OneOnOneResolver: OneOnOneResolverInterface {

    // MARK: - Dependencies

    private let protocolSelector: OneOnOneProtocolSelectorInterface
    private let migrator: OneOnOneMigratorInterface?

    // MARK: - Life cycle

    public convenience init(syncContext: NSManagedObjectContext) {
        let mlsService = syncContext.performAndWait {
            syncContext.mlsService
        }

        self.init(migrator: mlsService.map(OneOnOneMigrator.init))
    }

    public init(
        protocolSelector: OneOnOneProtocolSelectorInterface = OneOnOneProtocolSelector(),
        migrator: OneOnOneMigratorInterface? = nil
    ) {
        self.protocolSelector = protocolSelector
        self.migrator = migrator
    }

    // MARK: - Methods

    public func resolveAllOneOnOneConversations(in context: NSManagedObjectContext) async throws {
        // TODO: [WPB-5812] implement

        let users: [ZMUser] = try await context.perform {
            let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
            request.predicate = NSPredicate(format: "oneOnOneConversation != nil")
            return try context.fetch(request)
        }

        for user in users {
            try await resolveOneOnOneConversation(with: user, in: context)
        }
    }

    @discardableResult
    public func resolveOneOnOneConversation(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution {
        guard let otherUser = await context.perform({ ZMUser.fetch(with: userID, in: context) }) else {
            // TODO: [WPB-5812] throw error? was ignored before
            return .noAction
        }

        return try await resolveOneOnOneConversation(with: otherUser, in: context)
    }

    @discardableResult
    func resolveOneOnOneConversation(
        with otherUser: ZMUser,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution {
        WireLogger.conversation.debug("resolving one on one with user: \(String(describing: otherUser.remoteIdentifier)) on domain: \(String(describing: otherUser.domain))")

        let selfUser = await context.perform { ZMUser(context: context) }

        let messageProtocol = await protocolSelector.getProtocolInsersectionBetween(
            selfUser: selfUser,
            otherUser: otherUser,
            in: context
        )

        switch messageProtocol {
        case .none:
            WireLogger.conversation.debug("no common protocols found")
            await context.perform {
                otherUser.oneOnOneConversation?.isForcedReadOnly = true
            }
            return .archivedAsReadOnly

        case .mls:
            WireLogger.conversation.debug("should resolve to mls one on one")

            guard let migrator else {
                throw OneOnOneResolverError.migratorNotFound
            }

            let mlsGroupIdentifier = try await migrator.migrateToMLS(
                user: otherUser,
                in: context
            )

            return .migratedToMLSGroup(identifier: mlsGroupIdentifier)

        case .proteus:
            WireLogger.conversation.debug("should resolve to proteus one on one")
            return .noAction

        // This should never happen:
        // Users can only support proteus and mls protocols.
        // Mixed protocol is used by conversations to represent
        // the migration state when migrating from proteus to mls.
        case .mixed:
            assertionFailure("users should not have mixed protocol")
            return .noAction
        }
    }

}
