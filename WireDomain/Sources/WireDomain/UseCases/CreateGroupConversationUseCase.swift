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

import WireDataModel
import WireLogging
import WireNetwork

// sourcery: AutoMockable
/// Creates and setup a group conversation
public protocol CreateGroupConversationUseCaseProtocol {
    func invoke(
        teamID: UUID?,
        messageProtocol: WireNetwork.ConversationMessageProtocol,
        name: String?,
        users: Set<ZMUser>,
        accessMode: Set<WireNetwork.ConversationAccessMode>,
        accessRoles: Set<WireNetwork.ConversationAccessRole>,
        enableReceipts: Bool,
        cells: Bool?,
        isMLSEnabled: Bool
    ) async throws -> ZMConversation
}

/// Channels are MLS conversations which belong to a team and have a name.
public struct CreateGroupConversationUseCase: CreateGroupConversationUseCaseProtocol {

    public enum Failure: Error {
        case missingSelfClientID
        case missingConversationID
        case conversationNotFound
        case failedToCreateGroup(Error)
        case missingLegalholdConsent
        case nonFederatingDomains(Set<String>)
        case notConnected
        case invalidOperation
    }

    // MARK: - Properties

    private let api: any ConversationsAPI
    private let store: any ConversationLocalStoreProtocol
    private let mlsService: (any MLSServiceInterface)?
    private let context: NSManagedObjectContext
    private let localDomain: String?
    private let isFederationEnabled: Bool
    private let isMLSEnabled: Bool
    private let logger: WireLogger = .conversation

    // MARK: - Object lifecycle

    public init(
        api: ConversationsAPI,
        store: ConversationLocalStoreProtocol,
        mlsService: (any MLSServiceInterface)?,
        context: NSManagedObjectContext,
        localDomain: String?,
        isFederationEnabled: Bool,
        isMLSEnabled: Bool
    ) {
        self.api = api
        self.store = store
        self.mlsService = mlsService
        self.context = context
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled
        self.isMLSEnabled = isMLSEnabled
    }

    public func invoke(
        teamID: UUID?,
        messageProtocol: WireNetwork.ConversationMessageProtocol,
        name: String?,
        users: Set<ZMUser>,
        accessMode: Set<WireNetwork.ConversationAccessMode>,
        accessRoles: Set<WireNetwork.ConversationAccessRole>,
        enableReceipts: Bool,
        cells: Bool?,
        isMLSEnabled: Bool
    ) async throws -> ZMConversation {
        do {
            return try await createGroup(
                teamID: teamID,
                messageProtocol: messageProtocol,
                name: name,
                users: users,
                accessMode: accessMode,
                accessRoles: accessRoles,
                enableReceipts: enableReceipts,
                cells: cells,
                isMLSEnabled: isMLSEnabled
            )
        } catch let error as ConversationsAPIError {
            switch error {
            case .notConnected:
                await context.perform {
                    users.forEach { $0.needsToBeUpdatedFromBackend = true }
                    context.enqueueDelayedSave()
                }

                throw Failure.notConnected
            case .missingLegalHoldConsent:
                throw Failure.missingLegalholdConsent
            case let .nonFederatingBackends(domains):
                do {
                    return try await createGroupExcludingDomains(
                        domains,
                        teamID: teamID,
                        messageProtocol: messageProtocol,
                        name: name,
                        accessMode: accessMode,
                        accessRoles: accessRoles,
                        enableReceipts: enableReceipts,
                        cells: cells,
                        users: users
                    )
                } catch {
                    throw Failure.nonFederatingDomains(Set(domains))
                }
            default:
                throw Failure.failedToCreateGroup(error)
            }
        } catch {
            throw Failure.failedToCreateGroup(error)
        }

    }

    private func createGroup(
        teamID: UUID?,
        messageProtocol: WireNetwork.ConversationMessageProtocol,
        name: String?,
        users: Set<ZMUser>,
        accessMode: Set<WireNetwork.ConversationAccessMode>,
        accessRoles: Set<WireNetwork.ConversationAccessRole>,
        enableReceipts: Bool,
        cells: Bool?,
        isMLSEnabled: Bool
    ) async throws -> ZMConversation {
        let (
            selfClientID,
            qualifiedUserIds,
            unqualifiedUserIds
        ) = try await context.perform {
            let selfUser = ZMUser.selfUser(in: context)

            guard let selfClientID = selfUser.selfClient()?.remoteIdentifier else {
                throw Failure.missingSelfClientID
            }

            let usersExcludingSelfUser = users.filter { !$0.isSelfUser }
            let qualifiedUserIDs: [WireNetwork.QualifiedID]
            let unqualifiedUserIDs: [UUID]

            if let ids = usersExcludingSelfUser.qualifiedUserIDs {
                qualifiedUserIDs = ids.toAPIModel()
                unqualifiedUserIDs = []
            } else {
                qualifiedUserIDs = []
                unqualifiedUserIDs = usersExcludingSelfUser.compactMap(\.remoteIdentifier)
            }

            return (
                selfClientID,
                qualifiedUserIDs,
                unqualifiedUserIDs
            )
        }

        let apiParameters = CreateGroupConversationParameters(
            groupType: .group,
            messageProtocol: messageProtocol,
            creatorClientID: selfClientID,
            qualifiedUserIDs: qualifiedUserIds,
            unqualifiedUserIDs: unqualifiedUserIds,
            name: name,
            accessMode: teamID == nil ? [] : accessMode,
            accessRoles: teamID == nil ? [] : accessRoles,
            legacyAccessRole: nil,
            teamID: teamID,
            isReadReceiptsEnabled: teamID == nil ? false : enableReceipts,
            cells: cells
        )

        let remoteConversation = try await api.createGroupConversation(
            parameters: apiParameters
        )

        let localConversation = try await createConversationLocally(
            remoteConversation
        )

        switch messageProtocol {
        case .mls:

            try await setupMLS(
                for: localConversation,
                with: users
            )

        case .mixed, .proteus:
            break
        }

        return localConversation
    }

    // MARK: - API error handling

    private func createGroupExcludingDomains(
        _ excludedDomains: [String],
        teamID: UUID?,
        messageProtocol: WireNetwork.ConversationMessageProtocol,
        name: String?,
        accessMode: Set<WireNetwork.ConversationAccessMode>,
        accessRoles: Set<WireNetwork.ConversationAccessRole>,
        enableReceipts: Bool,
        cells: Bool?,
        users: Set<ZMUser>
    ) async throws -> ZMConversation {
        let (unreachableUsers, reachableUsers) = await context.perform {
            let unreachableUsers = users.belongingTo(domains: Set(excludedDomains))
            let reachableUsers = Set(users).subtracting(unreachableUsers)

            return (unreachableUsers, reachableUsers)
        }

        // Retrying with reachable users (with federated domains)
        let conversation = try await createGroup(
            teamID: teamID,
            messageProtocol: messageProtocol,
            name: name,
            users: reachableUsers,
            accessMode: accessMode,
            accessRoles: accessRoles,
            enableReceipts: enableReceipts,
            cells: cells,
            isMLSEnabled: isMLSEnabled
        )

        // Add system message for unreachable users (with non federated domains)
        await appendFailedToAddUsersMessage(
            in: conversation,
            users: unreachableUsers
        )

        return conversation
    }

    // MARK: - MLS

    private func setupMLS(
        for conversation: ZMConversation,
        with participants: Set<ZMUser>
    ) async throws {
        let (mlsGroupID, isMLSConversation) = await context.perform {
            (
                conversation.mlsGroupID,
                conversation.messageProtocol == .mls
            )
        }

        guard isMLSConversation, let mlsGroupID, let mlsService else { return }

        let ciphersuite = try await mlsService.createGroup(
            for: mlsGroupID,
            removalKeys: nil
        )

        await context.perform {
            // Self user is creator, so we don't need to process a welcome message
            conversation.mlsStatus = .ready
            conversation.ciphersuite = ciphersuite
            context.saveOrRollback()
        }

        try await validate(
            users: participants,
            conversation: conversation
        )

        try await addMLSParticipants(
            participants,
            to: conversation
        )
    }

    private func validate(
        users: Set<ZMUser>,
        conversation: ZMConversation
    ) async throws {
        try await context.perform {
            guard
                conversation.conversationType == .group,
                !users.isEmpty
            else {
                throw Failure.invalidOperation
            }
        }
    }

    private func addMLSParticipants(
        _ users: Set<ZMUser>,
        to conversation: ZMConversation
    ) async throws {
        guard let mlsService else { return }

        let (qualifiedID, groupID) = await context.perform {
            (conversation.qualifiedID, conversation.mlsGroupID)
        }

        WireLogger.mls.info(
            "adding \(users.count) participants to conversation (\(String(describing: qualifiedID)))"
        )

        guard let groupID else {
            WireLogger.mls.warn(
                "failed to add participants to conversation (\(String(describing: qualifiedID))): missing group ID"
            )
            throw Failure.invalidOperation
        }

        let mlsUsers = await context.perform {
            users.compactMap {
                MLSUser(from: $0, localDomain: localDomain)
            }
        }

        do {

            try await mlsService.addMembersToConversation(
                with: mlsUsers,
                for: groupID
            )

            try await context.perform {
                try context.save()
            }

        } catch let MLSService.MLSAddMembersError.failedToClaimKeyPackages(failedMLSUsers) {
            let failedUsers = await context.perform {
                users.filter {
                    failedMLSUsers.contains(MLSUser(from: $0, localDomain: self.localDomain))
                }
            }

            try await handleNotClaimedKeyPackages(
                failedUsers: Set(failedUsers),
                users: users,
                conversation: conversation
            )

        } catch let SendMLSMessageFailure.nonFederatingDomains(domains: domains) {

            try await handleNonFederatingDomains(
                domains,
                users: users,
                conversation: conversation
            )

        } catch let SendMLSMessageFailure.unreachableDomains(domains: domains) {

            try await handleUnreachableDomains(
                domains,
                users: users,
                conversation: conversation
            )

        } catch {
            WireLogger.mls.warn(
                "failed to add members to conversation (\(String(describing: qualifiedID))): \(String(describing: error))"
            )
            throw error
        }

    }

    private func createConversationLocally(
        _ conversation: WireNetwork.Conversation
    ) async throws -> ZMConversation {
        await store.storeConversation(
            conversation.toDomainModel(),
            timestamp: .now,
            isFederationEnabled: isFederationEnabled,
            isMLSEnabled: isMLSEnabled
        )

        let qualifiedID = conversation.qualifiedID?.id
        guard let conversationID = conversation.id ?? qualifiedID else {
            throw Failure.missingConversationID
        }

        let conversationDomain = conversation.qualifiedID?.domain

        let localConversation = await store.fetchConversation(
            id: conversationID,
            domain: conversationDomain
        )

        // Conversation should be stored locally
        guard let localConversation else {
            throw Failure.conversationNotFound
        }

        await context.perform {
            _ = context.saveOrRollback()
        }

        return localConversation
    }

    // MARK: - MLS error handling

    private func handleNotClaimedKeyPackages(
        failedUsers: Set<ZMUser>,
        users: Set<ZMUser>,
        conversation: ZMConversation
    ) async throws {
        guard !failedUsers.isEmpty else {
            return Flow.addParticipants.checkpoint(
                description: "unexpected failedToClaimKeyPackages but no failed users"
            )
        }

        let users = Set(users)
        if failedUsers != users {

            // Operation was aborted because some users didn't have key packages
            // We filter them out and retry once
            Flow.addParticipants.checkpoint(description: "retrying failedUsers begin")
            try await addMLSParticipants(
                users.subtracting(failedUsers),
                to: conversation
            )
            Flow.addParticipants.checkpoint(description: "retrying failedUsers end")
        }

        let failedUserIds = await context.perform {
            failedUsers.map { $0.remoteIdentifier.transportString() }
        }

        Flow.addParticipants.checkpoint(
            description: "add FailedToAddUsersMessage for users: \(failedUserIds.joined(separator: ", "))"
        )

        await appendFailedToAddUsersMessage(
            in: conversation,
            users: failedUsers
        )
    }

    private func handleUnreachableDomains(
        _ domains: Set<String>,
        users: Set<ZMUser>,
        conversation: ZMConversation
    ) async throws {
        let unreachableUsers = await context.perform { users.belongingTo(domains: domains) }

        if unreachableUsers.isEmpty {

            /// Backend is not able to determine which users are unreachable.
            /// We just insert a message and do not attempt to retry

            await appendFailedToAddUsersMessage(
                in: conversation,
                users: Set(users)
            )
        } else {
            try await retryAddingMLSParticipants(
                users,
                to: conversation,
                excludingDomains: domains
            )
        }
    }

    private func handleNonFederatingDomains(
        _ domains: Set<String>,
        users: Set<ZMUser>,
        conversation: ZMConversation
    ) async throws {
        try await retryAddingMLSParticipants(
            users,
            to: conversation,
            excludingDomains: domains
        )
    }

    private func retryAddingMLSParticipants(
        _ users: Set<ZMUser>,
        to conversation: ZMConversation,
        excludingDomains domains: Set<String>
    ) async throws {
        let usersToExclude = await context.perform { users.belongingTo(domains: domains) }
        let usersToAdd = Set(users).subtracting(usersToExclude)

        await appendFailedToAddUsersMessage(
            in: conversation,
            users: usersToExclude
        )

        guard !usersToAdd.isEmpty else { return }

        try await addMLSParticipants(
            usersToAdd,
            to: conversation
        )
    }

    // MARK: - Helpers

    private func appendFailedToAddUsersMessage(
        in conversation: ZMConversation,
        users: Set<ZMUser>
    ) async {
        await context.perform {
            conversation.appendFailedToAddUsersSystemMessage(
                users: users,
                sender: conversation.creator,
                at: conversation.lastServerTimeStamp ?? Date()
            )
            context.enqueueDelayedSave()
        }
    }
}
