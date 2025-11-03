//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLegacyLogging

// sourcery: AutoMockable
public protocol OneOnOneMigratorInterface {

    @discardableResult
    func migrateToMLS(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> MLSGroupID

}

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
        // Fetch MLS 1:1 conversation and store it locally.
        let (mlsGroupID, removalKeys) = try await syncMLSConversationFromBackend(
            userID: userID,
            in: context
        )

        // Create or join the MLS conversation if needed.
        if try await !mlsService.conversationExists(groupID: mlsGroupID) {
            try await createOrJoinMLSConversationIfNeeded(
                userID: userID,
                mlsGroupID: mlsGroupID,
                removalKeys: removalKeys,
                in: context
            )
        }

        // Perform the migration of messages and link the MLS conversation if needed.
        // It's safe to attempt this step each time to enhance the resilience of the app.
        // This ensures that in cases where an MLS conversation exists but Proteus hasn't yet switched and the messages
        // haven't been migrated,
        // it will attempt the migration again.
        try await migrateMessagesAndLinkMLSConversationIfNeeded(
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
    ) async throws -> (MLSGroupID, BackendMLSPublicKeys?) {
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
        removalKeys: BackendMLSPublicKeys? = nil,
        in context: NSManagedObjectContext
    ) async throws {
        let users = [MLSUser(userID)]

        do {
            let ciphersuite = try await mlsService.establishGroup(
                for: mlsGroupID,
                with: users,
                removalKeys: removalKeys
            )
            await context.perform {
                let conversation = ZMConversation.fetch(with: mlsGroupID, in: context)
                conversation?.ciphersuite = ciphersuite
                conversation?.mlsStatus = .ready
            }
        } catch {
            throw MigrateMLSOneOnOneConversationError.failedToEstablishGroup(error)
        }
    }

    private func migrateMessagesAndLinkMLSConversationIfNeeded(
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

            guard !(mlsConversation.migratedToMLS && otherUser.oneOnOneConversation == mlsConversation) else {
                throw MigrateMLSOneOnOneConversationError.alreadyMigrated
            }

            WireLogger.conversation
                .info(
                    "Migrating messages and link the MLS conversation if needed. Conversation is migrated to MLS: \(mlsConversation.migratedToMLS), is oneOnOneConversation MLS: \(otherUser.oneOnOneConversation == mlsConversation)"
                )
            // Note on proteus, it's possible to have duplicate 1-1 conversations, so we need to fetch all relevant
            // 1-1 conversations here.
            let source = OneOnOneSource(context: context)
            var proteusConversations: [ZMConversation] = []
            // NOTE: querying for all types at once triggers a table scan which is very expensive
            for type in [OneOnOneType.fake, OneOnOneType.proteus, OneOnOneType.proteusPending] {
                let conversations = try source.fetchOneOnOnes(
                    user: otherUser,
                    types: [type]
                )
                proteusConversations.append(contentsOf: conversations)
            }

            // Move local messages from all proteus conversations
            for proteusConversation in proteusConversations {
                // Since ZMMessages only have a single conversation connected,
                // forming this union also removes the relationship to the proteus conversation.
                mlsConversation.migrateMessages(from: proteusConversation)
            }

            if !proteusConversations.isEmpty {
                // insert system message that we moved from proteus to MLS
                let sender = ZMUser.selfUser(in: context)
                mlsConversation.appendMLSMigrationFinalizedSystemMessageIfNeeded(sender: sender, at: .now)

                // update just to be sure
                mlsConversation.needsToBeUpdatedFromBackend = true
            }
            // switch active conversation
            otherUser.oneOnOneConversation = mlsConversation

            mlsConversation.migratedToMLS = true
        }
    }

    private func createOrJoinMLSConversationIfNeeded(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID,
        removalKeys: BackendMLSPublicKeys?,
        in context: NSManagedObjectContext
    ) async throws {
        guard let epoch = await fetchMLSConversationEpoch(mlsGroupID: mlsGroupID, in: context) else {
            throw MigrateMLSOneOnOneConversationError.missingConversationEpoch
        }

        if epoch == 0 {
            try await establishMLSGroupIfNeeded(
                userID: userID,
                mlsGroupID: mlsGroupID,
                removalKeys: removalKeys,
                in: context
            )
        } else {
            try await mlsService.joinGroup(with: mlsGroupID)
        }
    }
}
