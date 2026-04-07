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
import WireLogging

/// Wipes an invalid MLS group and clears the group ID on the conversation.
///
/// Clearing the group ID prevents the generator from reprocessing this conversation.
struct WipeMLSGroupItem: WorkItem {

    let groupID: MLSGroupID
    private let mlsService: any MLSServiceInterface
    private let conversationLocalStore: any ConversationLocalStoreProtocol

    let _internalID = UUID()

    var id: String {
        "WipeMLSGroupItem_\(_internalID.uuidString)_\(groupID)"
    }

    var priority: WorkItemPriority {
        .medium
    }

    init(
        groupID: MLSGroupID,
        mlsService: any MLSServiceInterface,
        conversationLocalStore: any ConversationLocalStoreProtocol
    ) {
        self.groupID = groupID
        self.mlsService = mlsService
        self.conversationLocalStore = conversationLocalStore
    }

    func start() async throws {
        let logAttributes: LogAttributes = [.mlsGroupID: groupID.safeForLoggingDescription] + LogAttributes.safePublic

        do {
            try await mlsService.wipeGroup(groupID)
            WireLogger.mls.info("wiped invalid MLS group", attributes: logAttributes)
        } catch {
            WireLogger.mls.warn(
                "failed to wipe invalid MLS group: \(String(describing: error))",
                attributes: logAttributes
            )
        }

        await conversationLocalStore.clearMLSGroupID(mlsGroupID: groupID)
    }
}
