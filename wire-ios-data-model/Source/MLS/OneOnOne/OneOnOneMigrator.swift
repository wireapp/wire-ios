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

    func migrateToMLS(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws

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

    public func migrateToMLS(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws {
        let mlsGroupID = try await fetchMLSOneOnOneConversation(
            userID: userID,
            in: context
        )

        try await establishMLSGroupIfNeeded(
            userID: userID,
            mlsGroupID: mlsGroupID
        )

        try await context.perform {
            guard let mlsConversation = ZMConversation.fetch(
                with: mlsGroupID,
                in: context
            ) else {
                throw MigrateMLSOneOnOneConversationError.failedToActivateConversation
            }

            try self.switchActiveOneOnOneConversation(
                userID: userID,
                conversation: mlsConversation,
                in: context
            )

            context.saveOrRollback()
        }
    }

    private func fetchMLSOneOnOneConversation(
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

    private func establishMLSGroupIfNeeded(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID
    ) async throws {
        guard !mlsService.conversationExists(groupID: mlsGroupID) else {
            return
        }

        do {
            try mlsService.createGroup(for: mlsGroupID)
            try await mlsService.addMembersToConversation(
                with: [MLSUser(userID)],
                for: mlsGroupID
            )
        } catch {
            throw MigrateMLSOneOnOneConversationError.failedToEstablishGroup(error)
        }
    }

    private func switchActiveOneOnOneConversation(
        userID: QualifiedID,
        conversation: ZMConversation,
        in context: NSManagedObjectContext
    ) throws {
        guard
            let otherUser = ZMUser.fetch(with: userID, in: context),
            let connection = otherUser.connection
        else {
            throw MigrateMLSOneOnOneConversationError.failedToActivateConversation
        }

        // TODO: This only works for one on ones with people outside your team.
        // MLS one on ones with people from your team are now real one on ones
        // (as opposed to fake one on ones with proteus), but there is no connection
        // between you and your team member. So how do we make the new mls one on one
        // the active conversation?

        // Android solves this by having an `activeOneOnOne` field on the their
        // user object. We could do the same, adding a one to one opitonal relationship
        // between ZMUser and ZMConversation, which could be used either for just team
        // one on ones, or all one on ones. 

        // If we do that, we would need to migrate all ZMConnection.conversation values
        // to ZMUser.oneOnOneConversation. Then we could remove `ZMConnection.conversation`
        // completely (I think) and use ZMUser.OneOnOneConversation instead.

        connection.conversation = conversation
    }

}
