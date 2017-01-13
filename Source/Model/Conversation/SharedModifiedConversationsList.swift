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


private let zmLog = ZMSLog(tag: "modified conversations")


/// This class is used to mark conversations as modified in an extension 
/// context in order to refetch them in the main application.
@objc public class SharedModifiedConversationsList: NSObject {

    private let defaults = UserDefaults.shared()
    private let modifiedKey = "modifiedConversations"

    public func add(_ conversation: ZMConversation) {
        guard let identifier = conversation.remoteIdentifier else { return }
        let identifiers = storedIdentifiers + [identifier]
        let identifiersAsString = identifiers.map { $0.uuidString }
        defaults?.set(Array(identifiersAsString), forKey: modifiedKey)
    }

    public func clear() {
        defaults?.set(nil, forKey: modifiedKey)
    }

    public var storedIdentifiers: Set<UUID> {
        let stored = defaults?.object(forKey: modifiedKey) as? [String]
        if let identifiers = stored?.flatMap(UUID.init) {
            return Set(identifiers)
        }
        return []
    }

}


public extension NSManagedObjectContext {

    @objc(notifyMessagesChangedInConversationWithRemoteIdentifiers:)
    public func notifyMessagesChanged(with identifiers: Set<UUID>) {
        guard !identifiers.isEmpty else { return zmLog.warn("Call made to notify without remote identifiers") }
        let conversations = ZMConversation.fetchObjects(withRemoteIdentifiers: NSOrderedSet(set: identifiers), in: self)?.array as? [ZMConversation]

        conversations?.forEach { conversation in
            refresh(conversation, mergeChanges: true)
        }

        if zm_isUserInterfaceContext {
            conversations?.forEach {
                // When notifying the last message changed, the message window will be
                // recalculated and a notification about a potentially added message will be fired.
                guard let message = $0.messages.lastObject as? ZMMessage else { return }
                globalManagedObjectContextObserver.notifyNonCoreDataChangeInManagedObject(message)
            }
        }
    }

}
