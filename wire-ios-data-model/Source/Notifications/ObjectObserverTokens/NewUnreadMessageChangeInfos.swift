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

// MARK: - NewUnreadMessagesChangeInfo

//////////////////////////
///
/// NewUnreadMessage
///
//////////////////////////

public final class NewUnreadMessagesChangeInfo: ObjectChangeInfo {
    // MARK: Lifecycle

    public convenience init(messages: [ZMConversationMessage]) {
        self.init(object: messages as NSObject)
    }

    // MARK: Public

    public var messages: [ZMConversationMessage] {
        object as? [ZMConversationMessage] ?? []
    }
}

// MARK: - ZMNewUnreadMessagesObserver

@objc
public protocol ZMNewUnreadMessagesObserver: NSObjectProtocol {
    func didReceiveNewUnreadMessages(_ changeInfo: NewUnreadMessagesChangeInfo)
}

extension NewUnreadMessagesChangeInfo {
    /// Adds a ZMNewUnreadMessagesObserver
    /// You must hold on to the token and use it to unregister
    @objc(addNewMessageObserver:forManagedObjectContext:)
    public static func add(
        observer: ZMNewUnreadMessagesObserver,
        managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        ManagedObjectObserverToken(
            name: .NewUnreadMessage,
            managedObjectContext: managedObjectContext
        ) { [weak observer] note in
            guard let observer,
                  let changeInfo = note.changeInfo as? NewUnreadMessagesChangeInfo
            else {
                return
            }
            observer.didReceiveNewUnreadMessages(changeInfo)
        }
    }
}

// MARK: - NewUnreadKnockMessagesChangeInfo

//////////////////////////
///
/// NewUnreadKnockMessage
///
//////////////////////////

@objc
public final class NewUnreadKnockMessagesChangeInfo: ObjectChangeInfo {
    // MARK: Lifecycle

    public convenience init(messages: [ZMConversationMessage]) {
        self.init(object: messages as NSObject)
    }

    // MARK: Public

    public var messages: [ZMConversationMessage] {
        object as? [ZMConversationMessage] ?? []
    }
}

// MARK: - ZMNewUnreadKnocksObserver

@objc
public protocol ZMNewUnreadKnocksObserver: NSObjectProtocol {
    func didReceiveNewUnreadKnockMessages(_ changeInfo: NewUnreadKnockMessagesChangeInfo)
}

extension NewUnreadKnockMessagesChangeInfo {
    /// Adds a ZMNewUnreadKnocksObserver
    /// You must hold on to the token and use it to unregister
    @objc(addNewKnockObserver:forManagedObjectContext:)
    public static func add(
        observer: ZMNewUnreadKnocksObserver,
        managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        ManagedObjectObserverToken(
            name: .NewUnreadKnock,
            managedObjectContext: managedObjectContext
        ) { [weak observer] note in
            guard let observer,
                  let changeInfo = note.changeInfo as? NewUnreadKnockMessagesChangeInfo
            else {
                return
            }
            observer.didReceiveNewUnreadKnockMessages(changeInfo)
        }
    }
}

// MARK: - NewUnreadUnsentMessageChangeInfo

//////////////////////////
///
/// NewUnreadUndeliveredMessage
///
//////////////////////////

@objc
public final class NewUnreadUnsentMessageChangeInfo: ObjectChangeInfo {
    // MARK: Lifecycle

    public required convenience init(messages: [ZMConversationMessage]) {
        self.init(object: messages as NSObject)
    }

    // MARK: Public

    public var messages: [ZMConversationMessage] {
        object as? [ZMConversationMessage] ?? []
    }
}

// MARK: - ZMNewUnreadUnsentMessageObserver

@objc
public protocol ZMNewUnreadUnsentMessageObserver: NSObjectProtocol {
    func didReceiveNewUnreadUnsentMessages(_ changeInfo: NewUnreadUnsentMessageChangeInfo)
}

extension NewUnreadUnsentMessageChangeInfo {
    /// Adds a ZMNewUnreadUnsentMessageObserver
    /// You must hold on to the token and use it to unregister
    @objc(addNewUnreadUnsentMessageObserver:forManagedObjectContext:)
    public static func add(
        observer: ZMNewUnreadUnsentMessageObserver,
        managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        ManagedObjectObserverToken(
            name: .NewUnreadUnsentMessage,
            managedObjectContext: managedObjectContext
        ) { [weak observer] note in
            guard let observer,
                  let changeInfo = note.changeInfo as? NewUnreadUnsentMessageChangeInfo
            else {
                return
            }
            observer.didReceiveNewUnreadUnsentMessages(changeInfo)
        }
    }
}
