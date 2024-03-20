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
        mlsGroupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) async throws

}

public struct OneOnOneMigrator: OneOnOneMigratorInterface {

    // MARK: - Dependencies

    private let mlsService: MLSServiceInterface

    // MARK: - Life cycle

    public init(mlsService: MLSServiceInterface) {
        self.mlsService = mlsService
    }

    // MARK: - Methods

    public func migrateToMLS(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) async throws {
        try await establishLocalMLSConversationIfNeeded(
            userID: userID,
            mlsGroupID: mlsGroupID
        )

        try await switchLocalConversationToMLS(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: context
        )
    }

    private func establishLocalMLSConversationIfNeeded(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID
    ) async throws {
        let users = [MLSUser(userID)]

        do {
            try await mlsService.establishGroup(for: mlsGroupID, with: users)
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

            // move local messages
            if let proteusConversation = otherUser.oneOnOneConversation {
                // Since ZMMessages only have a single conversation connected,
                // forming this union also removes the relationship to the proteus conversation.
                mlsConversation.mutableMessages.union(proteusConversation.allMessages)

                // update just to be sure
                mlsConversation.needsToBeUpdatedFromBackend = true
            }

            // switch active conversation
            otherUser.oneOnOneConversation = mlsConversation

            context.saveOrRollback()
        }
    }
}
