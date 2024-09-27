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

// MARK: - OneOnOneMigratorInterface

// sourcery: AutoMockable
public protocol OneOnOneMigratorInterface {
    @discardableResult
    func migrateToMLS(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> MLSGroupID
}

// MARK: - OneOnOneMigrator

public struct OneOnOneMigrator: OneOnOneMigratorInterface {
    // MARK: - Dependencies

    private let mlsService: MLSServiceInterface

    // MARK: - Life cycle

    public init(mlsService: MLSServiceInterface) {
        self.mlsService = mlsService
    }

    // MARK: - Methods

    @discardableResult
    public func migrateToMLS(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> MLSGroupID {
        let mlsGroupID = try await syncMLSConversationFromBackend(
            userID: userID,
            in: context
        )

        if try await mlsService.conversationExists(groupID: mlsGroupID) {
            return mlsGroupID
        }

        guard let epoch = await fetchMLSConversationEpoch(mlsGroupID: mlsGroupID, in: context) else {
            throw MigrateMLSOneOnOneConversationError.missingConversationEpoch
        }

        if epoch == 0 {
            try await establishMLSGroupIfNeeded(
                userID: userID,
                mlsGroupID: mlsGroupID,
                in: context
            )
        } else {
            try await mlsService.joinGroup(with: mlsGroupID)
        }

        try await switchLocalConversationToMLS(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: context
        )

        await context.perform {
            _ = context.saveOrRollback()
        }

        return mlsGroupID
    }

    // MARK: Helpers

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

    private func fetchMLSConversationEpoch(
        mlsGroupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) async -> UInt64? {
        await context.perform {
            let conversation = ZMConversation.fetch(with: mlsGroupID, in: context)
            return conversation?.epoch
        }
    }

    private func establishMLSGroupIfNeeded(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) async throws {
        let users = [MLSUser(userID)]

        do {
            let ciphersuite = try await mlsService.establishGroup(for: mlsGroupID, with: users)
            await context.perform {
                let conversation = ZMConversation.fetch(with: mlsGroupID, in: context)
                conversation?.ciphersuite = ciphersuite
                conversation?.mlsStatus = .ready
            }
        } catch {
            throw MigrateMLSOneOnOneConversationError.failedToEstablishGroup(error)
        }
    }

    private func switchLocalConversationToMLS(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) async throws {
        try await context.perform {
            guard let mlsConversation = ZMConversation.fetch(
                with: mlsGroupID,
                in: context
            ) else {
                throw MigrateMLSOneOnOneConversationError.failedToActivateConversation
            }

            guard let otherUser = ZMUser.fetch(with: userID, in: context) else {
                throw MigrateMLSOneOnOneConversationError.failedToActivateConversation
            }

            // move local messages from proteus conversation if it exists
            if let proteusConversation = otherUser.oneOnOneConversation {
                // Since ZMMessages only have a single conversation connected,
                // forming this union also removes the relationship to the proteus conversation.
                mlsConversation.mutableMessages.union(proteusConversation.allMessages)

                // update just to be sure
                mlsConversation.needsToBeUpdatedFromBackend = true
            }

            // switch active conversation
            otherUser.oneOnOneConversation = mlsConversation
        }
    }
}
