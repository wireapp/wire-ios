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

// MARK: - OneOnOneResolverInterface

// sourcery: AutoMockable
public protocol OneOnOneResolverInterface {
    func resolveAllOneOnOneConversations(in context: NSManagedObjectContext) async throws

    @discardableResult
    func resolveOneOnOneConversation(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> OneOnOneConversationResolution
}

// MARK: - OneOnOneResolver

public final class OneOnOneResolver: OneOnOneResolverInterface {
    // MARK: Lifecycle

    // MARK: - Initializer

    public init(
        protocolSelector: OneOnOneProtocolSelectorInterface = OneOnOneProtocolSelector(),
        migrator: OneOnOneMigratorInterface?
    ) {
        self.protocolSelector = protocolSelector
        self.migrator = migrator
    }

    // MARK: Public

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

        let mlsEnabled = DeveloperFlag.enableMLSSupport.isOn

        switch messageProtocol {
        case .none where mlsEnabled:
            return await resolveCommonUserProtocolNone(with: userID, in: context)

        case .mls where mlsEnabled:
            return try await resolveCommonUserProtocolMLS(with: userID, in: context)

        case .proteus:
            return await resolveCommonUserProtocolProteus(with: userID, in: context)

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

    // MARK: Private

    // MARK: - Dependencies

    private let protocolSelector: OneOnOneProtocolSelectorInterface
    private let migrator: OneOnOneMigratorInterface?

    // MARK: Resolve - None

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

            self.makeConversationReadOnly(
                selfUser: ZMUser.selfUser(in: context),
                otherUser: otherUser,
                conversation: conversation
            )
        }

        return .archivedAsReadOnly
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
    ) async -> OneOnOneConversationResolution {
        WireLogger.conversation.debug("should resolve to proteus 1-1 conversation")
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
