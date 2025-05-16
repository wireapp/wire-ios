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

import Combine
import WireConversationUI
import WireDataModel

final class SenderObserver: NSObject, UserObserving, SenderObserverProtocol {

    var observation: Any?

    var author: String?
    private let authorChangedSubject = PassthroughSubject<String, Never>()
    var authorChangedPublisher: AnyPublisher<String, Never> {
        authorChangedSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    init(
        messageID: Any,
        viewContext: NSManagedObjectContext
    ) {
        super.init()
        guard let messageID = messageID as? NSManagedObjectID else {
            return
        }
        viewContext.perform {
            let message = try! viewContext.existingObject(with: messageID) as! ZMMessage
            self.author = message.senderName
            if let sender = message.senderUser {
                self.observation = UserChangeInfo.add(observer: self, for: sender, context: viewContext)
            }
        }
    }

    func userDidChange(_ changeInfo: UserChangeInfo) {
        authorChangedSubject.send(changeInfo.user.name ?? "")
    }
}
