// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import Foundation

//////////////////////////
///
/// NewUnreadMessage
///
//////////////////////////


public protocol MessageToken : ObjectsDidChangeDelegate {
}


public final class NewUnreadMessagesChangeInfo : NSObject  {
    
    public required init(messages: [ZMConversationMessage]) {
        self.messages = messages
    }
    
    public let messages : [ZMConversationMessage]
}


@objc public final class NewUnreadMessagesObserverToken: NSObject, MessageToken {

    private weak var observer : ZMNewUnreadMessagesObserver?
    
    public init(observer: ZMNewUnreadMessagesObserver) {
        self.observer = observer
    }
    
    public func objectsDidChange(changes: ManagedObjectChanges) {
        let inserted = (changes.inserted as! [ZMMessage]).filter {$0.isUnreadMessage && $0.knockMessageData == nil }
        if !inserted.isEmpty {
            let changeInfo = NewUnreadMessagesChangeInfo(messages: inserted)
            self.observer?.didReceiveNewUnreadMessages(changeInfo)
        }
    }
    
    public func tearDown() {

    }
}




//////////////////////////
///
/// NewUnreadKnockMessage
///
//////////////////////////


@objc public final class NewUnreadKnockMessagesChangeInfo : ObjectChangeInfo {
    
    public required init(object: NSObject) {
        self.messages = object as! [ZMConversationMessage]
        super.init(object: object)
    }
    
    public let messages : [ZMConversationMessage]
}


@objc public final class NewUnreadKnockMessagesObserverToken: NSObject, MessageToken {
    
    private weak var observer : ZMNewUnreadKnocksObserver?
    
    public init(observer: ZMNewUnreadKnocksObserver) {
        self.observer = observer
    }
    
    private func filterUnreadKnocks(array: [ZMMessage]) -> [ZMConversationMessage] {
        var unreadMessages = [ZMMessage]()
        
        for message in array where message.isUnreadMessage && message.knockMessageData != nil {
            unreadMessages.append(message)
        }
        
        return unreadMessages
    }
    
    public func objectsDidChange(changes: ManagedObjectChanges) {
        let insertedKnockMessages = filterUnreadKnocks(changes.inserted as! [ZMMessage]) + filterUnreadKnocks(changes.updated as! [ZMMessage])
        
        if !insertedKnockMessages.isEmpty {
            let changeInfo = NewUnreadKnockMessagesChangeInfo(object: insertedKnockMessages)
            self.observer?.didReceiveNewUnreadKnockMessages(changeInfo)
        }
    }
    
    public func tearDown() {
    }
}



//////////////////////////
///
/// NewUnreadUndeliveredMessage
///
//////////////////////////


@objc public final class NewUnreadUnsentMessageChangeInfo : ObjectChangeInfo {
    
    public required init(object: NSObject) {
        self.messages = object as! [ZMMessage]
        super.init(object: object)
    }
    
    public let messages : [ZMMessage]
}


@objc public final class NewUnreadUnsentMessageObserverToken: NSObject, MessageToken {
    
    private weak var observer : ZMNewUnreadUnsentMessageObserver?
    
    public init(observer: ZMNewUnreadUnsentMessageObserver) {
        self.observer = observer
    }
    
    private func filterUnsentMessage(array: [ZMMessage]) -> [ZMMessage] {
        return array.filter { $0.deliveryState == .FailedToSend }
    }
    
    public func objectsDidChange(changes: ManagedObjectChanges) {
        let unreadUnsentMessages = filterUnsentMessage(changes.updated as! [ZMMessage])
        
        if !unreadUnsentMessages.isEmpty {
            let changeInfo = NewUnreadUnsentMessageChangeInfo(object: unreadUnsentMessages)
            self.observer?.didReceiveNewUnreadUnsentMessages(changeInfo)
        }
    }
    
    public func tearDown() {
        // no op
    }
}


