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

@objc public final class MessageWindowChangeInfo: NSObject, SetChangeInfoOwner {
    
    public static let MessageWindowChangeUserInfoKey = "messageWindowChangeInfo"
    public static let MessageChangeUserInfoKey = "messageChangeInfos"
    
    public typealias ChangeInfoContent = ZMMessage
    public var setChangeInfo: SetChangeInfo<ZMMessage>
    
    public var conversationMessageWindow : ZMConversationMessageWindow { return setChangeInfo.observedObject as! ZMConversationMessageWindow }
    public var isFetchingMessagesChanged = false
    public var isFetchingMessages = false
    
    /// Set to true when there might be some changes that are not reflected in the change info and it's better to reload
    public var needsReload = false
    
    init(setChangeInfo: SetChangeInfo<ZMMessage>) {
        self.setChangeInfo = setChangeInfo
    }
    
    convenience init(windowWithMissingMessagesChanged window: ZMConversationMessageWindow, isFetching: Bool) {
        self.init(setChangeInfo: SetChangeInfo(observedObject: window))
        self.isFetchingMessages = isFetching
        self.isFetchingMessagesChanged = true
        
    }
    
    // Once everything is in Swift, we can also remove this and use a protocol extension
    public var orderedSetState : OrderedSetState<ChangeInfoContent> { return setChangeInfo.orderedSetState }
    public var insertedIndexes : IndexSet { return setChangeInfo.insertedIndexes }
    public var deletedIndexes : IndexSet { return setChangeInfo.deletedIndexes }
    public var deletedObjects: Set<AnyHashable> { return setChangeInfo.deletedObjects }
    public var updatedIndexes : IndexSet { return setChangeInfo.updatedIndexes }
    public var movedIndexPairs : [MovedIndex] { return setChangeInfo.movedIndexPairs }
    public var zm_movedIndexPairs : [ZMMovedIndex] { return setChangeInfo.zm_movedIndexPairs }
    public func enumerateMovedIndexes(_ block:@escaping (_ from: Int, _ to : Int) -> Void) {
        setChangeInfo.enumerateMovedIndexes(block)
    }
}


@objc public protocol ZMConversationMessageWindowObserver : NSObjectProtocol {
    func conversationWindowDidChange(_ changeInfo: MessageWindowChangeInfo)
    @objc optional func messagesInsideWindow(_ window: ZMConversationMessageWindow, didChange messageChangeInfos: [MessageChangeInfo])
}

extension MessageWindowChangeInfo {

    /// Adds a ZMConversationMessageWindowObserver to the specified window
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forWindow:)
    public static func add(observer: ZMConversationMessageWindowObserver, for window: ZMConversationMessageWindow) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .MessageWindowDidChange, managedObjectContext: window.conversation.managedObjectContext!, object: window)
        { [weak observer] (note) in
            guard let `observer` = observer, let window = note.object as? ZMConversationMessageWindow else { return }
            if let changeInfo = note.userInfo[self.MessageWindowChangeUserInfoKey] as? MessageWindowChangeInfo {
                observer.conversationWindowDidChange(changeInfo)
            }
            if let messageChangeInfos = note.userInfo[self.MessageChangeUserInfoKey] as? [MessageChangeInfo] {
                observer.messagesInsideWindow?(window, didChange: messageChangeInfos)
            }
        } 
    }
}
