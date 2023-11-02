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
import WireSystem

public protocol LocalConversationRemovalUseCaseProtocol {
    func removeConversation(_ conversation: ZMConversation, syncContext: NSManagedObjectContext)
}

public class LocalConversationRemovalUseCase: LocalConversationRemovalUseCaseProtocol {

    public init() {}

    public func removeConversation(
        _ conversation: ZMConversation,
        syncContext: NSManagedObjectContext
    ) {
        precondition(syncContext.zm_isSyncContext, "use case should only be accessed on the sync context")

        conversation.isDeletedRemotely = true
        wipeMLSGroupIfNeeded(for: conversation, in: syncContext)
        syncContext.saveOrRollback()
    }

    func wipeMLSGroupIfNeeded(
        for conversation: ZMConversation,
        in context: NSManagedObjectContext
    ) {
        guard conversation.messageProtocol == .mls else {
            return
        }

        guard let groupID = conversation.mlsGroupID else {
            return WireLogger.mls.warn("failed to wipe conversation: missing group ID")
        }

        guard let mlsService = context.mlsService else {
            return WireLogger.mls.warn("failed to wipe conversation: missing `mlsService`")
        }

        mlsService.wipeGroup(groupID)
    }
}
