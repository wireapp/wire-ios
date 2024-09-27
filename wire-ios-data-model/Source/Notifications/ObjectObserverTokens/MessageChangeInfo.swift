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

private var zmLog = ZMSLog(tag: "MessageChangeInfo")

// MARK: - MessageKey

enum MessageKey: String {
    case previewGenericMessage
    case mediumGenericMessage
    case linkPreview
    case underlyingMessage
}

// MARK: - ZMMessage + ObjectInSnapshot

extension ZMMessage: ObjectInSnapshot {
    @objc public class var observableKeys: Set<String> {
        [#keyPath(ZMMessage.deliveryState), #keyPath(ZMMessage.isObfuscated)]
    }

    public var notificationName: Notification.Name {
        .MessageChange
    }
}

extension ZMAssetClientMessage {
    override public class var observableKeys: Set<String> {
        let keys = super.observableKeys
        let additionalKeys = [
            #keyPath(ZMAssetClientMessage.transferState),
            MessageKey.previewGenericMessage.rawValue,
            MessageKey.mediumGenericMessage.rawValue,
            #keyPath(ZMAssetClientMessage.hasDownloadedPreview),
            #keyPath(ZMAssetClientMessage.hasDownloadedFile),
            #keyPath(ZMAssetClientMessage.isDownloading),
            #keyPath(ZMAssetClientMessage.progress),
            #keyPath(ZMMessage.reactions),
            #keyPath(ZMMessage.confirmations),
        ]
        return keys.union(additionalKeys)
    }
}

extension ZMClientMessage {
    override public class var observableKeys: Set<String> {
        let keys = super.observableKeys
        let additionalKeys = [
            #keyPath(ZMAssetClientMessage.hasDownloadedPreview),
            #keyPath(ZMClientMessage.linkPreviewState),
            MessageKey.underlyingMessage.rawValue,
            #keyPath(ZMMessage.reactions),
            #keyPath(ZMMessage.confirmations),
            #keyPath(ZMClientMessage.quote),
            MessageKey.linkPreview.rawValue,
            #keyPath(ZMMessage.linkAttachments),
            #keyPath(ZMClientMessage.buttonStates),
        ]
        return keys.union(additionalKeys)
    }
}

extension ZMImageMessage {
    override public class var observableKeys: Set<String> {
        let keys = super.observableKeys
        let additionalKeys = [
            #keyPath(ZMImageMessage.mediumData),
            #keyPath(ZMImageMessage.mediumRemoteIdentifier),
            #keyPath(ZMMessage.reactions),
        ]
        return keys.union(additionalKeys)
    }
}

extension ZMSystemMessage {
    override public class var observableKeys: Set<String> {
        let keys = super.observableKeys
        let additionalKeys = [
            #keyPath(ZMSystemMessage.childMessages),
            #keyPath(ZMSystemMessage.systemMessageType),
        ]
        return keys.union(additionalKeys)
    }
}

// MARK: - MessageChangeInfo

@objcMembers
public final class MessageChangeInfo: ObjectChangeInfo {
    // MARK: Lifecycle

    public required init(object: NSObject) {
        self.message = object as! ZMMessage
        super.init(object: object)
    }

    // MARK: Public

    public let message: ZMMessage

    override public var debugDescription: String {
        [
            "deliveryStateChanged: \(deliveryStateChanged)",
            "reactionsChanged: \(reactionsChanged)",
            "confirmationsChanged: \(confirmationsChanged)",
            "childMessagesChanged: \(childMessagesChanged)",
            "quoteChanged: \(quoteChanged)",
            "imageChanged: \(imageChanged)",
            "fileAvailabilityChanged: \(fileAvailabilityChanged)",
            "usersChanged: \(usersChanged)",
            "linkPreviewChanged: \(linkPreviewChanged)",
            "transferStateChanged: \(transferStateChanged)",
            "senderChanged: \(senderChanged)",
            "isObfuscatedChanged: \(isObfuscatedChanged)",
            "underlyingMessageChanged: \(underlyingMessageChanged)",
            "linkAttachmentsChanged: \(linkAttachmentsChanged)",
            "buttonStatesChanged: \(buttonStatesChanged)",
        ].joined(separator: ", ")
    }

    public var deliveryStateChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMMessage.deliveryState))
    }

    public var reactionsChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMMessage.reactions)) ||
            changeInfos[MessageChangeInfo.ReactionChangeInfoKey] != nil
    }

    public var confirmationsChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMMessage.confirmations))
    }

    public var underlyingMessageChanged: Bool {
        changedKeysContain(keys: MessageKey.underlyingMessage.rawValue)
    }

    public var childMessagesChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMSystemMessage.childMessages))
    }

    public var quoteChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMClientMessage.quote))
    }

    /// Whether the image data on disk changed
    public var imageChanged: Bool {
        changedKeysContain(
            keys: #keyPath(ZMImageMessage.mediumData),
            #keyPath(ZMImageMessage.mediumRemoteIdentifier),
            #keyPath(ZMAssetClientMessage.hasDownloadedPreview),
            #keyPath(ZMAssetClientMessage.hasDownloadedFile),
            MessageKey.previewGenericMessage.rawValue,
            MessageKey.mediumGenericMessage.rawValue
        )
    }

    /// Whether the file on disk changed
    public var fileAvailabilityChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMAssetClientMessage.hasDownloadedFile))
    }

    public var usersChanged: Bool {
        userChangeInfo != nil
    }

    public var linkPreviewChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMClientMessage.linkPreviewState), MessageKey.linkPreview.rawValue)
    }

    public var transferStateChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMAssetClientMessage.transferState))
    }

    public var senderChanged: Bool {
        if usersChanged, userChangeInfo?.user as? ZMUser == message.sender {
            return true
        }
        return false
    }

    public var isObfuscatedChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMMessage.isObfuscated))
    }

    public var linkAttachmentsChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMMessage.linkAttachments))
    }

    public var buttonStatesChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMClientMessage.buttonStates)) ||
            changeInfos[MessageChangeInfo.ButtonStateChangeInfoKey] != nil
    }

    public var userChangeInfo: UserChangeInfo? {
        changeInfos[MessageChangeInfo.UserChangeInfoKey] as? UserChangeInfo
    }

    // MARK: Internal

    static let UserChangeInfoKey = "userChanges"
    static let ReactionChangeInfoKey = "reactionChanges"
    static let ButtonStateChangeInfoKey = "buttonStateChanges"

    static func changeInfo(for message: ZMMessage, changes: Changes) -> MessageChangeInfo? {
        MessageChangeInfo(object: message, changes: changes)
    }
}

// MARK: - ZMMessageObserver

@objc
public protocol ZMMessageObserver: NSObjectProtocol {
    func messageDidChange(_ changeInfo: MessageChangeInfo)
}

extension MessageChangeInfo {
    /// Adds a ZMMessageObserver to the specified message
    /// To observe messages and their users (senders, systemMessage users), observe the conversation window instead
    /// Messages observed with this call will not contain information about user changes
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forMessage:managedObjectContext:)
    public static func add(
        observer: ZMMessageObserver,
        for message: ZMConversationMessage,
        managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        ManagedObjectObserverToken(
            name: .MessageChange,
            managedObjectContext: managedObjectContext,
            object: message
        ) { [weak observer] note in
            guard let observer,
                  let changeInfo = note.changeInfo as? MessageChangeInfo
            else { return }

            observer.messageDidChange(changeInfo)
        }
    }
}
