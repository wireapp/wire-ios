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

extension ZMConversation: ObjectInSnapshot {
    @objc public static var observableKeys: Set<String> {
        [
            #keyPath(ZMConversation.allMessages),
            #keyPath(ZMConversation.lastModifiedDate),
            #keyPath(ZMConversation.isArchived),
            #keyPath(ZMConversation.conversationListIndicator),
            #keyPath(ZMConversation.mutedStatus),
            #keyPath(ZMConversation.securityLevel),
            #keyPath(ZMConversation.displayName),
            #keyPath(ZMConversation.estimatedUnreadCount),
            #keyPath(ZMConversation.clearedTimeStamp),
            #keyPath(ZMConversation.localParticipantRoles),
            #keyPath(ZMConversation.isSelfAnActiveMember),
            #keyPath(ZMConversation.relatedConnectionState),
            #keyPath(ZMConversation.team),
            #keyPath(ZMConversation.accessModeStrings),
            #keyPath(ZMConversation.accessRoleString),
            #keyPath(ZMConversation.accessRoleStringsV2),
            #keyPath(ZMConversation.remoteIdentifier),
            #keyPath(ZMConversation.localMessageDestructionTimeout),
            #keyPath(ZMConversation.syncedMessageDestructionTimeout),
            #keyPath(ZMConversation.language),
            #keyPath(ZMConversation.hasReadReceiptsEnabled),
            ZMConversation.externalParticipantsStateKey,
            #keyPath(ZMConversation.legalHoldStatus),
            #keyPath(ZMConversation.labels),
            #keyPath(ZMConversation.localParticipants),
            ZMConversation.mlsStatusKey,
            ZMConversation.mlsVerificationStatusKey,
            #keyPath(ZMConversation.isDeletedRemotely),
            ZMConversation.messageProtocolKey,
            #keyPath(ZMConversation.oneOnOneUser),
        ]
    }

    public var notificationName: Notification.Name {
        .ConversationChange
    }
}

////////////////////
////
//// ConversationObserverToken
//// This can be used for observing only conversation properties
////
////////////////////

@objcMembers
public final class ConversationChangeInfo: ObjectChangeInfo {
    public var isDeletedChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.isDeletedRemotely))
    }

    public var languageChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.language))
    }

    public var messagesChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.allMessages))
    }

    public var participantsChanged: Bool {
        changedKeysContain(
            keys: #keyPath(ZMConversation.localParticipantRoles),
            #keyPath(ZMConversation.isSelfAnActiveMember),
            #keyPath(ZMConversation.participantRoles)
        )
    }

    public var activeParticipantsChanged: Bool {
        changedKeysContain(
            keys: #keyPath(ZMConversation.isSelfAnActiveMember),
            #keyPath(ZMConversation.localParticipants)
        )
    }

    public var nameChanged: Bool {
        changedKeysContain(
            keys: #keyPath(ZMConversation.displayName),
            #keyPath(ZMConversation.userDefinedName)
        ) || activeParticipantsChanged
    }

    public var lastModifiedDateChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.lastModifiedDate))
    }

    public var unreadCountChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.estimatedUnreadCount))
    }

    public var connectionStateChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.relatedConnectionState))
    }

    public var isArchivedChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.isArchived))
    }

    public var mutedMessageTypesChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.mutedStatus))
    }

    public var conversationListIndicatorChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.conversationListIndicator))
    }

    public var clearedChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.clearedTimeStamp))
    }

    public var teamChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.team))
    }

    public var securityLevelChanged: Bool {
        changedKeysContain(keys: SecurityLevelKey)
    }

    public var mlsVerificationStatusChanged: Bool {
        changedKeysContain(keys: ZMConversation.mlsVerificationStatusKey)
    }

    public var allowGuestsChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.accessModeStrings)) ||
            changedKeysContain(keys: #keyPath(ZMConversation.accessRoleString)) ||
            changedKeysContain(keys: #keyPath(ZMConversation.accessRoleStringsV2))
    }

    public var allowServicesChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.accessRoleStringsV2))
    }

    public var destructionTimeoutChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.localMessageDestructionTimeout)) ||
            changedKeysContain(keys: #keyPath(ZMConversation.syncedMessageDestructionTimeout))
    }

    public var hasReadReceiptsEnabledChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.hasReadReceiptsEnabled))
    }

    public var externalParticipantsStateChanged: Bool {
        changedKeysContain(keys: ZMConversation.externalParticipantsStateKey)
    }

    public var legalHoldStatusChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.legalHoldStatus))
    }

    public var labelsChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.labels))
    }

    public var mlsStatusChanged: Bool {
        changedKeysContain(keys: ZMConversation.mlsStatusKey)
    }

    public var messageProtocolChanged: Bool {
        changedKeysContain(keys: ZMConversation.messageProtocolKey)
    }

    public var oneOnOneUserChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMConversation.oneOnOneUser))
    }

    public var conversation: ZMConversation {
        object as! ZMConversation
    }

    override public var description: String {
        debugDescription
    }

    override public var debugDescription: String {
        [
            "allMessagesChanged: \(messagesChanged)",
            "participantsChanged: \(participantsChanged)",
            "activeParticipantsChanged: \(activeParticipantsChanged)",
            "nameChanged: \(nameChanged)",
            "unreadCountChanged: \(unreadCountChanged)",
            "lastModifiedDateChanged: \(lastModifiedDateChanged)",
            "connectionStateChanged: \(connectionStateChanged)",
            "isArchivedChanged: \(isArchivedChanged)",
            "mutedMessageTypesChanged: \(mutedMessageTypesChanged)",
            "conversationListIndicatorChanged \(conversationListIndicatorChanged)",
            "clearedChanged \(clearedChanged)",
            "securityLevelChanged \(securityLevelChanged)",
            "teamChanged \(teamChanged)",
            "destructionTimeoutChanged \(destructionTimeoutChanged)",
            "languageChanged \(languageChanged)",
            "hasReadReceiptsEnabledChanged \(hasReadReceiptsEnabledChanged)",
            "externalParticipantsStateChanged \(externalParticipantsStateChanged)",
            "legalHoldStatusChanged: \(legalHoldStatusChanged)",
            "labelsChanged: \(labelsChanged)",
            "mlsStatusChanged: \(mlsStatusChanged)",
            "messageProtocolChanged: \(messageProtocolChanged)",
            "oneOnOneUserChanged: \(oneOnOneUserChanged)",
        ].joined(separator: ", ")
    }

    public required init(object: NSObject) {
        super.init(object: object)
    }

    static func changeInfo(for conversation: ZMConversation, changes: Changes) -> ConversationChangeInfo? {
        ConversationChangeInfo(object: conversation, changes: changes)
    }
}

@objc
public protocol ZMConversationObserver: NSObjectProtocol {
    func conversationDidChange(_ changeInfo: ConversationChangeInfo)
}

extension ConversationChangeInfo {
    /// Adds a ZMConversationObserver to the specified conversation
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forConversation:)
    public static func add(observer: ZMConversationObserver, for conversation: ZMConversation) -> NSObjectProtocol {
        ManagedObjectObserverToken(
            name: .ConversationChange,
            managedObjectContext: conversation.managedObjectContext!,
            object: conversation
        ) { [weak observer] note in
            guard let observer,
                  let changeInfo = note.changeInfo as? ConversationChangeInfo
            else { return }

            observer.conversationDidChange(changeInfo)
        }
    }
}

/// Conversation degraded
extension ConversationChangeInfo {
    @objc public var causedByConversationPrivacyChange: Bool {
        if mlsVerificationStatusChanged {
            return conversation.mlsVerificationStatus == .degraded && !conversation
                .messagesThatCausedSecurityLevelDegradation.isEmpty
        } else if securityLevelChanged {
            return conversation.securityLevel == .secureWithIgnored && !conversation
                .messagesThatCausedSecurityLevelDegradation.isEmpty
        } else if legalHoldStatusChanged {
            return conversation.legalHoldStatus == .pendingApproval && !conversation
                .messagesThatCausedSecurityLevelDegradation.isEmpty
        }

        return false
    }

    /// Users that caused the conversation to degrade
    @objc public var usersThatCausedConversationToDegrade: Set<ZMUser> {
        let untrustedParticipants = conversation.localParticipants.filter { user -> Bool in
            !user.isTrusted
        }
        return Set(untrustedParticipants)
    }
}
