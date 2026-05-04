//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireLinkPreview

private var zmLog = ZMSLog(tag: "Message")

@objc
public enum ZMDeliveryState: UInt {
    case invalid = 0
    case pending = 1
    case sent = 2
    case delivered = 3
    case read = 4
    case failedToSend = 5
}

@objc
public protocol ReadReceipt {

    @available(*, deprecated, message: "Use `userType` instead")
    var user: ZMUser { get }
    var userType: UserType { get }

    var serverTimestamp: Date? { get }

}

@objc
public protocol ZMConversationMessage: NSObjectProtocol {
    typealias MessageID = UUID

    /// Unique identifier for the message
    var nonce: MessageID? { get }

    /// The user who sent the message (internal)
    @available(*, deprecated, message: "Use `senderUser` instead")
    var sender: ZMUser? { get }

    /// The user who sent the message
    var senderUser: UserType? { get }

    /// The timestamp as received by the server
    var serverTimestamp: Date? { get }

    @available(*, deprecated, message: "Use `conversationLike` instead")
    var conversation: ZMConversation? { get }

    /// The conversation this message belongs to
    var conversationLike: ConversationLike? { get }

    /// The current delivery state of this message. It makes sense only for
    /// messages sent from this device. In any other case, it will be
    /// ZMDeliveryStateDelivered
    var deliveryState: ZMDeliveryState { get }

    /// True if the message has been successfully sent to the server
    var isSent: Bool { get }

    /// List of recipients who have read the message.
    var readReceipts: [ReadReceipt] { get }

    /// Whether the message expects read confirmations.
    var needsReadConfirmation: Bool { get }

    /// The textMessageData of the message which also contains potential link previews. If the message has no text, it
    /// will be nil
    var textMessageData: TextMessageData? { get }

    /// The image data associated with the message. If the message has no image, it will be nil
    var imageMessageData: ZMImageMessageData? { get }

    /// The system message data associated with the message. If the message is not a system message data associated, it
    /// will be nil
    var systemMessageData: ZMSystemMessageData? { get }

    /// The knock message data associated with the message. If the message is not a knock, it will be nil
    var knockMessageData: ZMKnockMessageData? { get }

    /// The file transfer data associated with the message. If the message is not the file transfer, it will be nil
    var fileMessageData: ZMFileMessageData? { get }

    /// The location message data associated with the message. If the message is not a location message, it will be nil
    var locationMessageData: LocationMessageData? { get }

    /// The multipart message data associated with the message. If the message is not a multipart message, it will be
    /// nil
    var multipartMessageData: MultipartMessageData? { get }

    var usersReaction: [String: [UserType]] { get }
    var reactionData: Set<ReactionData> { get }
    func reactionsSortedByCreationDate() -> [ReactionData]

    /// In case this message failed to deliver, this will resend it
    func resend()

    /// tell whether or not the message can be deleted
    var canBeDeleted: Bool { get }

    /// True if the message has been deleted
    var hasBeenDeleted: Bool { get }

    var updatedAt: Date? { get }

    /// Starts the "self destruction" timer if all conditions are met
    /// It checks internally if the message is ephemeral, if sender is the other user and if there is already an
    /// existing timer
    /// Returns YES if a timer was started by the message call
    func startSelfDestructionIfNeeded() -> Bool

    /// Returns true if the message is ephemeral
    var isEphemeral: Bool { get }

    /// If the message is ephemeral, it returns a fixed timeout
    /// Otherwise it returns -1
    /// Override this method in subclasses if needed
    var deletionTimeout: TimeInterval { get }

    /// Returns true if the message is an ephemeral message that was sent by the selfUser and the obfuscation timer
    /// already fired
    /// At this point the genericMessage content is already cleared. You should receive a notification that the content
    /// was cleared
    var isObfuscated: Bool { get }

    /// Returns the date when a ephemeral message will be destructed or `nil` if th message is not ephemeral
    var destructionDate: Date? { get }

    /// Returns whether this is a message that caused the security level of the conversation to degrade in this session
    /// (since the
    /// app was restarted)
    var causedSecurityLevelDegradation: Bool { get }

    /// Marks the message as the last unread message in the conversation, moving the unread mark exactly before this
    /// message.
    func markAsUnread()

    /// Checks if the message can be marked unread
    var canBeMarkedUnread: Bool { get }

    /// The replies quoting this message.
    var replies: Set<ZMMessage> { get }

    /// The links attached to the message.
    var linkAttachments: [LinkAttachment]? { get set }

    /// Used to trigger link attachments update for this message.
    var needsLinkAttachmentsUpdate: Bool { get set }

    var isSilenced: Bool { get }

    /// Whether the asset message can not be received or shared.
    var isRestricted: Bool { get }
}

public protocol ConversationCompositeMessage {
    /// The composite message associated with the message. If the message is not a composite message, it will be nil
    var compositeMessageData: CompositeMessageData? { get }
}

public protocol SwiftConversationMessage {

    /// The reason `self` was expired.
    var expirationReason: ExpirationReason? { get }

    /// The list of users who didn't receive the message (e.g their backend is offline)
    var failedToSendUsers: [UserType] { get }

}

public extension ZMConversationMessage {

    /// Whether the given user is the sender of the message.

    func isUserSender(_ user: UserType) -> Bool {
        guard let zmUser = user as? ZMUser else { return false }

        return zmUser == senderUser as? ZMUser
    }
}

public extension Equatable where Self: ZMConversationMessage {}

public func == (lhs: ZMConversationMessage, rhs: ZMConversationMessage) -> Bool {
    lhs.isEqual(rhs)
}

public func == (lhs: ZMConversationMessage?, rhs: ZMConversationMessage?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        true
    case (_, nil):
        false
    case (nil, _):
        false
    case (_, _):
        lhs!.isEqual(rhs!)
    }
}

// MARK: - Conversation managed properties

public extension ZMMessage {

    @NSManaged var visibleInConversation: ZMConversation?
    @NSManaged var hiddenInConversation: ZMConversation?

    var conversation: ZMConversation? {
        visibleInConversation ?? hiddenInConversation
    }
}

// MARK: - Conversation Message protocol implementation

extension ZMMessage: ZMConversationMessage {
    public var conversationLike: ConversationLike? {
        conversation
    }

    public var senderUser: UserType? {
        sender
    }

    @NSManaged public var linkAttachments: [LinkAttachment]?
    @NSManaged public var needsLinkAttachmentsUpdate: Bool
    @NSManaged public var replies: Set<ZMMessage>

    public var readReceipts: [ReadReceipt] {
        confirmations
            .filter { $0.type == .read }
            .sortedAscendingPrependingNil(by: \.serverTimestamp)
    }

    public var causedSecurityLevelDegradation: Bool {
        false
    }

    public var canBeMarkedUnread: Bool {
        guard isNormal,
              serverTimestamp != nil,
              conversation != nil,
              let sender,
              !sender.isSelfUser else {
            return false
        }

        return true
    }

    public func markAsUnread() {
        guard canBeMarkedUnread,
              let serverTimestamp,
              let conversation,
              let managedObjectContext,
              let syncContext = managedObjectContext.zm_sync else {

            zmLog.error("Cannot mark as unread message outside of the conversation.")
            return
        }
        let conversationID = conversation.objectID

        conversation.lastReadServerTimeStamp = Date(timeInterval: -0.01, since: serverTimestamp)
        managedObjectContext.saveOrRollback()

        syncContext.performGroupedBlock {
            guard let syncObject = try? syncContext.existingObject(with: conversationID),
                  let syncConversation = syncObject as? ZMConversation else {
                zmLog
                    .error(
                        "Cannot mark as unread message outside of the conversation: sync conversation cannot be fetched."
                    )
                return
            }

            syncConversation.calculateLastUnreadMessages()
            syncContext.saveOrRollback()
        }
    }

    public var isSilenced: Bool {
        conversation?.isMessageSilenced(nil, senderID: sender?.remoteIdentifier) ?? true
    }

    public var isRestricted: Bool {
        guard
            isFile || isImage,
            let managedObjectContext
        else { return false }

        let featureRepository = LegacyFeatureRepository(context: managedObjectContext)
        let fileSharingFeature = featureRepository.fetchFileSharing()

        return fileSharingFeature.status == .disabled
    }

}

public extension ZMMessage {

    @NSManaged var sender: ZMUser?
    @NSManaged var serverTimestamp: Date?

    @objc var textMessageData: TextMessageData? {
        nil
    }

    @objc var imageMessageData: ZMImageMessageData? {
        nil
    }

    @objc var knockMessageData: ZMKnockMessageData? {
        nil
    }

    @objc var systemMessageData: ZMSystemMessageData? {
        nil
    }

    @objc var fileMessageData: ZMFileMessageData? {
        nil
    }

    @objc var locationMessageData: LocationMessageData? {
        nil
    }

    @objc var multipartMessageData: MultipartMessageData? {
        nil
    }

    @objc var isSent: Bool {
        true
    }

    @objc var deliveryState: ZMDeliveryState {
        .delivered
    }

    @objc var reactionData: Set<ReactionData> {
        var result = Set<ReactionData>()
        for reaction in reactions where !reaction.users.isEmpty {
            result.insert(
                ReactionData(
                    reactionString: reaction.unicodeValue!,
                    users: Array(reaction.users),
                    creationDate: reaction.creationDate
                )
            )
        }
        return result
    }

    @objc var usersReaction: [String: [UserType]] {
        Array(reactionData)
            .partition(by: \.reactionString)
            .mapValues { $0.flatMap(\.users) }
    }

    @objc
    func reactionsSortedByCreationDate() -> [ReactionData] {
        reactionData.sorted {
            $0.creationDate < $1.creationDate
        }
    }

    @objc var canBeDeleted: Bool {
        deliveryState != .pending
    }

    @objc var hasBeenDeleted: Bool {
        isZombieObject || (visibleInConversation == nil && hiddenInConversation != nil)
    }

    @objc var updatedAt: Date? {
        nil
    }

    @objc
    func startSelfDestructionIfNeeded() -> Bool {
        if !isZombieObject, isEphemeral, let sender, !sender.isSelfUser {
            return startDestructionIfNeeded()
        }
        return false
    }

    @objc var isEphemeral: Bool {
        false
    }

    @objc var deletionTimeout: TimeInterval {
        -1
    }
}

// MARK: - Message send failure properties

public extension ZMMessage {

    @NSManaged var failedToSendRecipients: Set<ZMUser>?

}
