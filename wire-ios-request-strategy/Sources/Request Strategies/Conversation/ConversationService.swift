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
import WireDataModel

// sourcery: AutoMockable
public protocol ConversationServiceInterface {

    func createGroupConversation(
        name: String?,
        users: Set<ZMUser>,
        allowGuests: Bool,
        allowServices: Bool,
        enableReceipts: Bool,
        messageProtocol: MessageProtocol,
        completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void
    )

    func createTeamOneOnOneProteusConversation(
        user: ZMUser,
        completion: @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void
    )

    func syncConversation(
        qualifiedID: QualifiedID,
        completion: @escaping () -> Void
    )

    func syncConversation(
        qualifiedID: QualifiedID
    ) async

    func syncConversationIfMissing(
        qualifiedID: QualifiedID
    ) async

}

public enum ConversationCreationFailure: Error {

    case missingPermissions
    case missingSelfClientID
    case conversationNotFound
    case noMLSGroup
    case networkError(CreateGroupConversationAction.Failure)
    case underlyingError(Error)

}

public final class ConversationService: ConversationServiceInterface {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let createGroupFlow = Flow.createGroup
    private let participantsServiceBuilder: (NSManagedObjectContext) -> ConversationParticipantsServiceInterface

    // MARK: - Life cycle

    public init(context: NSManagedObjectContext,
                participantsServiceBuilder: ((NSManagedObjectContext) -> ConversationParticipantsServiceInterface)? = nil) {
        self.context = context
        self.participantsServiceBuilder = participantsServiceBuilder ?? { syncContext in
            ConversationParticipantsService(context: syncContext)
        }
    }

    // MARK: - Create conversation

    public func createGroupConversation(
        name: String?,
        users: Set<ZMUser>,
        allowGuests: Bool,
        allowServices: Bool,
        enableReceipts: Bool,
        messageProtocol: MessageProtocol,
        completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void
    ) {
        createGroupFlow.start()
        let flowCompletion = { [weak self] (result: Swift.Result<ZMConversation, ConversationCreationFailure>) in
            switch result {
            case .failure(let error):
                self?.createGroupFlow.fail(error)
            case .success:
                self?.createGroupFlow.succeed()
            }
            completion(result)
        }

        if let teamID = ZMUser.selfUser(in: context).teamIdentifier {
            internalCreateTeamGroupConversation(
                teamID: teamID,
                name: name,
                users: users,
                allowGuests: allowGuests,
                allowServices: allowServices,
                enableReceipts: enableReceipts,
                messageProtocol: messageProtocol,
                completion: flowCompletion
            )
        } else {
            internalCreateGroupConversation(
                name: name,
                users: users,
                completion: flowCompletion
            )
        }
    }

    public func createTeamOneOnOneProteusConversation(
        user: ZMUser,
        completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void
    ) {
        // Team 1-1 proteus conversations are "fake 1-1s" because they're
        // actually group conversation that are treated as 1-1s.
        internalCreateGroupConversation(
            teamID: user.teamIdentifier,
            name: nil,
            users: [user],
            accessMode: ConversationAccessMode.value(forAllowGuests: true),
            accessRoles: ConversationAccessRoleV2.from(
                allowGuests: true,
                allowServices: true
            ),
            enableReceipts: false,
            messageProtocol: .proteus
        ) { result in
            switch result {
            case .success(let conversation):
                user.oneOnOneConversation = conversation
                completion(.success(conversation))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func internalCreateTeamGroupConversation(
        teamID: UUID,
        name: String?,
        users: Set<ZMUser>,
        allowGuests: Bool,
        allowServices: Bool,
        enableReceipts: Bool,
        messageProtocol: WireDataModel.MessageProtocol,
        completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void
    ) {
        guard ZMUser.selfUser(in: context).canCreateConversation(type: .group) else {
            completion(.failure(.missingPermissions))
            return
        }

        internalCreateGroupWithRetryIfNeeded(
            teamID: teamID,
            name: name,
            users: users,
            accessMode: ConversationAccessMode.value(forAllowGuests: allowGuests),
            accessRoles: ConversationAccessRoleV2.from(
                allowGuests: allowGuests,
                allowServices: allowServices
            ),
            enableReceipts: enableReceipts,
            messageProtocol: messageProtocol,
            completion: completion
        )
    }

    private func internalCreateGroupConversation(
        name: String?,
        users: Set<ZMUser>,
        completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void
    ) {

        internalCreateGroupWithRetryIfNeeded(
            teamID: nil,
            name: name,
            users: users,
            accessMode: ConversationAccessMode(),
            accessRoles: [],
            enableReceipts: false,
            messageProtocol: .proteus,
            completion: completion
        )
    }

    private func internalCreateGroupWithRetryIfNeeded(
        teamID: UUID?,
        name: String?,
        users: Set<ZMUser>,
        accessMode: ConversationAccessMode,
        accessRoles: Set<ConversationAccessRoleV2>,
        enableReceipts: Bool,
        messageProtocol: WireDataModel.MessageProtocol,
        completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void) {

            func createGroup(
                withUsers users: Set<ZMUser>,
                completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void
            ) {
                internalCreateGroupConversation(
                    teamID: teamID,
                    name: name,
                    users: users,
                    accessMode: accessMode,
                    accessRoles: accessRoles,
                    enableReceipts: enableReceipts,
                    messageProtocol: messageProtocol,
                    completion: completion
                )
            }

            createGroupFlow.checkpoint(description: "create Group with user ids: \(users.map { $0.remoteIdentifier.transportString() }.joined(separator: ","))")
            createGroup(withUsers: users) { result in
                switch result {
                case .failure(.networkError(.unreachableDomains(let domains))):
                    let unreachableUsers = users.belongingTo(domains: domains)
                    let reachableUsers = Set(users).subtracting(unreachableUsers)

                    self.createGroupFlow.checkpoint(description: "retry create Group with unreachableUsers \(users.map { $0.remoteIdentifier.transportString() }.joined(separator: ","))")
                    createGroup(withUsers: reachableUsers) { retryResult in

                        if case .success(let conversation) = retryResult {
                            conversation.appendFailedToAddUsersSystemMessage(
                                users: unreachableUsers,
                                sender: .selfUser(in: self.context),
                                at: Date()
                            )
                        }

                        completion(retryResult)
                    }

                default:
                    completion(result)
                }
            }
        }

    private func internalCreateGroupConversation(
        teamID: UUID?,
        name: String?,
        users: Set<ZMUser>,
        accessMode: ConversationAccessMode,
        accessRoles: Set<ConversationAccessRoleV2>,
        enableReceipts: Bool,
        messageProtocol: WireDataModel.MessageProtocol,
        completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void
    ) {
        let selfUser = ZMUser.selfUser(in: context)

        guard let selfClientID = selfUser.selfClient()?.remoteIdentifier else {
            completion(.failure(.missingSelfClientID))
            return
        }

        let usersExcludingSelfUser = users.filter { !$0.isSelfUser }
        let qualifiedUserIDs: [QualifiedID]
        let unqualifiedUserIDs: [UUID]

        if let ids = usersExcludingSelfUser.qualifiedUserIDs {
            qualifiedUserIDs = ids
            unqualifiedUserIDs = []
        } else {
            qualifiedUserIDs = []
            unqualifiedUserIDs = usersExcludingSelfUser.compactMap(\.remoteIdentifier)
        }

        var action = CreateGroupConversationAction(
            messageProtocol: messageProtocol,
            creatorClientID: selfClientID,
            qualifiedUserIDs: qualifiedUserIDs,
            unqualifiedUserIDs: unqualifiedUserIDs,
            name: name,
            accessMode: accessMode,
            accessRoles: accessRoles,
            legacyAccessRole: nil,
            teamID: teamID,
            isReadReceiptsEnabled: enableReceipts
        )

        action.perform(in: context.notificationContext) { result in

            self.context.perform {
                switch result {
                case .success(let objectID):
                    Task {
                        do {
                            try await self.handleMLSConversationIfNeeded(
                                for: objectID,
                                participantObjectIDs: Set(usersExcludingSelfUser.map(\.objectID)))
                        } catch {
                            if error.isFailedToAddSomeUsersError {
                                // we ignore the error a system message is inserted
                                // and focus on group creation successful
                            } else {
                                await self.context.perform {
                                    completion(.failure(.underlyingError(error)))
                                }
                                return
                            }
                        }

                        await self.context.perform {
                            if let conversation = try? self.context.existingObject(with: objectID) as? ZMConversation {
                                completion(.success(conversation))
                            } else {
                                completion(.failure(.conversationNotFound))
                            }
                        }
                    }

                case .failure(CreateGroupConversationAction.Failure.notConnected):
                    users.forEach { $0.needsToBeUpdatedFromBackend = true }
                    self.context.enqueueDelayedSave()
                    completion(.failure(.networkError(.notConnected)))

                case .failure(let failure):
                    completion(.failure(.networkError(failure)))
                }
            }
        }
    }

    private func handleMLSConversationIfNeeded(for conversationObjectId: NSManagedObjectID,
                                               participantObjectIDs: Set<NSManagedObjectID>) async throws {
        guard let syncContext = await context.perform({ self.context.zm_sync }) else {
            assertionFailure("handleMLSConversationIfNeeded must be done on syncContext")
            return
        }
        guard let syncConversation = await syncContext.perform({
            let conversation = try? syncContext.existingObject(with: conversationObjectId) as? ZMConversation

            guard conversation?.messageProtocol == .mls else {
                // proteus: nothing to do for proteus, see action handler
                // mixed: Conversations should never be created with mixed protocol, that's why we break here
                return ZMConversation?.none
            }
            return conversation
        }) else {
            return
        }

        guard let syncParticipants: [ZMUser] = await syncContext.perform({
            var participants: [ZMUser] = participantObjectIDs.existingObjects(in: syncContext) ?? []
            participants.append(ZMUser.selfUser(in: syncContext))
            return participants
        }) else {
            return
        }

        let (mlsGroupID, mlsService) = await syncContext.perform {
            (syncConversation.mlsGroupID, syncContext.mlsService)
        }

        guard let mlsGroupID, let mlsService else { return }

        self.createGroupFlow.checkpoint(description: "create MLS group with ID (\(mlsGroupID))")
        let ciphersuite = try await mlsService.createGroup(for: mlsGroupID, removalKeys: nil)

        await syncContext.perform {
            self.createGroupFlow.checkpoint(description: "marking MLS ZMConversation ready, group ID (\(String(describing: syncConversation.mlsGroupID)))")

            // Self user is creator, so we don't need to process a welcome message
            syncConversation.mlsStatus = .ready
            syncConversation.ciphersuite = ciphersuite
            syncContext.saveOrRollback()
        }

        let participantsService = participantsServiceBuilder(syncContext)
        self.createGroupFlow.checkpoint(description: MLSAddParticipantLog(users: syncParticipants, groupId: mlsGroupID))
        try await participantsService.addParticipants(syncParticipants, to: syncConversation)
    }

    // MARK: - Sync conversation

    public func syncConversation(
        qualifiedID: QualifiedID,
        completion: @escaping () -> Void = {}
    ) {
        var action = SyncConversationAction(qualifiedID: qualifiedID)
        action.perform(in: context.notificationContext) { _ in
            completion()
        }
    }

    public func syncConversationIfMissing(
        qualifiedID: QualifiedID
    ) async {
        guard await context.perform({
            ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: self.context)
        }) == nil else {
            return
        }
        await syncConversation(qualifiedID: qualifiedID)
    }

    public func syncConversation(
        qualifiedID: QualifiedID
    ) async {
        await withCheckedContinuation { continuation in
            syncConversation(qualifiedID: qualifiedID) {
                continuation.resume()
            }
        }
    }
}

struct MLSAddParticipantLog: LogConvertible {
    var users: [ZMUser]
    var groupId: MLSGroupID

    var logDescription: String {
        let ids = users.compactMap { user in user.managedObjectContext?.performAndWait {
            user.remoteIdentifier.transportString()
        } }
        return "add MLS participants \(ids.joined(separator: ",")) - MLS Group ID: \(groupId.safeForLoggingDescription)"
    }
}
