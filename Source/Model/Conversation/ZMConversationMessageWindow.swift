//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public final class ZMConversationMessageWindow: NSObject {
    private(set) var size: UInt
    let mutableMessages: NSMutableOrderedSet
    @objc public let conversation: ZMConversation

    var activeSize: UInt {
        return min(size, UInt(conversation.messages.count))
    }

    @objc public var messages: NSOrderedSet {
        return mutableMessages.reversed
    }

    init(conversation: ZMConversation, size: UInt) {
        self.conversation = conversation
        self.size = size
        mutableMessages = NSMutableOrderedSet()

        super.init()

        // find first unread, offset size from there
        if let firstUnreadMessage = conversation.firstUnreadMessage {
            let firstUnreadIndex = UInt(conversation.messages.index(of: firstUnreadMessage))
            self.size = max(0, UInt(conversation.messages.count) - firstUnreadIndex + size)
        }

        recalculateMessages()
        conversation.managedObjectContext?.messageWindowObserverCenter.windowWasCreated(self)
    }

    deinit {
        if let zm_isValidContext = conversation.managedObjectContext?.zm_isValidContext,
           zm_isValidContext {
            conversation.managedObjectContext?.messageWindowObserverCenter.removeMessageWindow(self)
        }
    }

    @objc func recalculateMessages() {
        let messages = conversation.messages
        let numberOfMessages = Int(activeSize)
        let range = NSRange(location: messages.count - numberOfMessages, length: numberOfMessages)
        let newMessages = NSMutableOrderedSet(orderedSet: messages, range: range, copyItems: false)

        let filtered = newMessages.filter { message in
            guard let message = message as? ZMMessage else { return false }

            var filterResult: Bool = false
            if let _ = conversation.clearedTimeStamp {
                filterResult = message.shouldBeDisplayed && (message.deliveryState == .pending || message.serverTimestamp!.compare(self.conversation.clearedTimeStamp!) == .orderedDescending)
            } else {
                filterResult = message.shouldBeDisplayed
            }

            return filterResult && !message.isExpirationZombie
        }

        mutableMessages.removeAllObjects()
        mutableMessages.union(NSOrderedSet(array: filtered))
    }

    @objc public func moveUp(byMessages amountOfMessages: UInt) {
        let oldSize = activeSize
        size += amountOfMessages
        if oldSize != activeSize {
            recalculateMessages()
            conversation.managedObjectContext?.messageWindowObserverCenter.windowDidScroll(self)
        }
    }

    @objc public func moveDown(byMessages amountOfMessages: UInt) {
        let oldSize = activeSize
        size -= min(amountOfMessages, max(size, 1) - 1)
        if oldSize != activeSize {
            recalculateMessages()
        }
    }
}

extension ZMMessage {

    /// a message that should be destructed, but isObfuscated flag is false and it still exist in Core Date
    fileprivate var isExpirationZombie: Bool {
        guard let destructionDate = self.destructionDate else { return false }

        return destructionDate.timeIntervalSinceNow <= 0 && isObfuscated == false
    }
}

extension ZMConversation {
    @objc public func conversationWindow(withSize size: UInt) -> ZMConversationMessageWindow {
        return ZMConversationMessageWindow(conversation: self, size: size)
    }
}
