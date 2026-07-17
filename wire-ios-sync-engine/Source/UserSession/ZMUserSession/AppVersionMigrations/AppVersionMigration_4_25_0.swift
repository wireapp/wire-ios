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
import WireDataModel
import WireDomain
import WireLogging

/// **Issue:** Blocked 1:1 conversations were incorrectly hidden - [WPB-24403]
///
/// Prior to the fix in `UpdateConversationItem`, blocking a 1:1 user could end up marking the
/// associated conversation as `isDeletedRemotely = true`: the backend returns 404 on
/// `GET /conversations/{id}` for a 1:1 once the connection is blocked, and the work item
/// blindly deleted the local conversation in that case. This migration restores those
/// conversations so the user can see and unblock them from the conversation list.
struct AppVersionMigration_4_25_0: AppVersionMigration {

    let version: SemanticVersion = "4.25.0"
    let coreDataStack: CoreDataStackProtocol

    func perform() async throws {
        let context = coreDataStack.syncContext

        try await context.perform {
            let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
            request.predicate = NSPredicate(
                format: "%K == YES AND %K == %d AND %K.connection.status == %d",
                #keyPath(ZMConversation.isDeletedRemotely),
                ZMConversationConversationTypeKey,
                ZMConversationType.oneOnOne.rawValue,
                ZMConversationOneOnOneUserKey,
                ZMConnectionStatus.blocked.rawValue
            )

            let conversations = (try? context.fetch(request)) ?? []

            WireLogger.appVersionMigration.info(
                "\(conversations.count) blocked 1:1 conversations to restore",
                attributes: .safePublic
            )

            for conversation in conversations {
                conversation.isDeletedRemotely = false
                WireLogger.appVersionMigration.info(
                    "Restore blocked 1:1 conversation",
                    attributes: [.conversationId: conversation.qualifiedID?.safeForLoggingDescription],
                    .safePublic
                )
            }

            try context.save()
        }
    }
}
