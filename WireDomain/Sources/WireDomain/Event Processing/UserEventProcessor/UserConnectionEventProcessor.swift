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

import WireAPI
import WireDataModel

/// Process user connection events.

protocol UserConnectionEventProcessorProtocol {

    /// Process a user connection event.
    ///
    /// - Parameter event: A user connection event.

    func processEvent(_ event: UserConnectionEvent) async throws

}

struct UserConnectionEventProcessor: UserConnectionEventProcessorProtocol {

    enum UserConnectionEventError: Error {

        case failedToFetchConversation
        case failedToEstablishGroup(Error)
        case failedToActivateConversation

    }

    let context: NSManagedObjectContext
    let connectionsRepository: any ConnectionsRepositoryProtocol
    let userRepository: any UserRepositoryProtocol
    let conversationsRepository: any ConversationRepositoryProtocol
    let mlsService: any MLSServiceInterface

    func processEvent(_ event: UserConnectionEvent) async throws {
        let connection = event.connection

        try await connectionsRepository.updateConnection(connection)

        if connection.status == .accepted {
            try await resolveOneOnOneConversation(for: connection.receiverQualifiedID)
        }
    }

    private func resolveOneOnOneConversation(for userID: UserID?) async throws {
        guard let userID,
              let user = userRepository.fetchUser(with: userID.uuid, domain: userID.domain)
        else {
            throw UserConnectionEventError.failedToActivateConversation
        }

        let selfUser = userRepository.fetchSelfUser()
        let commonProtocol = getCommonProtocol(between: selfUser, and: user)
        let mlsEnabled = DeveloperFlag.enableMLSSupport.isOn

        if mlsEnabled, commonProtocol == .mls {
            try await resolveMLSConversation(
                for: user
            )
        }

        if mlsEnabled, commonProtocol == nil {
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

        guard let userID = user.qualifiedID else {
            throw UserConnectionEventError.failedToActivateConversation
        }

        /// Sync the user MLS conversation from backend.
        let mlsGroupID = try await conversationsRepository.pullMLSOneToOneConversation(
            userID: userID.uuid.uuidString,
            domain: userID.domain
        )

        /// Then, fetch the synced MLS conversation.
        let mlsConversation = await conversationsRepository.fetchMLSConversation(with: mlsGroupID)

        guard let mlsConversation, let groupID = mlsConversation.mlsGroupID else {
            throw UserConnectionEventError.failedToFetchConversation
        }

        let needsMLSMigration = try await mlsService.conversationExists(
            groupID: groupID
        ) == false

        /// If conversation already exists, there is no need to perform a migration.
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
            for: user
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
        if mlsConversation.epoch == 0 {
            let users = [MLSUser(userID)]

            do {
                let ciphersuite = try await mlsService.establishGroup(
                    for: groupID,
                    with: users
                )

                await context.perform {
                    mlsConversation.ciphersuite = ciphersuite
                    mlsConversation.mlsStatus = .ready
                }

            } catch {
                throw UserConnectionEventError.failedToEstablishGroup(error)
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
        for user: ZMUser
    ) async {
        await context.perform {
            /// Move local messages from proteus conversation if it exists
            if let proteusConversation = user.oneOnOneConversation {
                /// Since ZMMessages only have a single conversation connected,
                /// forming this union also removes the relationship to the proteus conversation.
                mlsConversation.mutableMessages.union(proteusConversation.allMessages)
                mlsConversation.isForcedReadOnly = false
                mlsConversation.needsToBeUpdatedFromBackend = true
            }

            /// Switch active conversation
            user.oneOnOneConversation = mlsConversation
        }
    }

    /// Resolves a Proteus 1:1 conversation.
    /// - Parameter user: The user to resolve the conversation for.

    private func resolveProteusConversation(
        for user: ZMUser
    ) async {
        WireLogger.conversation.debug("Should resolve to Proteus 1-1 conversation")

        guard let conversation = user.oneOnOneConversation else {
            return WireLogger.conversation.warn(
                "Failed to resolve Proteus conversation: missing 1:1 conversation for user with id \(user.remoteIdentifier.safeForLoggingDescription)"
            )
        }

        await context.perform {
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
        WireLogger.conversation.debug("No common protocols found")

        guard let conversation = user.oneOnOneConversation else {
            return WireLogger.conversation.warn(
                "Failed to resolve 1:1 conversation with no common protocol: missing 1:1 conversation for user with id \(user.remoteIdentifier.safeForLoggingDescription)"
            )
        }

        if !conversation.isForcedReadOnly {
            await context.perform {
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
    ) -> ConversationMessageProtocol? {
        let selfUserProtocols = selfUser.supportedProtocols
        let otherUserProtocols = otherUser.supportedProtocols.isEmpty ? [.proteus] : otherUser.supportedProtocols /// default to Proteus if empty.

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
