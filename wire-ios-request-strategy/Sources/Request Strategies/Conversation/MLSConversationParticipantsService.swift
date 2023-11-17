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

class MLSClientIDsProvider {

    func fetchUserClients(
        for userID: QualifiedID,
        in context: NotificationContext
    ) async throws -> [MLSClientID] {
        var action = FetchUserClientsAction(userIDs: [userID])
        let userClients = try await action.perform(in: context)
        return userClients.compactMap(MLSClientID.init(qualifiedClientID:))
    }

}

// sourcery: AutoMockable
protocol MLSConversationParticipantsServiceInterface: ConversationParticipantsServiceInterface {}

class MLSConversationParticipantsService: MLSConversationParticipantsServiceInterface {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let clientIDsProvider: MLSClientIDsProvider

    // MARK: - Life cycle

    init(
        context: NSManagedObjectContext,
        clientIDsProvider: MLSClientIDsProvider? = nil
    ) {
        self.context = context
        self.clientIDsProvider = clientIDsProvider ?? MLSClientIDsProvider()
    }

    // MARK: - Interface

    func addParticipants(
        _ users: [ZMUser],
        to conversation: ZMConversation,
        completion: @escaping AddParticipantAction.ResultHandler
    ) {
        Logging.mls.info("adding \(users.count) participants to conversation (\(String(describing: conversation.qualifiedID)))")

        guard
            let mlsService = getMLSService(fromSyncContext: context.zm_sync),
            let groupID = conversation.mlsGroupID
        else {
            Logging.mls.warn("failed to add participants to conversation (\(String(describing: conversation.qualifiedID))): invalid operation")
            completion(.failure(.invalidOperation))
            return
        }

        // If we don't copy the id here (contexts thread), then the app will
        // crash if we try to use it in the task (not on the contexts thread).
        let qualifiedID = conversation.qualifiedID
        let mlsUsers = users.compactMap(MLSUser.init(from:))

        Task {
            do {
                try await mlsService.addMembersToConversation(with: mlsUsers, for: groupID)

                await context.perform {
                    completion(.success(()))
                }

            } catch {
                Logging.mls.error("failed to add members to conversation (\(String(describing: qualifiedID))): \(String(describing: error))")

                await context.perform {
                    completion(.failure(.failedToAddMLSMembers))
                }
            }
        }
    }

    func removeParticipant(
        _ user: ZMUser,
        from conversation: ZMConversation,
        completion: @escaping WireDataModel.RemoveParticipantAction.ResultHandler
    ) {
        Logging.mls.info("removing participant from conversation (\(String(describing: conversation.qualifiedID)))")

        guard
            let mlsService = getMLSService(fromSyncContext: context.zm_sync),
            let groupID = conversation.mlsGroupID,
            let userID = user.qualifiedID
        else {
            Logging.mls.info("failed to remove participant from conversation (\(String(describing: conversation.qualifiedID))): invalid operation")
            completion(.failure(.invalidOperation))
            return
        }

        Task {
            do {
                let clientIDs = try await clientIDsProvider.fetchUserClients(
                    for: userID,
                    in: context.notificationContext
                )

                try await mlsService.removeMembersFromConversation(
                    with: clientIDs,
                    for: groupID
                )

                await context.perform {
                    completion(.success(()))
                }

            } catch {
                await context.perform {
                    Logging.mls.warn("failed to remove participant from conversation (\(String(describing: conversation.qualifiedID))): \(String(describing: error))")
                    completion(.failure(.failedToRemoveMLSMembers))
                }
            }
        }
    }
}

// MARK: - Helpers

private extension MLSConversationParticipantsService {
    func getMLSService(
        fromSyncContext context: NSManagedObjectContext
    ) -> MLSServiceInterface? {

        var mlsService: MLSServiceInterface?

        context.performAndWait {
            mlsService = context.mlsService
        }

        return mlsService
    }
}
