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

import WireDataModel

// sourcery: AutoMockable
/// Facilitate access to message related domain objects.
public protocol MessageRepositoryProtocol {

    func addSystemMessage(
        messageType: SystemMessageType,
        conversationID: UUID,
        conversationDomain: String?
    ) async
}

public class MessageRepository: MessageRepositoryProtocol {

    // MARK: - Properties

    private let localStore: any MessageLocalStoreProtocol
    private let conversationRepository: any ConversationRepositoryProtocol

    // MARK: - Object lifecycle

    public init(
        localStore: any MessageLocalStoreProtocol,
        conversationRepository: any ConversationRepositoryProtocol
    ) {
        self.localStore = localStore
        self.conversationRepository = conversationRepository
    }

    public func addSystemMessage(
        messageType: SystemMessageType,
        conversationID: UUID,
        conversationDomain: String?
    ) async {
        await localStore.addSystemMessage(
            messageType: messageType,
            conversationID: conversationID,
            conversationDomain: conversationDomain
        )
    }

}
