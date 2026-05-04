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

// sourcery: AutoMockable
/// Sync conversation cells state with backend since we don't receive an event for it (yet)
public protocol SyncCellsStateUseCaseProtocol {
    func invoke(
        conversationObjectID: NSManagedObjectID
    ) async throws -> CellsState
}

public struct SyncCellsStateUseCase: SyncCellsStateUseCaseProtocol {
    private let repository: any ConversationRepositoryProtocol
    private let context: NSManagedObjectContext
    private let localDomain: String?

    public init(
        repository: any ConversationRepositoryProtocol,
        context: NSManagedObjectContext,
        localDomain: String?
    ) {
        self.repository = repository
        self.context = context
        self.localDomain = localDomain
    }

    public func invoke(
        conversationObjectID: NSManagedObjectID
    ) async throws -> CellsState {

        typealias ConversationInfo = (
            conversation: ZMConversation?,
            id: UUID?,
            domain: String?
        )

        let conversationInfo: ConversationInfo = try await context.perform { [context] in
            let conversation = try context.existingObject(
                with: conversationObjectID
            ) as? ZMConversation

            return (
                conversation,
                conversation?.remoteIdentifier,
                conversation?.domain ?? localDomain
            )
        }

        guard let conversation = conversationInfo.conversation,
              let conversationID = conversationInfo.id,
              let conversationDomain = conversationInfo.domain else {
            assertionFailure("could not find conversation locally")
            return .pending
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
