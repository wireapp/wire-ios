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

extension ZMConversation : ObjectInSnapshot {
    
    @objc public static var observableKeys : Set<String> {
        return Set([#keyPath(ZMConversation.messages),
                    #keyPath(ZMConversation.lastModifiedDate),
                    #keyPath(ZMConversation.isArchived),
                    #keyPath(ZMConversation.conversationListIndicator),
                    #keyPath(ZMConversation.isSilenced),
                    #keyPath(ZMConversation.securityLevel),
                    #keyPath(ZMConversation.displayName),
                    #keyPath(ZMConversation.estimatedUnreadCount),
                    #keyPath(ZMConversation.clearedTimeStamp),
                    #keyPath(ZMConversation.lastServerSyncedActiveParticipants),
                    #keyPath(ZMConversation.isSelfAnActiveMember),
                    #keyPath(ZMConversation.relatedConnectionState),
                    #keyPath(ZMConversation.team),
                    #keyPath(ZMConversation.accessModeStrings),
                    #keyPath(ZMConversation.accessRoleString),
                    #keyPath(ZMConversation.remoteIdentifier),
                    #keyPath(ZMConversation.localMessageDestructionTimeout),
                    #keyPath(ZMConversation.syncedMessageDestructionTimeout),
                    #keyPath(ZMConversation.language)
            ])
    }

    public var notificationName: Notification.Name {
        return .ConversationChange
    }

}


////////////////////
////
//// ConversationObserverToken
//// This can be used for observing only conversation properties
////
////////////////////


@objcMembers public final class ConversationChangeInfo : ObjectChangeInfo {

    public var languageChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.language))
    }

    public var messagesChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.messages))
    }

    public var participantsChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.lastServerSyncedActiveParticipants), #keyPath(ZMConversation.isSelfAnActiveMember))
    }

    public var nameChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.displayName), #keyPath(ZMConversation.userDefinedName))
    }

    public var lastModifiedDateChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.lastModifiedDate))
    }

    public var unreadCountChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.estimatedUnreadCount))
    }

    public var connectionStateChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.relatedConnectionState))
    }

    public var isArchivedChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isArchived))
    }

    public var isSilencedChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isSilenced))
    }

    public var conversationListIndicatorChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.conversationListIndicator))
    }

    public var clearedChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.clearedTimeStamp))
    }

    public var teamChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.team))
    }

    public var securityLevelChanged : Bool {
        return changedKeysContain(keys: SecurityLevelKey)
    }
        
    public var createdRemotelyChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.remoteIdentifier))
    }
    
    public var allowGuestsChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.accessModeStrings)) ||
               changedKeysContain(keys: #keyPath(ZMConversation.accessRoleString))
    }
    
    public var destructionTimeoutChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.localMessageDestructionTimeout)) ||
                changedKeysContain(keys: #keyPath(ZMConversation.syncedMessageDestructionTimeout))
    }
    
    public var conversation : ZMConversation { return self.object as! ZMConversation }
    
    public override var description : String { return self.debugDescription }
    public override var debugDescription : String {
        return "messagesChanged: \(messagesChanged)," +
        "participantsChanged: \(participantsChanged)," +
        "nameChanged: \(nameChanged)," +
        "unreadCountChanged: \(unreadCountChanged)," +
        "lastModifiedDateChanged: \(lastModifiedDateChanged)," +
        "connectionStateChanged: \(connectionStateChanged)," +
        "isArchivedChanged: \(isArchivedChanged)," +
        "isSilencedChanged: \(isSilencedChanged)," +
        "conversationListIndicatorChanged \(conversationListIndicatorChanged)," +
        "clearedChanged \(clearedChanged)," +
        "securityLevelChanged \(securityLevelChanged)," +
        "teamChanged \(teamChanged)" +
        "createdRemotelyChanged \(createdRemotelyChanged)" +
        "destructionTimeoutChanged \(destructionTimeoutChanged)" +
        "languageChanged \(languageChanged)"
    }
    
    public required init(object: NSObject) {
        super.init(object: object)
    }
    
    static func changeInfo(for conversation: ZMConversation, changes: Changes) -> ConversationChangeInfo? {
        guard changes.changedKeys.count > 0 || changes.originalChanges.count > 0 else { return nil }
        let changeInfo = ConversationChangeInfo(object: conversation)
        changeInfo.changeInfos = changes.originalChanges
        changeInfo.changedKeys = changes.changedKeys
        return changeInfo
    }
}

@objc public protocol ZMConversationObserver : NSObjectProtocol {
    func conversationDidChange(_ changeInfo: ConversationChangeInfo)
}


extension ConversationChangeInfo {

    /// Adds a ZMConversationObserver to the specified conversation
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forConversation:)
    public static func add(observer: ZMConversationObserver, for conversation: ZMConversation) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .ConversationChange,
                                          managedObjectContext: conversation.managedObjectContext!,
                                          object: conversation)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? ConversationChangeInfo
                else { return }
            
            observer.conversationDidChange(changeInfo)
        } 
    }
}


/// Conversation degraded
extension ConversationChangeInfo {
    
    /// True if the conversation security level is .secureWithIgnored and we tried to send a message
    @objc public var didNotSendMessagesBecauseOfConversationSecurityLevel : Bool {
        return self.securityLevelChanged &&
            self.conversation.securityLevel == .secureWithIgnored &&
            !self.conversation.messagesThatCausedSecurityLevelDegradation.isEmpty
    }
    
    /// Users that caused the conversation to degrade
    @objc public var usersThatCausedConversationToDegrade : Set<ZMUser> {
        guard let activeParticipants = self.conversation.activeParticipants.array as? [ZMUser] else {
            return []
        }
        
        let untrustedParticipants = activeParticipants.filter { user -> Bool in
            return !user.trusted()
        }
        return Set(untrustedParticipants)
    }
}
