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

// MARK: - MLSConversationParticipantsServiceInterface

// sourcery: AutoMockable
protocol MLSConversationParticipantsServiceInterface {
    func addParticipants(
        _ users: [ZMUser],
        to conversation: ZMConversation
    ) async throws

    func removeParticipant(
        _ user: ZMUser,
        from conversation: ZMConversation
    ) async throws
}

// MARK: - MLSConversationParticipantsError

enum MLSConversationParticipantsError: Error, Equatable {
    case failedToClaimKeyPackages(users: Set<ZMUser>)
    case invalidOperation
}

// MARK: - MLSConversationParticipantsService

struct MLSConversationParticipantsService: MLSConversationParticipantsServiceInterface {
    // MARK: Lifecycle

    init?(context: NSManagedObjectContext) {
        guard let syncContext = context.performAndWait({ context.zm_sync }) else {
            return nil
        }

        guard let mlsService = syncContext.performAndWait({ syncContext.mlsService }) else {
            return nil
        }

        self.init(
            context: context,
            mlsService: mlsService,
            clientIDsProvider: MLSClientIDsProvider()
        )
    }

    init(
        context: NSManagedObjectContext,
        mlsService: MLSServiceInterface,
        clientIDsProvider: MLSClientIDsProviding
    ) {
        self.context = context
        self.mlsService = mlsService
        self.clientIDsProvider = clientIDsProvider
    }

    // MARK: Internal

    // MARK: - Interface

    func addParticipants(
        _ users: [ZMUser],
        to conversation: ZMConversation
    ) async throws {
        let (qualifiedID, groupID) = await context.perform {
            (conversation.qualifiedID, conversation.mlsGroupID)
        }

        WireLogger.mls.info("adding \(users.count) participants to conversation (\(String(describing: qualifiedID)))")

        guard let groupID else {
            WireLogger.mls
                .warn(
                    "failed to add participants to conversation (\(String(describing: qualifiedID))): missing group ID"
                )
            throw MLSConversationParticipantsError.invalidOperation
        }

        let mlsUsers = await context.perform { users.compactMap(MLSUser.init(from:)) }

        do {
            try await mlsService.addMembersToConversation(with: mlsUsers, for: groupID)

        } catch let MLSService.MLSAddMembersError.failedToClaimKeyPackages(failedMLSUsers) {
            let failedUsers = await context.perform {
                users.filter { failedMLSUsers.contains(MLSUser(from: $0)) }
            }
            throw MLSConversationParticipantsError.failedToClaimKeyPackages(users: Set(failedUsers))

        } catch let SendCommitBundleAction.Failure.nonFederatingDomains(domains: domains) {
            throw FederationError.nonFederatingDomains(domains)

        } catch let SendCommitBundleAction.Failure.unreachableDomains(domains: domains) {
            throw FederationError.unreachableDomains(domains)

        } catch {
            WireLogger.mls
                .warn(
                    "failed to add members to conversation (\(String(describing: qualifiedID))): \(String(describing: error))"
                )
            throw error
        }
    }

    func removeParticipant(
        _ user: ZMUser,
        from conversation: ZMConversation
    ) async throws {
        let (qualifiedID, groupID, userID) = await context.perform {
            (conversation.qualifiedID, conversation.mlsGroupID, user.qualifiedID)
        }

        WireLogger.mls.info("removing participant from conversation (\(String(describing: qualifiedID)))")

        guard let groupID, let userID else {
            WireLogger.mls
                .warn(
                    "failed to remove participant from conversation (\(String(describing: qualifiedID))): invalid operation"
                )
            throw MLSConversationParticipantsError.invalidOperation
        }

        do {
            let clientIDs = try await clientIDsProvider.fetchUserClients(
                for: userID,
                in: context.notificationContext
            )

            try await mlsService.removeMembersFromConversation(
                with: clientIDs,
                for: groupID
            )
        } catch {
            WireLogger.mls
                .warn(
                    "failed to remove participant from conversation (\(String(describing: qualifiedID))): \(String(describing: error))"
                )
            throw error
        }
    }

    // MARK: Private

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let clientIDsProvider: MLSClientIDsProviding
    private let mlsService: MLSServiceInterface
}
