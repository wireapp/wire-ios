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
public protocol OneOnOneMigratorInterface {

    @discardableResult
    func migrateToMLS(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> MLSGroupID

}

public enum MigrateMLSOneOnOneConversationError: Error {

    case failedToFetchConversation(Error)
    case failedToEstablishGroup(Error)
    case failedToActivateConversation

}

public final class OneOnOneMigrator: OneOnOneMigratorInterface {

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

        try await establishLocalMLSConversationIfNeeded(
            userID: userID,
            mlsGroupID: mlsGroupID
        )

        try await switchLocalConversationToMLS(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: context
        )

        return mlsGroupID
    }

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

    private func establishLocalMLSConversationIfNeeded(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID
    ) async throws {
        guard await !mlsService.conversationExists(groupID: mlsGroupID) else {
            return
        }

        do {
            try await mlsService.createGroup(
                for: mlsGroupID,
                with: [MLSUser(userID)]
            )
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

            guard
                let otherUser = ZMUser.fetch(with: userID, in: context),
                let connection = otherUser.connection
            else {
                throw MigrateMLSOneOnOneConversationError.failedToActivateConversation
            }

            // copy local messages
            if let proteusConversation = connection.conversation {
                mlsConversation.mutableMessages.union(proteusConversation.allMessages)
                // update just to be sure
                mlsConversation.needsToBeUpdatedFromBackend = true
            }

            // switch active conversation
            connection.conversation = mlsConversation

            context.saveOrRollback()
        }
    }
}
