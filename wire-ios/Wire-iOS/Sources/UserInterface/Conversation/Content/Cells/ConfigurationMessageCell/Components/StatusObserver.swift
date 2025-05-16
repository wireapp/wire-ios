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

final class StatusObserver: NSObject, ZMMessageObserver, StatusObserverProtocol {

    var observation: Any?

    private let statusChangedSubject = PassthroughSubject<MessageModel, Never>()
    var statusChangedPublisher: AnyPublisher<MessageModel, Never> {
        statusChangedSubject
            .removeDuplicates()
//            .debounce(for: .seconds(1), scheduler: RunLoop.main)
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
            self.send(message)
            self.observation = MessageChangeInfo
                .add(observer: self, for: message, context: viewContext)
        }
    }

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        send(changeInfo.message)
    }

    private func send(_ message: ZMMessage) {
        let uiMessage = message.toUIModel()
        statusChangedSubject.send(uiMessage)
    }
}
