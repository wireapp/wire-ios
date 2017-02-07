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

//////////////////////////
///
/// NewUnreadMessage
///
//////////////////////////

public final class NewUnreadMessagesChangeInfo : ObjectChangeInfo  {
    
    public convenience init(messages: [ZMConversationMessage]) {
        self.init(object: messages as NSObject)
    }
    
    public var messages : [ZMConversationMessage] {
        return object as? [ZMConversationMessage] ?? []
    }
    
}


@objc public protocol ZMNewUnreadMessagesObserver : NSObjectProtocol {
    func didReceiveNewUnreadMessages(_ changeInfo: NewUnreadMessagesChangeInfo)
}

extension NewUnreadMessagesChangeInfo {
    
    /// Adds a ZMNewUnreadMessagesObserver
    /// You must hold on to the token and use it to unregister
    @objc(addNewMessageObserver:)
    public static func add(observer: ZMNewUnreadMessagesObserver) -> NSObjectProtocol {
        return NotificationCenterObserverToken(name: .NewUnreadMessage)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.userInfo?["changeInfo"] as? NewUnreadMessagesChangeInfo
                else { return }
            observer.didReceiveNewUnreadMessages(changeInfo)
        }
    }
    
    @objc(removeNewMessageObserver:)
    public static func remove(observer: NSObjectProtocol) {
        guard let token = (observer as? NotificationCenterObserverToken)?.token else {
            NotificationCenter.default.removeObserver(observer, name: .NewUnreadMessage, object: nil)
            return
        }
        NotificationCenter.default.removeObserver(token, name: .NewUnreadMessage, object: nil)
    }
}



//////////////////////////
///
/// NewUnreadKnockMessage
///
//////////////////////////


@objc public final class NewUnreadKnockMessagesChangeInfo : ObjectChangeInfo {
    
    public convenience init(messages: [ZMConversationMessage]) {
        self.init(object: messages as NSObject)
    }
    
    public var messages : [ZMConversationMessage] {
        return object as? [ZMConversationMessage] ?? []
    }
}


@objc public protocol ZMNewUnreadKnocksObserver : NSObjectProtocol {
    func didReceiveNewUnreadKnockMessages(_ changeInfo: NewUnreadKnockMessagesChangeInfo)
}

extension NewUnreadKnockMessagesChangeInfo {

    /// Adds a ZMNewUnreadKnocksObserver
    /// You must hold on to the token and use it to unregister
    @objc(addNewKnockObserver:)
    public static func add(observer: ZMNewUnreadKnocksObserver) -> NSObjectProtocol {
        return NotificationCenterObserverToken(name: .NewUnreadKnock)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.userInfo?["changeInfo"] as? NewUnreadKnockMessagesChangeInfo
                else { return }
            observer.didReceiveNewUnreadKnockMessages(changeInfo)
        } 
    }
    
    @objc(removeNewKnockObserver:)
    public static func remove(observer: NSObjectProtocol) {
        guard let token = (observer as? NotificationCenterObserverToken)?.token else {
            NotificationCenter.default.removeObserver(observer, name: .NewUnreadKnock, object: nil)
            return
        }
        NotificationCenter.default.removeObserver(token, name: .NewUnreadKnock, object: nil)
    }
}



//////////////////////////
///
/// NewUnreadUndeliveredMessage
///
//////////////////////////


@objc public final class NewUnreadUnsentMessageChangeInfo : ObjectChangeInfo {
    
    public required convenience init(messages: [ZMConversationMessage]) {
        self.init(object: messages as NSObject)
    }
    
    public var messages : [ZMConversationMessage] {
        return  object as? [ZMConversationMessage] ?? []
    }
}



@objc public protocol ZMNewUnreadUnsentMessageObserver : NSObjectProtocol {
    func didReceiveNewUnreadUnsentMessages(_ changeInfo: NewUnreadUnsentMessageChangeInfo)
}

extension NewUnreadUnsentMessageChangeInfo {
    
    /// Adds a ZMNewUnreadUnsentMessageObserver
    /// You must hold on to the token and use it to unregister
    @objc(addNewUnreadUnsentMessageObserver:)
    public static func add(observer: ZMNewUnreadUnsentMessageObserver) -> NSObjectProtocol {
        return NotificationCenterObserverToken(name: .NewUnreadUnsentMessage)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.userInfo?["changeInfo"] as? NewUnreadUnsentMessageChangeInfo
                else { return }
            observer.didReceiveNewUnreadUnsentMessages(changeInfo)
        }
    }
    
    @objc(removeNewUnreadUnsentMessageObserver:)
    public static func remove(observer: NSObjectProtocol) {
        guard let token = (observer as? NotificationCenterObserverToken)?.token else {
            NotificationCenter.default.removeObserver(observer, name: .NewUnreadUnsentMessage, object: nil)
            return
        }
        NotificationCenter.default.removeObserver(token, name: .NewUnreadUnsentMessage, object: nil)
    }
}

