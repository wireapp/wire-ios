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

import UserNotifications

// MARK: - LocalNotificationType

/// Defines the various types of local notifications, some of which
/// have associated subtypes.
///
public enum LocalNotificationType {
    case event(LocalNotificationEventType)
    case calling(CallState)
    case message(LocalNotificationContentType)
    case failedMessage
    case availabilityBehaviourChangeAlert(Availability)
    case bundledMessages

    // MARK: Public

    public enum CallState: Equatable {
        case incomingCall(video: Bool)
        case missedCall(cancelled: Bool)
    }
}

// MARK: - NotificationBuilder

/// A notification builder provides the main components used to configure
/// a local notification.
///
public protocol NotificationBuilder {
    var notificationType: LocalNotificationType { get }
    func shouldCreateNotification() -> Bool
    func titleText() -> String?
    func bodyText() -> String
    func userInfo() -> NotificationUserInfo?
}

// MARK: - ZMLocalNotification

/// This class encapsulates all the data necessary to produce a local
/// notification. It configures and formats the textual content for
/// various notification types (message, calling, etc.) and includes
/// information regarding the conversation, sender, and team name.
///
public class ZMLocalNotification: NSObject {
    // MARK: Lifecycle

    public init?(builder: NotificationBuilder, moc: NSManagedObjectContext) {
        guard builder.shouldCreateNotification() else {
            return nil
        }
        self.type = builder.notificationType
        self.title = builder.titleText()
        self.body = builder.bodyText()

        let hasTeam = ZMUser.selfUser(in: moc).hasTeam
        let encryptionAtRestEnabled = moc.encryptMessagesAtRest

        self.category = builder.notificationType.category(
            hasTeam: hasTeam,
            encryptionAtRestEnabled: encryptionAtRestEnabled
        )

        self.sound = builder.notificationType.sound
        self.userInfo = builder.userInfo()
        self.id = userInfo?.messageNonce ?? UUID()
        super.init()

        userInfo?.requestID = id
    }

    // MARK: Public

    /// The unique identifier for this notification. Use it to later update
    /// or remove pending or scheduled notification requests.
    public let id: UUID

    public let type: LocalNotificationType
    public var title: String?
    public var body: String
    public var category: PushNotificationCategory
    public var sound: NotificationSound
    public var userInfo: NotificationUserInfo?

    /// Returns a configured concrete `UNNotificationContent` object.
    public lazy var content: UNNotificationContent = {
        let content = UNMutableNotificationContent()
        content.body = self.body
        content.categoryIdentifier = self.category.rawValue
        content.sound = UNNotificationSound(named: convertToUNNotificationSoundName(sound.name))

        if let title = self.title {
            content.title = title
        }

        if let userInfo = self.userInfo {
            content.userInfo = userInfo.storage
        }

        // only group non ephemeral messages
        if let conversationID = self.conversationID {
            switch self.type {
            case .message(.ephemeral): break
            default: content.threadIdentifier = conversationID.transportString()
            }
        }

        return content
    }()

    /// Returns a configured concrete `UNNotificationRequest`.
    public lazy var request = UNNotificationRequest(identifier: id.uuidString, content: content, trigger: nil)

    public var contentHashValue: Int {
        var hash = Hasher()
        hash.combine(messageNonce)
        hash.combine(title)
        hash.combine(body)
        return hash.finalize()
    }
}

// MARK: - Properties

extension ZMLocalNotification {
    public var selfUserID: UUID? { userInfo?.selfUserID }
    public var senderID: UUID? { userInfo?.senderID }
    public var messageNonce: UUID? { userInfo?.messageNonce }
    public var conversationID: UUID? { userInfo?.conversationID }

    /// Returns true if it is a calling notification, else false.
    var isCallingNotification: Bool {
        switch type {
        case .calling: true
        default: false
        }
    }

    /// Returns true if it is a ephemeral notification, else false.
    var isEphemeral: Bool {
        guard case .message(.ephemeral) = type else {
            return false
        }
        return true
    }
}

// MARK: - Lookup

extension ZMLocalNotification {
    public func conversation(in moc: NSManagedObjectContext) -> ZMConversation? {
        userInfo?.conversation(in: moc)
    }

    func sender(in moc: NSManagedObjectContext) -> ZMUser? {
        userInfo?.sender(in: moc)
    }
}

// MARK: - Unread Count

extension ZMLocalNotification {
    public func increaseEstimatedUnreadCount(on conversation: ZMConversation?) {
        if type.shouldIncreaseUnreadCount {
            conversation?.internalEstimatedUnreadCount += 1
            WireLogger.badgeCount
                .info(
                    "increase internalEstimatedUnreadCount: \(String(describing: conversation?.internalEstimatedUnreadCount)) in \(String(describing: conversation?.remoteIdentifier?.uuidString)) timestamp: \(Date())"
                )
        }

        if type.shouldDecreaseUnreadCount {
            conversation?.internalEstimatedUnreadCount -= 1
        }

        if type.shouldIncreaseUnreadMentionCount {
            conversation?.internalEstimatedUnreadSelfMentionCount += 1
        }

        if type.shouldIncreaseUnreadReplyCount {
            conversation?.internalEstimatedUnreadSelfReplyCount += 1
        }
    }
}

extension LocalNotificationType {
    var shouldIncreaseUnreadCount: Bool {
        if case LocalNotificationType.calling(.missedCall) = self {
            return true
        }

        guard case let LocalNotificationType.message(contentType) = self else {
            return false
        }

        switch contentType {
        case .messageTimerUpdate, .participantsAdded, .participantsRemoved, .reaction:
            return false
        default:
            return true
        }
    }

    var shouldDecreaseUnreadCount: Bool {
        guard case let LocalNotificationType.event(contentType) = self else {
            return false
        }

        switch contentType {
        case .conversationDeleted:
            return true
        default:
            return false
        }
    }

    var shouldIncreaseUnreadMentionCount: Bool {
        guard case let LocalNotificationType.message(contentType) = self else {
            return false
        }

        switch contentType {
        case .ephemeral(isMention: true, isReply: _),
             .text(_, isMention: true, isReply: _):
            return true
        default:
            return false
        }
    }

    var shouldIncreaseUnreadReplyCount: Bool {
        guard case let LocalNotificationType.message(contentType) = self else {
            return false
        }

        switch contentType {
        case .ephemeral(isMention: _, isReply: true),
             .text(_, isMention: _, isReply: true):
            return true
        default:
            return false
        }
    }
}

extension ZMLocalNotification {
    public static func bundledMessages(count: Int, in context: NSManagedObjectContext) -> ZMLocalNotification? {
        let builder = BundledMessagesNotificationBuilder(messageCount: count)
        return ZMLocalNotification(builder: builder, moc: context)
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUNNotificationSoundName(_ input: String) -> UNNotificationSoundName {
    UNNotificationSoundName(rawValue: input)
}
