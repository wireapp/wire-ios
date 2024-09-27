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
import WireSystem

// MARK: - RemoveLocalConversationUseCaseProtocol

public protocol RemoveLocalConversationUseCaseProtocol {
    func invoke(with conversation: ZMConversation, syncContext: NSManagedObjectContext) async throws
}

// MARK: - RemoveLocalConversationUseCase

public class RemoveLocalConversationUseCase: RemoveLocalConversationUseCaseProtocol {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func invoke(
        with conversation: ZMConversation,
        syncContext: NSManagedObjectContext
    ) async throws {
        let isSyncContext = await syncContext.perform { syncContext.zm_isSyncContext }
        precondition(isSyncContext, "use case should only be accessed on the sync context")

        await syncContext.perform { conversation.isDeletedRemotely = true }
        try await wipeMLSGroupIfNeeded(for: conversation, in: syncContext)
        await syncContext.perform { _ = syncContext.saveOrRollback() }
    }

    // MARK: Internal

    func wipeMLSGroupIfNeeded(
        for conversation: ZMConversation,
        in context: NSManagedObjectContext
    ) async throws {
        let (mlsService, groupID) = await context.perform {
            guard conversation.messageProtocol == .mls else {
                return (MLSServiceInterface?.none, MLSGroupID?.none)
            }
            return (context.mlsService, conversation.mlsGroupID)
        }

        guard let groupID else {
            return WireLogger.mls.warn("failed to wipe conversation: missing group ID")
        }

        guard let mlsService else {
            return WireLogger.mls.warn("failed to wipe conversation: missing `mlsService`")
        }

        try await mlsService.wipeGroup(groupID)
    }
}
