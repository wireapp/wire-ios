////
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
import WireDataModel

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

enum FederationError: Error, Equatable {
    case unreachableDomains(Set<String>)
    case nonFederatingDomains(Set<String>)
}

enum ConversationParticipantsError: Error {
    case invalidOperation
    case missingMLSParticipantsService
}

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

        try await validate(users: users, conversation: conversation)

        do {
            try await internalAddParticipants(users, to: conversation)
        } catch let error as FederationError {
            try await handleFederationError(
                error,
                users: users,
                conversation: conversation
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

            try await proteusParticipantsService.addParticipants(users, to: conversation)
        
        case .mls:

            guard let mlsParticipantsService else {
                throw ConversationParticipantsError.missingMLSParticipantsService
            }

            do {
                try await mlsParticipantsService.addParticipants(users, to: conversation)
            } catch MLSConversationParticipantsError.ignoredUsers(users: _) {
                // TODO: Insert system message
                // To be done in https://wearezeta.atlassian.net/browse/WPB-2228
            }

        case .mixed:

            guard let mlsParticipantsService else {
                throw ConversationParticipantsError.missingMLSParticipantsService
            }

            try await proteusParticipantsService.addParticipants(users, to: conversation)

            // For mixed protocol we only try once and don't handle errors
            try? await mlsParticipantsService.addParticipants(users, to: conversation)
        }
    }

    private func validate(
        users: [ZMUser],
        conversation: ZMConversation
    ) async throws {
        try await context.perform { [self] in
            guard
                conversation.conversationType == .group,
                !users.isEmpty,
                !users.contains(ZMUser.selfUser(in: context))
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
        case .nonFederatingDomains(let domains):
            let unreachableUsers = await context.perform { users.belongingTo(domains: domains) }

            if unreachableUsers.isEmpty {

                /// If there are no users from unreachable domains, this means that the backend tried and failed to check for non-fully connected graphs
                /// because some of the existing participants are currently unreachable.
                /// As a result, we should inform that users can't be added and not retry the request.
                /// https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/822149401/Non-fully+connected+federation+graphs

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
        case .unreachableDomains(let domains):
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
