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
import WireSystem

@objcMembers
public class ZMClientMessage: ZMOTRMessage {
    public static let linkPreviewStateKey = "linkPreviewState"
    public static let linkPreviewKey = "linkPreview"

    //// From https://github.com/wearezeta/generic-message-proto:
    //// "If payload is smaller then 256KB then OM can be sent directly"
    //// Just to be sure we set the limit lower, to 128KB (base 10)
    public static let byteSizeExternalThreshold: UInt = 128_000

    /// Link Preview state
    @NSManaged public var updatedTimestamp: Date?

    /// In memory cache
    var cachedUnderlyingMessage: GenericMessage?

    override public static func entityName() -> String {
        "ClientMessage"
    }

    override open var ignoredKeys: Set<AnyHashable>? {
        (super.ignoredKeys ?? Set())
            .union([#keyPath(updatedTimestamp)])
    }

    override public var updatedAt: Date? {
        updatedTimestamp
    }

    override public var hashOfContent: Data? {
        guard let serverTimestamp else {
            return nil
        }
        return underlyingMessage?.hashOfContent(with: serverTimestamp)
    }

    override public func awakeFromFetch() {
        super.awakeFromFetch()

        cachedUnderlyingMessage = nil
    }

    override public func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)

        cachedUnderlyingMessage = nil
    }

    override public func didTurnIntoFault() {
        super.didTurnIntoFault()

        cachedUnderlyingMessage = nil
    }

    override public var isUpdatingExistingMessage: Bool {
        guard let content = underlyingMessage?.content else {
            return false
        }
        switch content {
        case .edited, .reaction:
            return true
        default:
            return false
        }
    }

    public static func keyPathsForValuesAffectingUnderlyingMessage() -> Set<String> {
        Set([
            #keyPath(ZMClientMessage.dataSet),
            #keyPath(ZMClientMessage.dataSet) + ".data",
        ])
    }

    override public func expire() {
        WireLogger.messaging
            .warn("expiring client message " + String(describing: underlyingMessage?.safeForLoggingDescription))

        guard
            let genericMessage = underlyingMessage,
            let content = genericMessage.content else {
            super.expire()
            return
        }

        switch content {
        case .edited:
            // Replace the nonce with the original
            // This way if we get a delete from a different device while we are waiting for the response it will delete
            // this message
            let originalID = underlyingMessage.flatMap { UUID(uuidString: $0.edited.replacingMessageID) }
            nonce = originalID

        case .buttonAction:
            guard
                let managedObjectContext,
                let conversation else {
                return
            }
            ZMClientMessage.expireButtonState(
                forButtonAction: genericMessage.buttonAction,
                forConversation: conversation,
                inContext: managedObjectContext
            )

        default:
            break
        }
        super.expire()
    }

    override public func resend() {
        if let genericMessage = underlyingMessage,
           case .edited? = genericMessage.content {
            // Re-apply the edit since we've restored the orignal nonce when the message expired
            editText(
                textMessageData?.messageText ?? "",
                mentions: textMessageData?.mentions ?? [],
                fetchLinkPreview: true
            )
        }
        super.resend()
    }

    override public func update(withPostPayload payload: [AnyHashable: Any], updatedKeys: Set<AnyHashable>?) {
        // we don't want to update the conversation if the message is a confirmation message
        guard
            let genericMessage = underlyingMessage,
            let content = genericMessage.content else {
            return
        }
        switch content {
        case .confirmation, .reaction:
            return

        case .deleted:
            let originalID = UUID(uuidString: genericMessage.deleted.messageID)
            guard
                let managedObjectContext,
                let conversation else {
                return
            }

            let original = ZMMessage.fetch(withNonce: originalID, for: conversation, in: managedObjectContext)
            original?.sender = nil
            original?.senderClientID = nil

        case .edited:
            if let nonce = nonce(fromPostPayload: payload),
               self.nonce != nonce {
                WireLogger.messaging.error(
                    "sent message response nonce does not match \(nonce)",
                    attributes: logInformation
                )
                return
            }

            if let serverTimestamp = (payload as NSDictionary).optionalDate(forKey: "time") {
                updatedTimestamp = serverTimestamp
            }

        default:
            super.update(withPostPayload: payload, updatedKeys: nil)
        }
    }

    private var logInformation: LogAttributes {
        [
            .nonce: nonce?.safeForLoggingDescription ?? "<nil>",
            .messageType: underlyingMessage?.safeTypeForLoggingDescription ?? "<nil>",
            .conversationId: conversation?.qualifiedID?.safeForLoggingDescription ?? "<nil>",
        ].merging(.safePublic, uniquingKeysWith: { _, new in new })
    }

    override public static func predicateForObjectsThatNeedToBeInsertedUpstream() -> NSPredicate? {
        let encryptedNotSynced = NSPredicate(format: "%K == FALSE", DeliveredKey)
        let notExpired = NSPredicate(format: "%K == 0", ZMMessageIsExpiredKey)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [encryptedNotSynced, notExpired])
    }

    override public func markAsSent() {
        super.markAsSent()

        if linkPreviewState == ZMLinkPreviewState.uploaded {
            linkPreviewState = ZMLinkPreviewState.done
        }
        setObfuscationTimerIfNeeded()
    }

    private func setObfuscationTimerIfNeeded() {
        guard isEphemeral else {
            return
        }
        if let genericMessage = underlyingMessage,
           genericMessage.textData != nil,
           !genericMessage.linkPreviews.isEmpty,
           linkPreviewState != ZMLinkPreviewState.done {
            // If we have link previews and they are not sent yet, we wait until they are sent
            return
        }
        startDestructionIfNeeded()
    }

    func hasDownloadedImage() -> Bool {
        guard
            let textMessageData,
            textMessageData.linkPreview != nil,
            let cache = managedObjectContext?.zm_fileAssetCache
        else {
            return false
        }

        return cache.hasImageData(for: self)
    }
}

extension ZMClientMessage {
    override public var imageMessageData: ZMImageMessageData? {
        nil
    }

    override public var fileMessageData: ZMFileMessageData? {
        nil
    }

    override public var isSilenced: Bool {
        conversation?.isMessageSilenced(underlyingMessage, senderID: sender?.remoteIdentifier) ?? true
    }
}
