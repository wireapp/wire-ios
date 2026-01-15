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

import Foundation
import WireDomain
import WireLogging
import WireNetwork

/// **Issue:**: Missing conversations - [WPB-22231]
struct AppVersionMigration_4_12_1: AppVersionMigration {

    let version: SemanticVersion = "4.12.1"
    let coreDataStack: CoreDataStackProtocol
    let api: ConversationsAPI
    let store: ConversationLocalStoreProtocol

    func perform() async throws {
        let context = coreDataStack.syncContext

        var conversationIds: [NSManagedObjectID] = []
        let deletedConversationIDs = await context.perform {
            // fetch all deleted conversations
            let conversations = ZMConversation.fetchDeleted(in: context)
            conversationIds = conversations.map(\.objectID)
            return conversations.compactMap { $0.qualifiedID.map { WireNetwork.QualifiedID(
                id: $0.uuid,
                domain: $0.domain
            ) } }
        }

        WireLogger.appVersionMigration.info(
            "\(deletedConversationIDs.count) Deleted conversations found",
            attributes: .safePublic
        )
        guard !deletedConversationIDs.isEmpty else {
            // no deleted conversation, just skip
            return
        }

        let conversationList = try await api.getConversations(for: deletedConversationIDs)

        WireLogger.appVersionMigration.info(
            "\(conversationList.found.count) conversations found",
            attributes: .safePublic
        )
        WireLogger.appVersionMigration.info(
            "\(conversationList.notFound.count) conversations really deleted",
            attributes:
            .safePublic
        )
        WireLogger.appVersionMigration.info(
            "\(conversationList.failed.count) conversations failed",
            attributes: .safePublic
        )

        try await context.perform {

            let conversations = conversationIds.compactMap { ZMConversation.existingObject(for: $0, in: context) }

            for existingConversation in conversationList.found {

                if let conversation = conversations.first(where: {
                    $0.qualifiedID?.toNetworkModel() == existingConversation.qualifiedID
                }) {
                    conversation.isDeletedRemotely = false
                    WireLogger.appVersionMigration.info(
                        "Restore deleted conversation",
                        attributes: [.conversationId: conversation.qualifiedID?.safeForLoggingDescription],
                        .safePublic
                    )
                }
            }

            for failedConversationID in conversationList.failed {

                let conversation = ZMConversation.fetch(
                    with: failedConversationID.id,
                    domain: failedConversationID.domain,
                    in: context
                )
                if let conversation {
                    conversation.isDeletedRemotely = false
                    WireLogger.appVersionMigration.info(
                        "Restoring failed conversation",
                        attributes: [.conversationId: conversation.qualifiedID?.safeForLoggingDescription],
                        .safePublic
                    )

                }
            }

            try context.save()
        }
    }
}

private extension WireDataModel.QualifiedID {
    func toNetworkModel() -> WireNetwork.QualifiedID {
        .init(id: uuid, domain: domain)
    }
}
