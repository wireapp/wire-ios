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

// MARK: - ConversationParticipantsServiceInterface

// sourcery: AutoMockable
public protocol ConversationParticipantsServiceInterface {
    func addParticipants(
        _ users: [ZMUser],
        to conversation: ZMConversation
    ) async throws

    func removeParticipant(
        _ user: ZMUser,
        from conversation: ZMConversation
    ) async throws
}

// MARK: - FederationError

enum FederationError: Error, Equatable {
    case unreachableDomains(Set<String>)
    case nonFederatingDomains(Set<String>)
}

// MARK: - ConversationParticipantsError

enum ConversationParticipantsError: Error, Equatable {
    case invalidOperation
    case missingMLSParticipantsService
    case failedToAddSomeUsers(users: Set<ZMUser>)
}

extension Error {
    var isFailedToAddSomeUsersError: Bool {
        if case ConversationParticipantsError.failedToAddSomeUsers(_)? = (self as? ConversationParticipantsError) {
            return true
        }
        if case ConversationAddParticipantsError.failedToAddMLSMembers? = (self as? ConversationAddParticipantsError) {
            return true
        }
        return false
    }
}

// MARK: - ConversationParticipantsService

public class ConversationParticipantsService: ConversationParticipantsServiceInterface {
    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let proteusParticipantsService: ProteusConversationParticipantsServiceInterface
    private let mlsParticipantsService: MLSConversationParticipantsServiceInterface?

    // MARK: - Life cycle

    public convenience init(context: NSManagedObjectContext) {
        self.init(
            context: context,
            proteusParticipantsService: ProteusConversationParticipantsService(context: context),
            mlsParticipantsService: MLSConversationParticipantsService(context: context)
        )
    }

    init(
        context: NSManagedObjectContext,
        proteusParticipantsService: ProteusConversationParticipantsServiceInterface,
        mlsParticipantsService: MLSConversationParticipantsServiceInterface?
    ) {
        self.context = context
        self.proteusParticipantsService = proteusParticipantsService
        self.mlsParticipantsService = mlsParticipantsService
    }

    // MARK: - Adding Participants

    public func addParticipants(
        _ users: [ZMUser],
        to conversation: ZMConversation
    ) async throws {
        let userIds = await context.perform { users.map { $0.remoteIdentifier.transportString() } }
        Flow.addParticipants.checkpoint(description: "validate users: \(userIds.joined(separator: ", "))")
        try await validate(users: users, conversation: conversation)

        do {
            try await internalAddParticipants(users, to: conversation)
        } catch let error as FederationError {
            try await handleFederationError(
                error,
                users: users,
                conversation: conversation
            )
        } catch let ConversationParticipantsError.failedToAddSomeUsers(users: failedUsers) {
            let failedUserIds = await context.perform { failedUsers.map { $0.remoteIdentifier.transportString() } }
            Flow.addParticipants
                .checkpoint(
                    description: "add FailedToAddUsersMessage for users: \(failedUserIds.joined(separator: ", "))"
                )

            await appendFailedToAddUsersMessage(
                in: conversation,
                users: failedUsers
            )
        }
    }

    private func internalAddParticipants(
        _ users: [ZMUser],
        to conversation: ZMConversation
    ) async throws {
        let messageProtocol = await context.perform { conversation.messageProtocol }

        switch messageProtocol {
        case .proteus:
            Flow.addParticipants.checkpoint(description: "add users for Proteus")
            try await proteusParticipantsService.addParticipants(users, to: conversation)

        case .mls:
            Flow.addParticipants.checkpoint(description: "add users for MLS")
            try await addMLSParticipants(users, to: conversation)

        case .mixed:

            if mlsParticipantsService == nil {
                throw ConversationParticipantsError.missingMLSParticipantsService
            }

            try await proteusParticipantsService.addParticipants(users, to: conversation)

            // For mixed protocol we only try once and don't handle errors
            try? await addMLSParticipants(users, to: conversation)
        }
    }

    private func addMLSParticipants(
        _ users: [ZMUser],
        to conversation: ZMConversation
    ) async throws {
        guard let mlsParticipantsService else {
            throw ConversationParticipantsError.missingMLSParticipantsService
        }

        do {
            try await mlsParticipantsService.addParticipants(users, to: conversation)
        } catch let MLSConversationParticipantsError.failedToClaimKeyPackages(users: failedUsers) {
            guard !failedUsers.isEmpty else {
                return Flow.addParticipants
                    .checkpoint(description: "unexpected failedToClaimKeyPackages but no failed users")
            }

            let users = Set(users)
            if failedUsers != users {
                // Operation was aborted because some users didn't have key packages
                // We filter them out and retry once
                Flow.addParticipants.checkpoint(description: "retrying failedUsers begin")
                try await internalAddParticipants(
                    Array(users.subtracting(failedUsers)),
                    to: conversation
                )
                Flow.addParticipants.checkpoint(description: "retrying failedUsers end")
            }

            throw ConversationParticipantsError.failedToAddSomeUsers(users: failedUsers)
        }
    }

    private func validate(
        users: [ZMUser],
        conversation: ZMConversation
    ) async throws {
        try await context.perform {
            guard
                conversation.conversationType == .group,
                !users.isEmpty
            else {
                throw ConversationParticipantsError.invalidOperation
            }
        }
    }

    private func handleFederationError(
        _ error: FederationError,
        users: [ZMUser],
        conversation: ZMConversation
    ) async throws {
        switch error {
        case let .unreachableDomains(domains):
            let unreachableUsers = await context.perform { users.belongingTo(domains: domains) }

            if unreachableUsers.isEmpty {
                /// Backend is not able to determine which users are unreachable.
                /// We just insert a message and do not attempt to retry

                await appendFailedToAddUsersMessage(
                    in: conversation,
                    users: Set(users)
                )
            } else {
                try await retryAddingParticipants(
                    users,
                    to: conversation,
                    excludingDomains: domains
                )
            }

        case let .nonFederatingDomains(domains):
            try await retryAddingParticipants(
                users,
                to: conversation,
                excludingDomains: domains
            )
        }
    }

    private func retryAddingParticipants(
        _ users: [ZMUser],
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

        try await internalAddParticipants(
            Array(usersToAdd),
            to: conversation
        )
    }

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
            self.context.enqueueDelayedSave()
        }
    }

    // MARK: - Removing Participant

    public func removeParticipant(
        _ user: ZMUser,
        from conversation: ZMConversation
    ) async throws {
        guard await context.perform({ conversation.conversationType == .group }) else {
            throw ConversationParticipantsError.invalidOperation
        }

        let (messageProtocol, isSelfUser) = await context.perform {
            (conversation.messageProtocol, user.isSelfUser)
        }

        switch (messageProtocol, isSelfUser) {
        case (.proteus, _), (.mixed, _), (.mls, true):
            try await proteusParticipantsService.removeParticipant(user, from: conversation)
        case (.mls, false):
            guard let mlsParticipantsService else {
                throw ConversationParticipantsError.missingMLSParticipantsService
            }
            try await mlsParticipantsService.removeParticipant(user, from: conversation)
        }
    }
}
