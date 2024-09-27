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

import UIKit
import UserNotifications
import WireTransport
import WireUtilities

@objc
public class ZMLocalNotificationSet: NSObject {
    let archivingKey: String
    let keyValueStore: ZMSynchonizableKeyValueStore
    public var notificationCenter: UserNotificationCenterAbstraction = .wrapper(.current())

    public var notifications = Set<ZMLocalNotification>() {
        didSet { try? updateArchive() }
    }

    public var oldNotifications = [NotificationUserInfo]()

    private var allNotifications: [NotificationUserInfo] {
        notifications.compactMap(\.userInfo) + oldNotifications
    }

    public init(archivingKey: String, keyValueStore: ZMSynchonizableKeyValueStore) {
        self.archivingKey = archivingKey
        self.keyValueStore = keyValueStore
        super.init()

        unarchiveOldNotifications()
    }

    /// Unarchives all previously created notifications that haven't been cancelled yet
    func unarchiveOldNotifications() {
        // NotificationUserInfo was moved from WireSyncEngine. To avoid crashing when unarchiving
        // data stored in previous versions, we must add a mapping of the class from the old name.
        NSKeyedUnarchiver.setClass(
            WireRequestStrategy.NotificationUserInfo.self,
            forClassName: "WireSyncEngine.NotificationUserInfo"
        )

        guard
            let archive = keyValueStore.storedValue(key: archivingKey) as? Data,
            let unarchivedNotes = NSKeyedUnarchiver.unarchiveObject(with: archive) as? [NotificationUserInfo]

        else {
            return
        }

        oldNotifications = unarchivedNotes
    }

    /// Archives all scheduled notifications - this could be optimized
    func updateArchive() throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: allNotifications, requiringSecureCoding: false)

        keyValueStore.store(value: data as NSData, key: archivingKey)
        keyValueStore.enqueueDelayedSave() // we need to save otherwise changes might not be stored
    }

    @discardableResult
    public func remove(_ notification: ZMLocalNotification) -> ZMLocalNotification? {
        notifications.remove(notification)
    }

    public func addObject(_ notification: ZMLocalNotification) {
        notifications.insert(notification)
    }

    func replaceObject(_ toReplace: ZMLocalNotification, newObject: ZMLocalNotification) {
        notifications.remove(toReplace)
        notifications.insert(newObject)
    }

    /// Cancels all notifications
    public func cancelAllNotifications() {
        let ids = allNotifications.compactMap { $0.requestID?.uuidString }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ids)
        notifications = Set()
        oldNotifications = []
    }

    /// This cancels all notifications of a specific conversation
    public func cancelNotifications(_ conversation: ZMConversation) {
        cancelOldNotifications(conversation)
        cancelCurrentNotifications(conversation)
    }

    /// Cancel all notifications created in this run
    func cancelCurrentNotifications(_ conversation: ZMConversation) {
        guard !notifications.isEmpty else { return }
        let toRemove = notifications.filter { $0.conversationID == conversation.remoteIdentifier }
        let ids = toRemove.map(\.id.uuidString)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ids)
        notifications.subtract(toRemove)
    }

    /// Cancels all notifications created in previous runs
    func cancelOldNotifications(_ conversation: ZMConversation) {
        guard !oldNotifications.isEmpty else { return }

        oldNotifications = oldNotifications.filter { userInfo in
            guard
                userInfo.conversationID == conversation.remoteIdentifier,
                let requestID = userInfo.requestID?.uuidString
            else { return true }

            notificationCenter.removePendingNotificationRequests(withIdentifiers: [requestID])
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [requestID])
            return false
        }
    }

    /// Cancal all notifications with the given message nonce
    public func cancelCurrentNotifications(messageNonce: UUID) {
        guard !notifications.isEmpty else { return }
        let toRemove = notifications.filter { $0.messageNonce == messageNonce }
        let ids = toRemove.map(\.id.uuidString)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ids)
        notifications.subtract(toRemove)
    }
}

// Event Notifications
extension ZMLocalNotificationSet {
    func cancelNotificationForIncomingCall(_ conversation: ZMConversation) {
        let toRemove = notifications.filter {
            $0.conversationID == conversation.remoteIdentifier && $0.isCallingNotification
        }
        let ids = toRemove.map(\.id.uuidString)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ids)
        notifications.subtract(toRemove)
    }
}

extension ZMConversation {
    public func localizedCallerName(with user: ZMUser) -> String {
        let conversationName = userDefinedName
        let callerName: String? = user.name
        var result: String?

        switch conversationType {
        case .group:
            if let conversationName, let callerName {
                result = String.localizedStringWithFormat(
                    "callkit.call.started.group".pushFormatString,
                    callerName,
                    conversationName
                )
            } else if let conversationName {
                result = String.localizedStringWithFormat(
                    "callkit.call.started.group.nousername".pushFormatString,
                    conversationName
                )
            } else if let callerName {
                result = String.localizedStringWithFormat(
                    "callkit.call.started.group.noconversationname".pushFormatString,
                    callerName
                )
            }

        case .oneOnOne:
            result = connectedUser?.name

        default:
            break
        }

        return result ?? String
            .localizedStringWithFormat("callkit.call.started.group.nousername.noconversationname".pushFormatString)
    }
}
