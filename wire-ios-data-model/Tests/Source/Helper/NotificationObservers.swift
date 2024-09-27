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

// MARK: - ObserverType

protocol ObserverType: NSObjectProtocol {
    associatedtype ChangeInfo: ObjectChangeInfo
    var notifications: [ChangeInfo] { get set }
}

extension ObserverType {
    func clearNotifications() {
        notifications = []
    }
}

// MARK: - MockUserObserver

final class MockUserObserver: UserObserving {
    var notifications = [UserChangeInfo]()

    func clearNotifications() {
        notifications = []
    }

    func userDidChange(_ changeInfo: UserChangeInfo) {
        notifications.append(changeInfo)
    }
}

// MARK: - MessageObserver

class MessageObserver: NSObject, ZMMessageObserver {
    var token: NSObjectProtocol?

    override init() {}

    init(message: ZMMessage) {
        super.init()
        self.token = MessageChangeInfo.add(
            observer: self,
            for: message,
            managedObjectContext: message.managedObjectContext!
        )
    }

    var notifications: [MessageChangeInfo] = []

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        notifications.append(changeInfo)
    }
}

// MARK: - NewUnreadMessageObserver

class NewUnreadMessageObserver: NSObject, ZMNewUnreadMessagesObserver {
    var token: NSObjectProtocol?
    var notifications: [NewUnreadMessagesChangeInfo] = []

    override init() {}

    init(context: NSManagedObjectContext) {
        super.init()
        self.token = NewUnreadMessagesChangeInfo.add(observer: self, managedObjectContext: context)
    }

    func didReceiveNewUnreadMessages(_ changeInfo: NewUnreadMessagesChangeInfo) {
        notifications.append(changeInfo)
    }
}

// MARK: - ConversationObserver

final class ConversationObserver: NSObject, ZMConversationObserver {
    var token: NSObjectProtocol?

    func clearNotifications() {
        notifications = []
    }

    override init() {}

    init(conversation: ZMConversation) {
        super.init()
        self.token = ConversationChangeInfo.add(observer: self, for: conversation)
    }

    var notifications = [ConversationChangeInfo]()

    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        notifications.append(changeInfo)
    }
}

// MARK: - ConversationListChangeObserver

@objcMembers
class ConversationListChangeObserver: NSObject, ZMConversationListObserver {
    public var notifications = [ConversationListChangeInfo]()
    public var observerCallback: ((ConversationListChangeInfo) -> Void)?
    unowned var conversationList: ConversationList
    var token: NSObjectProtocol?

    init(conversationList: ConversationList, managedObjectContext: NSManagedObjectContext) {
        self.conversationList = conversationList
        super.init()
        self.token = ConversationListChangeInfo.addListObserver(
            self,
            for: conversationList,
            managedObjectContext: managedObjectContext
        )
    }

    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        notifications.append(changeInfo)
        if let callBack = observerCallback {
            callBack(changeInfo)
        }
    }
}
