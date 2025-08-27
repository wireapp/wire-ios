//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
/// Sync conversation cells state with backend since we don't receive an event for it (yet)
public protocol SyncCellsStateUseCaseProtocol {
    func invoke(
        conversation: ZMConversation
    ) async throws -> CellsState
}

public struct SyncCellsStateUseCase: SyncCellsStateUseCaseProtocol {
    private let repository: any ConversationRepositoryProtocol
    private let context: NSManagedObjectContext
    
    public init(
        repository: any ConversationRepositoryProtocol,
        context: NSManagedObjectContext
    ) {
        self.repository = repository
        self.context = context
    }

    public func invoke(
        conversation: ZMConversation
    ) async throws -> CellsState {
        let (conversationID, conversationDomain): (UUID, String?) = await context.perform {
            (conversation.remoteIdentifier, conversation.domain ?? BackendInfo.domain)
        }
        
        guard let conversationDomain else {
            assertionFailure("conversation should have a domain")
            return .disabled
        }

        // sync conversation with backend
        try await repository.pullConversation(
            id: conversationID,
            domain: conversationDomain
        )
        
        return await context.perform {
            conversation.cellsState
        }
        
    }

}
