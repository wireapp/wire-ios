//
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
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import Foundation

@objc public final class MessageWindowChangeInfo : SetChangeInfo {
    
    public var conversationMessageWindow : ZMConversationMessageWindow { return self.observedObject as! ZMConversationMessageWindow }
    public var isFetchingMessagesChanged = false
    public var isFetchingMessages = false
    
    init(setChangeInfo: SetChangeInfo) {
        super.init(observedObject: setChangeInfo.observedObject, changeSet: setChangeInfo.changeSet)
    }
    convenience init(windowWithMissingMessagesChanged window: ZMConversationMessageWindow, isFetching: Bool) {
        self.init(setChangeInfo: SetChangeInfo(observedObject: window))
        self.isFetchingMessages = isFetching
        self.isFetchingMessagesChanged = true
        
    }
}

@objc public final class MessageWindowChangeToken: NSObject, ObjectsDidChangeDelegate, ZMMessageObserver, ZMConversationObserver {
    
    fileprivate var state : SetSnapshot
    fileprivate var conversationToken : ConversationObserverToken?
    
    public let conversationWindow : ZMConversationMessageWindow
    public weak var observer : ZMConversationMessageWindowObserver?
    
    
    fileprivate var shouldRecalculate : Bool = false
    fileprivate var updatedMessages : [ZMMessage] = []
    fileprivate var messageChangeInfos : [MessageChangeInfo] = []
    fileprivate var messageTokens: [ZMMessage : MessageObserverToken] = [:]
    
    public var isTornDown : Bool = false

    fileprivate var currentlyFetchingMessages = false
    
    public init(window: ZMConversationMessageWindow, observer: ZMConversationMessageWindowObserver?) {
        
        self.conversationWindow = window
        self.observer = observer
        self.state = SetSnapshot(set: conversationWindow.messages, moveType: .uiCollectionView)
        
        super.init()
        
        self.conversationToken = window.conversation.add(self) as? ConversationObserverToken
        self.registerObserversForMessages(window.messages)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MessageWindowChangeToken.windowDidScroll(_:)), name: NSNotification.Name(rawValue: ZMConversationMessageWindowScrolledNotificationName), object: self.conversationWindow)

    }
    
    public func tearDown() {
        self.conversationToken?.tearDown()
        self.conversationToken = nil
        for token in Array(self.messageTokens.values) {
            token.tearDown()
        }
        self.messageTokens = [:]
        self.updatedMessages = []
        isTornDown = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ZMConversationMessageWindowScrolledNotificationName), object: self.conversationWindow)
        self.tearDown()
    }
    
    public func windowDidScroll(_ note: Notification) {
        self.computeChanges()
    }
    
    public func objectsDidChange(_ changes: ManagedObjectChanges) {
        if(self.shouldRecalculate || self.updatedMessages.count > 0) {
            self.computeChanges()
        }
    }
    
    public func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        if(changeInfo.messagesChanged || changeInfo.clearedChanged) {
            self.shouldRecalculate = true
        }
    }
    
    public func computeChanges() {
        let currentlyUpdatedMessages = self.updatedMessages
        
        self.updatedMessages = []
        self.shouldRecalculate = false
        
        let updatedSet = NSOrderedSet(array: currentlyUpdatedMessages.filter({
            $0.conversation === self.conversationWindow.conversation}))
        
        conversationWindow.recalculateMessages()
        
        if let newStateUpdate = self.state.updatedState(updatedSet, observedObject: self.conversationWindow, newSet: self.conversationWindow.messages) {
            self.state = newStateUpdate.newSnapshot
            self.observer?.conversationWindowDidChange(MessageWindowChangeInfo(setChangeInfo: newStateUpdate.changeInfo))
            
            let a = newStateUpdate.insertedObjects
            self.registerObserversForMessages(a)
            let b = newStateUpdate.removedObjects
            self.removeObserverForMessages(b)
        }
        
        if self.messageChangeInfos.count > 0 {
            self.observer?.messages?(insideWindowDidChange: self.messageChangeInfos)
        }
        
        self.messageChangeInfos = []
    }
    
    fileprivate func registerObserversForMessages(_ messages: NSOrderedSet) {
        messages.forEach{
            guard let message = $0 as? ZMMessage, message.managedObjectContext != nil else {return }
            self.messageTokens[message] = ZMMessageNotification.add(self, for: message) as? MessageObserverToken
        }
    }
    
    fileprivate func removeObserverForMessages(_ messages: NSOrderedSet) {
        messages.forEach{
            guard let message = $0 as? ZMMessage else {return }
            (self.messageTokens[message])?.tearDown()
            self.messageTokens.removeValue(forKey: message)
        }
    }

    public func messageDidChange(_ change: MessageChangeInfo) {
        self.updatedMessages.append(change.message)
        self.messageChangeInfos.append(change)
    }
}

