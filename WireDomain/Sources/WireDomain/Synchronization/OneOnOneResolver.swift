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

import CoreData
import WireDataModel
import WireLogging
import WireNetwork

public struct OneOnOneResolver: OneOnOneResolverProtocol {

    private enum Error: Swift.Error {
        case failedToActivateConversation
        case failedToFetchConversation
        case failedToEstablishGroup(Swift.Error)
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let userLocalStore: any UserLocalStoreProtocol
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let pullMLSOneOnOneSync: any PullMLSOneOnOneSyncProtocol
    private let mlsProvider: MLSProvider

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        userLocalStore: any UserLocalStoreProtocol,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        pullMLSOneOnOneSync: any PullMLSOneOnOneSyncProtocol,
        mlsProvider: MLSProvider
    ) {
        self.context = context
        self.userLocalStore = userLocalStore
        self.conversationLocalStore = conversationLocalStore
        self.pullMLSOneOnOneSync = pullMLSOneOnOneSync
        self.mlsProvider = mlsProvider
    }

    public func resolveAllOneOnOneConversations() async throws {
        let usersIDs = try await userLocalStore.fetchAllUserIDsWithOneOnOneConversation()

        await withTaskGroup(of: Void.self) { group in
            for userID in usersIDs {
                group.addTask {
                    do {
                        try await resolveOneOnOneConversation(with: userID)
                    } catch {
                        /// skip conversation migration for this user
                        WireLogger.conversation.error(
                            "resolve 1-1 conversation with userID \(userID) failed: \(error)",
                            attributes: [.senderUserId: userID.safeForLoggingDescription]
                        )
                    }
                }
            }
        }
    }

    public func resolveOneOnOneConversation(
        with userID: WireDataModel.QualifiedID
    ) async throws {
        let user = try await userLocalStore.fetchUser(
            id: userID.uuid, domain: userID.domain
        )

        let selfUser = await userLocalStore.fetchSelfUser()
        let commonProtocol = await getCommonProtocol(between: selfUser, and: user)

        if mlsProvider.isMLSEnabled, commonProtocol == .mls {
            try await resolveMLSConversation(
                for: user
            )
        }

        if mlsProvider.isMLSEnabled, commonProtocol == nil {
            await resolveNoCommonProtocolConversation(
                between: selfUser,
                and: user
            )
        }

        if commonProtocol == .proteus {
            await resolveProteusConversation(
                for: user
            )
        }
    }

    private func resolveMLSConversation(for user: ZMUser) async throws {
        WireLogger.conversation.debug("Should resolve to mls 1-1 conversation")

        let userID = await context.perform {
            user.qualifiedID
        }

        guard let userID else {
            throw Error.failedToActivateConversation
        }

        // Sync the user MLS conversation from backend.
        let mlsGroupID = try await pullMLSOneOnOneSync.pull(
            userID: userID.uuid,
            userDomain: userID.domain
        )

        // Then, fetch the synced MLS conversation.
        let mlsConversation = await conversationLocalStore.fetchMLSConversation(groupID: mlsGroupID)

        let groupID = await context.perform {
            mlsConversation?.mlsGroupID
        }

        guard let mlsConversation, let groupID else {
            throw Error.failedToFetchConversation
        }

        let mlsService = mlsProvider.service

        // If conversation already exists, there is no need to perform a migration.
        let needsMLSMigration = try await mlsService.conversationExists(
            groupID: groupID
        ) == false

        if needsMLSMigration {
            await migrateToMLS(
                mlsConversation: mlsConversation,
                mlsGroupID: groupID,
                user: user,
                userID: userID
            )
        }
    }

    private func migrateToMLS(
        mlsConversation: ZMConversation,
        mlsGroupID: MLSGroupID,
        user: ZMUser,
        userID: WireDataModel.QualifiedID
    ) async {
        do {
            try await setupMLSGroup(
                mlsConversation: mlsConversation,
                groupID: mlsGroupID,
                userID: userID
            )
        } catch {
            await context.perform {
                let userOneOnOneConversation = user.oneOnOneConversation
                userOneOnOneConversation?.isForcedReadOnly = true
            }

            return WireLogger.conversation.error(
                "Failed to setup MLS group with ID: \(mlsGroupID.safeForLoggingDescription)"
            )
        }

        await switchLocalConversationToMLS(
            mlsConversation: mlsConversation,
            for: user,
            userID: userID
        )
    }

    /// Establish a new MLS group (when epoch is 0) or join an existing group.
    /// - parameters:
    ///     - mlsConversation: The 1:1 MLS conversation.
    ///     - groupID: The MLS group ID.
    ///     - userID: The user ID that will be part of the MLS group.

    private func setupMLSGroup(
        mlsConversation: ZMConversation,
        groupID: MLSGroupID,
        userID: WireDataModel.QualifiedID
    ) async throws {
        let mlsService = mlsProvider.service

        let epoch = await context.perform {
            mlsConversation.epoch
        }

        if epoch == 0 {
            let users = [MLSUser(userID)]

            do {
                let ciphersuite = try await mlsService.establishGroup(
                    for: groupID,
                    with: users,
                    removalKeys: nil
                )

                await context.perform {
                    mlsConversation.ciphersuite = ciphersuite
                    mlsConversation.mlsStatus = .ready
                }

            } catch {
                throw Error.failedToEstablishGroup(error)
            }
        } else {
            try await mlsService.joinGroup(with: groupID)
        }
    }

    /// Migrates Proteus messages to the MLS conversation and sets the MLS conversation for the user.
    /// - Parameter mlsConversation: The MLS conversation.
    /// - Parameter user: The user to set the MLS conversation for.

    private func switchLocalConversationToMLS(
        mlsConversation: ZMConversation,
        for user: ZMUser,
        userID: WireDataModel.QualifiedID
    ) async {
        await context.perform {
            guard !(mlsConversation.migratedToMLS && user.oneOnOneConversation == mlsConversation) else {
                return
            }

            // Note on proteus, it's possible to have 2 duplicate 1-1 conversations, so we need to fetch both
            // conversations here.
            let proteusConversations: [ZMConversation] = fetchAllTeamOneOnOneProteusConversations(
                otherUserID: userID,
                in: context
            )

            var allProteusConversations = Set(proteusConversations)
            if let existingConversation = user.oneOnOneConversation,
               existingConversation.messageProtocol == .proteus {
                allProteusConversations.insert(existingConversation)
            }

            // move local messages from proteus conversations if they exist
            for proteusConversation in allProteusConversations {
                // Since ZMMessages only have a single conversation connected,
                // forming this union also removes the relationship to the proteus conversation.
                mlsConversation.migrateMessages(from: proteusConversation)
            }

            if !allProteusConversations.isEmpty {
                // insert system message that we moved from proteus to MLS
                let sender = ZMUser.selfUser(in: context)
                mlsConversation.appendMLSMigrationFinalizedSystemMessageIfNeeded(sender: sender, at: .now)

                mlsConversation.isForcedReadOnly = false
                // update just to be sure
                mlsConversation.needsToBeUpdatedFromBackend = true
            }

            /// Switch active conversation
            user.oneOnOneConversation = mlsConversation
            mlsConversation.migratedToMLS = true
        }
    }

    private func fetchAllTeamOneOnOneProteusConversations(
        otherUserID: WireDataModel.QualifiedID,
        in context: NSManagedObjectContext
    ) -> [ZMConversation] {
        guard let otherUser = ZMUser.fetch(with: otherUserID, in: context) else {
            return []
        }
        let selfUser = ZMUser.selfUser(in: context)
        guard selfUser.team != nil else {
            return []
        }

        let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        let teamOneOnOnePredicate = ZMConversation.predicateForTeamOneToOneConversation()

        let sameParticipant = NSPredicate(
            format: "ANY %K.user == %@ AND ANY %K.user == %@",
            ZMConversationParticipantRolesKey,
            otherUser,
            ZMConversationParticipantRolesKey,
            selfUser
        )

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            teamOneOnOnePredicate,
            sameParticipant
        ])

        return context.fetchOrAssert(request: request)
    }

    /// Resolves a Proteus 1:1 conversation.
    /// - Parameter user: The user to resolve the conversation for.

    private func resolveProteusConversation(
        for user: ZMUser
    ) async {
        await context.perform {
            WireLogger.conversation.debug(
                "Should resolve to Proteus 1-1 conversation",
                attributes: [.senderUserId: user.remoteIdentifier.safeForLoggingDescription]
            )

            guard let conversation = user.oneOnOneConversation else {
                return WireLogger.conversation.warn(
                    "Failed to resolve Proteus conversation: missing 1:1 conversation for user with id \(user.remoteIdentifier.safeForLoggingDescription)"
                )
            }

            conversation.isForcedReadOnly = false
        }
    }

    /// Resolves a 1:1 conversation with no common protocols between self user and user.
    /// - Parameter selfUser: The self user.
    /// - Parameter user: The other user.
    ///
    /// When no common protocols are found, the 1:1 conversation is marked as read only and a system
    /// message is append to the conversation to inform the self user or the user.

    private func resolveNoCommonProtocolConversation(
        between selfUser: ZMUser,
        and user: ZMUser
    ) async {
        await context.perform {
            WireLogger.conversation.debug("No common protocols found")

            guard let conversation = user.oneOnOneConversation else {
                return WireLogger.conversation.warn(
                    "Failed to resolve 1:1 conversation with no common protocol: missing 1:1 conversation for user with id \(user.remoteIdentifier.safeForLoggingDescription)"
                )
            }

            if !conversation.isForcedReadOnly {
                if !selfUser.supportedProtocols.contains(.mls) {
                    conversation.appendMLSMigrationMLSNotSupportedForSelfUser(user: selfUser)
                } else if !user.supportedProtocols.contains(.mls) {
                    conversation.appendMLSMigrationMLSNotSupportedForOtherUser(user: user)
                }

                conversation.isForcedReadOnly = true
            }
        }
    }

    private func getCommonProtocol(
        between selfUser: ZMUser,
        and otherUser: ZMUser
    ) async -> ConversationMessageProtocol? {
        await context.perform {
            let selfUserProtocols = selfUser.supportedProtocols
            let otherUserProtocols = otherUser.supportedProtocols.isEmpty ?
                [.proteus] : otherUser.supportedProtocols /// default to Proteus if empty.

            let commonProtocols = selfUserProtocols.intersection(otherUserProtocols)

            if commonProtocols.contains(.mls) {
                return .mls
            } else if commonProtocols.contains(.proteus) {
                return .proteus
            } else {
                return nil
            }
        }
    }
}
