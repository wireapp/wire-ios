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
    private let migrator: OneOnOneMigratorInterface?

    // MARK: - Life cycle

    public convenience init(syncContext: NSManagedObjectContext) {
        let mlsService = syncContext.performAndWait {
            syncContext.mlsService
        }

        self.init(migrator: mlsService.map(OneOnOneMigrator.init))
    }

    public convenience init(mlsService: MLSServiceInterface) {
        self.init(migrator: OneOnOneMigrator(mlsService: mlsService))
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

        let messageProtocol = try await protocolSelector.getProtocolForUser(
            with: userID,
            in: context
        )

        switch messageProtocol {
        case .none:
            WireLogger.conversation.debug("no common protocols found")
            await context.perform {
                guard
                    let otherUser = ZMUser.fetch(with: userID, in: context),
                    let conversation = otherUser.oneOnOneConversation
                else {
                    return
                }

                let selfUser = ZMUser.selfUser(in: context)

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

        case .mls:
            WireLogger.conversation.debug("should resolve to mls 1-1 conversation")

            guard let migrator else {
                throw OneOnOneResolverError.migratorNotFound
            }

            let mlsGroupIdentifier = try await migrator.migrateToMLS(
                userID: userID,
                in: context
            )

            return .migratedToMLSGroup(identifier: mlsGroupIdentifier)

        case .proteus:
            WireLogger.conversation.debug("should resolve to proteus 1-1 conversation")
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
