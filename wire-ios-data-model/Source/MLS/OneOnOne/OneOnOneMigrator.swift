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
        let mlsGroupID = try await fetchMLSOneOnOneConversation(
            userID: userID,
            in: context
        )

        try await establishMLSGroupIfNeeded(
            userID: userID,
            mlsGroupID: mlsGroupID
        )

        try await context.perform {
            try self.switchActiveOneOnOneConversation(
                userID: userID,
                mlsGroupID: mlsGroupID,
                in: context
            )

            context.saveOrRollback()
        }

        return mlsGroupID
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

    private func switchActiveOneOnOneConversation(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) throws {
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

        if let proteusConversation = connection.conversation {
            copyMessagesFromProtheusConversation(
                proteusConversation,
                to: mlsConversation,
                in: context
            )
        }

        connection.conversation = mlsConversation
    }

    // MARK: - Copy Messages

    private func copyMessagesFromProtheusConversation(
        _ proteusConversation: ZMConversation,
        to mlsConversation: ZMConversation,
        in context: NSManagedObjectContext
    ) {
        guard let messages = try? fetchVisibleMessages(of: proteusConversation, context: context) else {
            assertionFailure("unable to fetch messages of proteus conversation!")
            return
        }

        for message in messages {
            if let mlsMessage = message.copyEntireObjectGraph(context: context) as? ZMMessage {
                mlsMessage.nonce = UUID() // keep objects uniquely identifiable
                mlsMessage.visibleInConversation = mlsConversation
                mlsMessage.hiddenInConversation = nil
            } else {
                // in production: continue for loop
                assertionFailure("expect cast ZMMessage to be always successful!")
            }
        }
    }

    private func fetchVisibleMessages(of conversation: ZMConversation, context: NSManagedObjectContext) throws -> [ZMMessage] {
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = conversation.visibleMessagesPredicate

        return try context.fetch(fetchRequest)
    }
}
