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
        super.init(observedObject: setChangeInfo.observedObject, changeSet: setChangeInfo.changeSet, orderedSetState: setChangeInfo.orderedSetState)
    }
    convenience init(windowWithMissingMessagesChanged window: ZMConversationMessageWindow, isFetching: Bool) {
        self.init(setChangeInfo: SetChangeInfo(observedObject: window))
        self.isFetchingMessages = isFetching
        self.isFetchingMessagesChanged = true
        
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
    public static func add(observer: ZMConversationMessageWindowObserver,for window: ZMConversationMessageWindow) -> NSObjectProtocol {
        return NotificationCenterObserverToken(name: .MessageWindowDidChange, object: window)
        { [weak observer] (note) in
            guard let `observer` = observer, let window = note.object as? ZMConversationMessageWindow else { return }
            if let changeInfo = note.userInfo?["messageWindowChangeInfo"] as? MessageWindowChangeInfo{
                observer.conversationWindowDidChange(changeInfo)
            }
            if let messageChangeInfos = note.userInfo?["messageChangeInfos"] as? [MessageChangeInfo] {
                observer.messagesInsideWindow?(window, didChange: messageChangeInfos)
            }
        } 
    }
    
    @objc(removeObserver:forWindow:)
    public static func remove(observer: NSObjectProtocol, for window: ZMConversationMessageWindow?) {
        guard let token = (observer as? NotificationCenterObserverToken)?.token else {
            NotificationCenter.default.removeObserver(observer, name: .MessageWindowDidChange, object: window)
            return
        }
        NotificationCenter.default.removeObserver(token, name: .MessageWindowDidChange, object: window)
    }
}
