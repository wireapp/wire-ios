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
import WireDataModel

// sourcery: AutoMockable
/// Clear content of a conversation
public protocol ClearConversationContentUseCaseProtocol {
    func invoke() async
}

public struct ClearConversationContentUseCase: ClearConversationContentUseCaseProtocol {

    private var conversationID: WireDataModel.QualifiedID
    private var syncContext: NSManagedObjectContext

    init(conversationID: WireDataModel.QualifiedID, syncContext: NSManagedObjectContext) {
        self.conversationID = conversationID
        self.syncContext = syncContext
    }

    public func invoke() async {
        await syncContext.perform { [syncContext] in
            guard let conversation = ZMConversation.fetch(
                with: conversationID.uuid,
                domain: conversationID.domain,
                in: syncContext
            ) else {
                assertionFailure("conversation not found")
                return
            }

            let timestamp = conversation.lastServerTimeStamp
            conversation.clearedTimeStamp = timestamp
            conversation.deleteOlderMessages() // this deletes all messages
            conversation.lastReadServerTimeStamp = timestamp
            syncContext.saveOrRollback()
        }

        let object = syncContext.notificationContext
        await MainActor.run {
            NotificationCenter.default.post(
                name: .clearContentNotification,
                object: object
            )
        }
    }
}
