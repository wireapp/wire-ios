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

extension ZMConversationMessageWindow {
    
    func toOrderedSet() -> OrderedSet<NSObject> {
        let messages = self.messages.array as! [NSObject]
        return OrderedSet(array: messages)
    }
    
}



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
    
    private var state : SetSnapshot
    private var conversationToken : ConversationObserverToken?
    
    public let conversationWindow : ZMConversationMessageWindow
    public weak var observer : ZMConversationMessageWindowObserver?
    
    
    private var shouldRecalculate : Bool = false
    private var updatedMessages : [ZMMessage] = []
    private var messageChangeInfos : [MessageChangeInfo] = []
    private var messageTokens: [ZMMessage : MessageObserverToken] = [:]
    
    public var isTornDown : Bool = false

    private var currentlyFetchingMessages = false
    
    public init(window: ZMConversationMessageWindow, observer: ZMConversationMessageWindowObserver?) {
        
        self.conversationWindow = window
        self.observer = observer
        self.state = SetSnapshot(set: conversationWindow.toOrderedSet(), moveType: .UICollectionView)
        
        super.init()
        
        self.conversationToken = window.conversation.addConversationObserver(self) as? ConversationObserverToken
        self.registerObserversForMessages(OrderedSet<ZMMessage>(orderedSet: window.messages).set())
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessageWindowChangeToken.windowDidScroll(_:)), name: ZMConversationMessageWindowScrolledNotificationName, object: self.conversationWindow)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessageWindowChangeToken.messagesWillStartFetching(_:)), name: ZMConversationWillStartFetchingMessages, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessageWindowChangeToken.messagesDidStopFetching(_:)), name: ZMConversationDidFinishFetchingMessages, object: nil)

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
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ZMConversationDidFinishFetchingMessages, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ZMConversationWillStartFetchingMessages, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ZMConversationMessageWindowScrolledNotificationName, object: self.conversationWindow)
        self.tearDown()
    }
    
    public func windowDidScroll(note: NSNotification) {
        self.computeChanges()
    }
    
    func notifyMessageFetchingState(state: Bool, toObserver observer: ZMConversationMessageWindowObserver) {
        let changeInfo = MessageWindowChangeInfo(windowWithMissingMessagesChanged: self.conversationWindow, isFetching: state)
        self.conversationWindow.conversation.managedObjectContext?.performGroupedBlock({ () -> Void in
            observer.conversationWindowDidChange(changeInfo)
        })

    }
    
    public func messagesWillStartFetching(note: NSNotification) {
        guard let userInfo = note.userInfo,
                  conversationWatched = userInfo[ZMNotificationConversationKey] as? ZMConversation
            where conversationWatched.objectID == self.conversationWindow.conversation.objectID else {
                return
        }
        if (!self.currentlyFetchingMessages) {
            self.currentlyFetchingMessages = true
            if let observer = self.observer {
                self.notifyMessageFetchingState(self.currentlyFetchingMessages, toObserver: observer)
            }
        }
    }
    
    public func messagesDidStopFetching(note: NSNotification) {
        guard let userInfo = note.userInfo,
            let conversationWatched = userInfo[ZMNotificationConversationKey] as? ZMConversation where
            conversationWatched.objectID == self.conversationWindow.conversation.objectID
            else { return }
        
        if (self.currentlyFetchingMessages) {
            self.currentlyFetchingMessages = false
            if let observer = self.observer {
                self.notifyMessageFetchingState(self.currentlyFetchingMessages, toObserver: observer)
            }
        }
    }
    
    public func objectsDidChange(changes: ManagedObjectChanges) {
        if(self.shouldRecalculate || self.updatedMessages.count > 0) {
            self.computeChanges()
        }
    }
    
    public func conversationDidChange(changeInfo: ConversationChangeInfo) {
        if(changeInfo.messagesChanged || changeInfo.clearedChanged) {
            self.shouldRecalculate = true
        }
    }
    
    public func computeChanges() {
        let currentlyUpdatedMessaged = self.updatedMessages
        
        self.updatedMessages = []
        self.shouldRecalculate = false
        
        let updatedSet = OrderedSet<NSObject>(array: currentlyUpdatedMessaged.filter {(msg : ZMConversationMessage) in return msg.conversation === self.conversationWindow.conversation})
        
        conversationWindow.recalculateMessages()
        
        if let newStateUpdate = self.state.updatedState(updatedSet, observedObject: self.conversationWindow, newSet: self.conversationWindow.toOrderedSet()) {
            self.state = newStateUpdate.newSnapshot
            self.observer?.conversationWindowDidChange(MessageWindowChangeInfo(setChangeInfo: newStateUpdate.changeInfo))
            
            let a = newStateUpdate.insertedObjects.set() as! Set<ZMMessage>
            self.registerObserversForMessages(a)
            let b = newStateUpdate.removedObjects.set() as! Set<ZMMessage>
            self.removeObserverForMessages(b)
        }
        
        if self.messageChangeInfos.count > 0 {
            self.observer?.messagesInsideWindowDidChange?(self.messageChangeInfos)
        }
        
        self.messageChangeInfos = []
    }
    
    private func registerObserversForMessages(messages: Set<ZMMessage>) {
        for message in messages {
            self.messageTokens[message] = ZMMessageNotification.addMessageObserver(self, forMessage: message) as? MessageObserverToken
        }
    }
    
    private func removeObserverForMessages(messages: Set<ZMMessage>) {
        for message in messages {
            (self.messageTokens[message])?.tearDown()
            self.messageTokens.removeValueForKey(message)
        }
    }

    public func messageDidChange(change: MessageChangeInfo) {
        self.updatedMessages.append(change.message)
        self.messageChangeInfos.append(change)
    }
}

