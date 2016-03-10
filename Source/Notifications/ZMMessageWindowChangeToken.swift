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



@objc public class ZMMessageWindowChangeToken: NSObject {
    
    struct ZMMessageWindowChangeTokenStateUpdate {
        
        let newState : ZMMessageWindowChangeTokenState
        let notification : ZMConversationMessageWindowNotification
    }
    
    struct ZMMessageWindowChangeTokenState {
        
        let messages : OrderedSet<ZMMessage>
        
        init(messages: OrderedSet<ZMMessage>) {
            self.messages = messages
        }
        
        private func calculateChangeSet(newMessages: OrderedSet<ZMMessage>, updatedMessages: OrderedSet<ZMMessage>) -> ZMChangedIndexes {
            let startState = ZMOrderedSetState(orderedSet:self.messages.internalSet())
            let endState = ZMOrderedSetState(orderedSet:newMessages.internalSet())
            let updatedState = ZMOrderedSetState(orderedSet:updatedMessages.internalSet())
            
            #if os(iOS)
                let moveType : ZMSetChangeMoveType = .UICollectionView
                #else
                let moveType : ZMSetChangeMoveType = .NSTableView
            #endif
        
            return ZMChangedIndexes(startState:startState, endState:endState, updatedState:updatedState, moveType:moveType)
        }
        
        private func calculateMovedIndexes(changeSet: ZMChangedIndexes) -> [ZMMovedIndex] {
            var array : [ZMMovedIndex] = []
            changeSet.enumerateMovedIndexes  {(x: UInt, y: UInt) in array.append(ZMMovedIndex(from: x, to: y)) }
            return array
        }
        
        // Returns the new state and the notification to send after some changes in messages
        func updatedState(updatedMessages: OrderedSet<ZMMessage>, conversationWindow: ZMConversationMessageWindow) -> ZMMessageWindowChangeTokenStateUpdate? {
            let newMessages = OrderedSet<ZMMessage>(array: conversationWindow.messages.array as! [ZMMessage])
            if messages == newMessages && updatedMessages.count == 0 {
                return nil
            }
            
            let changeSet = self.calculateChangeSet(newMessages, updatedMessages: updatedMessages)
            let movedIndexes = self.calculateMovedIndexes(changeSet)
            
            let notification = ZMConversationMessageWindowNotification(conversationMessageWindow: conversationWindow, insertedIndexes: changeSet.insertedIndexes, deletedIndexes: changeSet.deletedIndexes, movedIndexPairs: movedIndexes, updatedIndexes: changeSet.updatedIndexes)
            assert(notification != nil)
            
            return ZMMessageWindowChangeTokenStateUpdate(newState: ZMMessageWindowChangeTokenState(messages: newMessages), notification: notification)
        }
    }
    
    private var state : ZMMessageWindowChangeTokenState
    
    public let conversationWindow : ZMConversationMessageWindow
    
    public weak var observer : ZMConversationMessageWindowObserver?
    
    public init(window: ZMConversationMessageWindow, observer: ZMConversationMessageWindowObserver?) {
        
        self.conversationWindow = window
        self.observer = observer
        self.state = ZMMessageWindowChangeTokenState(messages: OrderedSet<ZMMessage>(array: conversationWindow.messages.array as! [ZMMessage]))
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "windowDidScroll:", name: ZMConversationMessageWindowScrolledNotificationName, object: self.conversationWindow)
    }
    
    public func tearDown() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ZMConversationMessageWindowScrolledNotificationName, object: self.conversationWindow)
    }
    
    deinit {
        self.tearDown()
    }
    
    public func windowDidScroll(note: NSNotification) {
        self.conversationDidChange([])
    }
    
    public func conversationDidChange(updatedMessages: [ZMMessage]) {

        let updatedSet = OrderedSet<ZMMessage>(array: updatedMessages.filter {msg in return msg.conversation === self.conversationWindow.conversation})
        
        conversationWindow.recalculateMessages()
        
        if let newStateUpdate = self.state.updatedState(updatedSet, conversationWindow: self.conversationWindow) {
            self.state = newStateUpdate.newState
            if let anObserver = self.observer {
                anObserver.conversationWindowDidChange(newStateUpdate.notification)
            }
        }
    }
}

