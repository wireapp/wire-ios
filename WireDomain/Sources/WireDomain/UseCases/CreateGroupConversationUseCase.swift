//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
/// Creates and sets up a group conversation or a channel.
///
/// Channels are group conversations that belong to a team, have a name, and always use MLS.
/// Pass `.channel` as `groupType` for channels or `.group` for regular group conversations.
public protocol CreateGroupConversationUseCaseProtocol {
    func invoke(
        groupType: WireNetwork.ConversationGroupType,
        teamID: UUID?,
        messageProtocol: WireNetwork.ConversationMessageProtocol,
        name: String?,
        historyDepth: String?,
        cells: Bool?,
        users: Set<ZMUser>,
        accessMode: Set<WireNetwork.ConversationAccessMode>,
        accessRoles: Set<WireNetwork.ConversationAccessRole>,
        enableReceipts: Bool,
        isMLSEnabled: Bool
    ) async throws -> ZMConversation
}

public struct CreateGroupConversationUseCase: CreateGroupConversationUseCaseProtocol {

    public enum Failure: Error {
        case missingSelfClientID
        case missingConversationID
        case conversationNotFound
        case failedToCreate(Error)
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
    private let logger: WireLogger = .conversation

    // MARK: - Object lifecycle

    public init(
        api: any ConversationsAPI,
        store: any ConversationLocalStoreProtocol,
        mlsService: (any MLSServiceInterface)?,
        context: NSManagedObjectContext,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.api = api
        self.store = store
        self.mlsService = mlsService
        self.context = context
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled
    }

    // MARK: - Invoke

    public func invoke(
        groupType: WireNetwork.ConversationGroupType,
        teamID: UUID?,
        messageProtocol: WireNetwork.ConversationMessageProtocol,
        name: String?,
        historyDepth: String?,
        cells: Bool?,
        users: Set<ZMUser>,
        accessMode: Set<WireNetwork.ConversationAccessMode>,
        accessRoles: Set<WireNetwork.ConversationAccessRole>,
        enableReceipts: Bool,
        isMLSEnabled: Bool
    ) async throws -> ZMConversation {
        do {
            return try await createConversation(
                groupType: groupType,
                teamID: teamID,
                messageProtocol: messageProtocol,
                name: name,
                historyDepth: historyDepth,
                cells: cells,
                users: users,
                accessMode: accessMode,
                accessRoles: accessRoles,
                enableReceipts: enableReceipts,
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
                    return try await createConversationExcludingDomains(
                        domains,
                        groupType: groupType,
                        teamID: teamID,
                        messageProtocol: messageProtocol,
                        name: name,
                        historyDepth: historyDepth,
                        cells: cells,
                        users: users,
                        accessMode: accessMode,
                        accessRoles: accessRoles,
                        enableReceipts: enableReceipts,
                        isMLSEnabled: isMLSEnabled
                    )
                } catch {
                    throw Failure.nonFederatingDomains(Set(domains))
                }

            default:
                throw Failure.failedToCreate(error)
            }
        } catch {
            throw Failure.failedToCreate(error)
        }
    }

    // MARK: - Core creation

    private func createConversation(
        groupType: WireNetwork.ConversationGroupType,
        teamID: UUID?,
        messageProtocol: WireNetwork.ConversationMessageProtocol,
        name: String?,
        historyDepth: String?,
        cells: Bool?,
        users: Set<ZMUser>,
        accessMode: Set<WireNetwork.ConversationAccessMode>,
        accessRoles: Set<WireNetwork.ConversationAccessRole>,
        enableReceipts: Bool,
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

            return (selfClientID, qualifiedUserIDs, unqualifiedUserIDs)
        }

        // TODO: [WPB-18347] - add historyDepth to body when API is ready

        let apiParameters = CreateGroupConversationParameters(
            groupType: groupType,
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
            remoteConversation,
            isMLSEnabled: isMLSEnabled
        )

        if messageProtocol == .mls {
            try await setupMLS(
                for: localConversation,
                with: users
            )
        }

        return localConversation
    }

    // MARK: - API error handling

    private func createConversationExcludingDomains(
        _ excludedDomains: [String],
        groupType: WireNetwork.ConversationGroupType,
        teamID: UUID?,
        messageProtocol: WireNetwork.ConversationMessageProtocol,
        name: String?,
        historyDepth: String?,
        cells: Bool?,
        users: Set<ZMUser>,
        accessMode: Set<WireNetwork.ConversationAccessMode>,
        accessRoles: Set<WireNetwork.ConversationAccessRole>,
        enableReceipts: Bool,
        isMLSEnabled: Bool
    ) async throws -> ZMConversation {
        let (unreachableUsers, reachableUsers) = await context.perform {
            let unreachableUsers = users.belongingTo(domains: Set(excludedDomains))
            return (unreachableUsers, Set(users).subtracting(unreachableUsers))
        }

        let conversation = try await createConversation(
            groupType: groupType,
            teamID: teamID,
            messageProtocol: messageProtocol,
            name: name,
            historyDepth: historyDepth,
            cells: cells,
            users: reachableUsers,
            accessMode: accessMode,
            accessRoles: accessRoles,
            enableReceipts: enableReceipts,
            isMLSEnabled: isMLSEnabled
        )

        await appendFailedToAddUsersMessage(
            in: conversation,
            users: unreachableUsers
        )

        return conversation
    }

    // MARK: - Local store

    private func createConversationLocally(
        _ conversation: WireNetwork.Conversation,
        isMLSEnabled: Bool
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

        guard let localConversation else {
            throw Failure.conversationNotFound
        }

        await context.perform {
            _ = context.saveOrRollback()
        }

        return localConversation
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

        try await validate(
            users: participants,
            conversation: conversation
        )

        let ciphersuite = try await establishMLSGroup(
            participants,
            for: mlsGroupID,
            conversation: conversation
        )

        await context.perform {
            // Self user is creator, so we don't need to process a welcome message
            conversation.mlsStatus = .ready
            conversation.ciphersuite = ciphersuite
            context.saveOrRollback()
        }
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

    /// Creates an MLS group and adds participants atomically, with error handling and retries.
    ///
    /// On key package or federation failures, retries with the filtered user set.
    /// Each retry creates a fresh group (the prior attempt was rolled back).

    private func establishMLSGroup(
        _ users: Set<ZMUser>,
        for groupID: MLSGroupID,
        conversation: ZMConversation
    ) async throws -> WireDataModel.MLSCipherSuite {
        guard let mlsService else { throw Failure.invalidOperation }

        let qualifiedID = await context.perform { conversation.qualifiedID }

        WireLogger.mls.info(
            "establishing MLS group for conversation (\(String(describing: qualifiedID))) with \(users.count) participants"
        )

        let mlsUsers = await context.perform {
            users.compactMap {
                MLSUser(from: $0, localDomain: localDomain)
            }
        }

        do {
            return try await mlsService.establishGroup(
                for: groupID,
                with: mlsUsers,
                removalKeys: nil
            )

        } catch let MLSService.MLSAddMembersError.failedToClaimKeyPackages(failedMLSUsers) {
            let failedUsers = await context.perform {
                users.filter {
                    failedMLSUsers.contains(MLSUser(from: $0, localDomain: self.localDomain))
                }
            }
            return try await handleNotClaimedKeyPackages(
                failedUsers: Set(failedUsers),
                users: users,
                for: groupID,
                conversation: conversation
            )

        } catch let SendMLSMessageFailure.nonFederatingDomains(domains: domains) {
            return try await handleNonFederatingDomains(
                domains,
                users: users,
                for: groupID,
                conversation: conversation
            )

        } catch let SendMLSMessageFailure.unreachableDomains(domains: domains) {
            return try await handleUnreachableDomains(
                domains,
                users: users,
                for: groupID,
                conversation: conversation
            )

        } catch {
            WireLogger.mls.warn(
                "failed to establish MLS group for conversation (\(String(describing: qualifiedID))): \(String(describing: error))"
            )
            throw error
        }
    }

    // MARK: - MLS error handling

    private func handleNotClaimedKeyPackages(
        failedUsers: Set<ZMUser>,
        users: Set<ZMUser>,
        for groupID: MLSGroupID,
        conversation: ZMConversation
    ) async throws -> WireDataModel.MLSCipherSuite {
        guard !failedUsers.isEmpty else {
            Flow.addParticipants.checkpoint(
                description: "unexpected failedToClaimKeyPackages but no failed users"
            )
            throw Failure.invalidOperation
        }

        let allUsers = Set(users)
        var ciphersuite: WireDataModel.MLSCipherSuite?

        if failedUsers != allUsers {
            // Filter out users without key packages and retry with the remainder.
            // This creates a fresh group (the prior attempt was rolled back).
            Flow.addParticipants.checkpoint(description: "retrying failedUsers begin")
            ciphersuite = try await establishMLSGroup(
                allUsers.subtracting(failedUsers),
                for: groupID,
                conversation: conversation
            )
            Flow.addParticipants.checkpoint(description: "retrying failedUsers end")
        }

        let failedUserIds = await context.perform {
            failedUsers.map { $0.remoteIdentifier.transportString() }
        }

        Flow.addParticipants.checkpoint(
            description: "add FailedToAddUsersMessage for users: \(failedUserIds.joined(separator: ", "))"
        )

        await appendFailedToAddUsersMessage(in: conversation, users: failedUsers)

        guard let ciphersuite else {
            throw Failure.failedToCreate(
                MLSService.MLSAddMembersError.failedToClaimKeyPackages(users: Array(failedUsers).compactMap {
                    MLSUser(from: $0, localDomain: localDomain)
                })
            )
        }

        return ciphersuite
    }

    private func handleUnreachableDomains(
        _ domains: Set<String>,
        users: Set<ZMUser>,
        for groupID: MLSGroupID,
        conversation: ZMConversation
    ) async throws -> WireDataModel.MLSCipherSuite {
        let unreachableUsers = await context.perform { users.belongingTo(domains: domains) }

        if unreachableUsers.isEmpty {
            /// Backend is not able to determine which users are unreachable.
            /// We just insert a message and do not attempt to retry.
            await appendFailedToAddUsersMessage(in: conversation, users: Set(users))
            throw Failure.invalidOperation
        } else {
            return try await retryEstablishingMLSGroup(
                users,
                for: groupID,
                conversation: conversation,
                excludingDomains: domains
            )
        }
    }

    private func handleNonFederatingDomains(
        _ domains: Set<String>,
        users: Set<ZMUser>,
        for groupID: MLSGroupID,
        conversation: ZMConversation
    ) async throws -> WireDataModel.MLSCipherSuite {
        try await retryEstablishingMLSGroup(
            users,
            for: groupID,
            conversation: conversation,
            excludingDomains: domains
        )
    }

    private func retryEstablishingMLSGroup(
        _ users: Set<ZMUser>,
        for groupID: MLSGroupID,
        conversation: ZMConversation,
        excludingDomains domains: Set<String>
    ) async throws -> WireDataModel.MLSCipherSuite {
        let usersToExclude = await context.perform { users.belongingTo(domains: domains) }
        let usersToAdd = Set(users).subtracting(usersToExclude)

        await appendFailedToAddUsersMessage(in: conversation, users: usersToExclude)

        guard !usersToAdd.isEmpty else {
            throw Failure.invalidOperation
        }

        return try await establishMLSGroup(usersToAdd, for: groupID, conversation: conversation)
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
