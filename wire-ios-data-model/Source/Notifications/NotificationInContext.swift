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
import WireUtilities

// MARK: - NotificationInContext

/// A notification that is tied to a specific context. It mimics
/// the behavior of a regular NSNotification but is always linked to
/// a context.
/// This is needed to allow for sending a notification for `nil` object,
/// or to register an observer for any (`nil`) object, but still avoiding
/// receiving notifications that are from a different context. We could not
/// use the object as the implicit context because when registering for `nil`
/// we would get all notifications, even from other contexts.

@objcMembers
public class NotificationInContext: NSObject {
    // MARK: Lifecycle

    public init(
        name: Notification.Name,
        context: NotificationContext,
        object: AnyObject? = nil,
        userInfo: [String: Any]? = nil
    ) {
        var userInfo = userInfo ?? [:]
        if let object {
            userInfo[NotificationInContext.objectInNotificationKey] = object
        }
        self.notification = Notification(
            name: name,
            object: context,
            userInfo: userInfo
        )
    }

    private init(notification: Notification) {
        self.notification = notification
    }

    // MARK: Public

    /// Name of the notification
    public var name: Notification.Name {
        notification.name
    }

    /// The object of the notification
    public var object: AnyObject? {
        userInfo[NotificationInContext.objectInNotificationKey] as AnyObject?
    }

    /// The context in which the notification is valid
    public var context: NotificationContext {
        notification.object! as! NotificationContext
    }

    public var userInfo: [AnyHashable: Any] {
        notification.userInfo ?? [:]
    }

    /// Register for observer
    public static func addObserver(
        name: Notification.Name,
        context: NotificationContext,
        object: AnyObject? = nil,
        queue: OperationQueue? = nil,
        using: @escaping (NotificationInContext) -> Void
    ) -> SelfUnregisteringNotificationCenterToken {
        addUnboundedObserver(name: name, context: context, object: object, queue: queue, using: using)
    }

    public static func addUnboundedObserver(
        name: Notification.Name,
        context: NotificationContext?,
        object: AnyObject? = nil,
        queue: OperationQueue? = nil,
        using: @escaping (NotificationInContext) -> Void
    ) -> SelfUnregisteringNotificationCenterToken {
        SelfUnregisteringNotificationCenterToken(NotificationCenter.default.addObserver(
            forName: name,
            object: context,
            queue: queue
        ) { note in
            let notificationInContext = NotificationInContext(notification: note)
            guard object == nil || object! === notificationInContext.object else {
                return
            }
            using(notificationInContext)
        })
    }

    /// Post notification in default notification center
    public func post() {
        NotificationCenter.default.post(notification)
    }

    // MARK: Internal

    static let objectInNotificationKey = "objectInNotification"

    // MARK: Private

    /// Internal notification
    private let notification: Notification
}

extension NotificationInContext {
    private enum UserInfoKeys: String {
        case changedKeys
        case changeInfo
    }

    public convenience init(
        name: Notification.Name,
        context: NotificationContext,
        object: AnyObject? = nil,
        changeInfo: ObjectChangeInfo,
        userInfo: [String: Any]? = nil
    ) {
        var userInfo = userInfo ?? [:]
        userInfo[UserInfoKeys.changeInfo.rawValue] = changeInfo

        self.init(
            name: name,
            context: context,
            object: object,
            userInfo: userInfo
        )
    }

    public convenience init(
        name: Notification.Name,
        context: NotificationContext,
        object: AnyObject? = nil,
        changedKeys: [String],
        userInfo: [String: Any]? = nil
    ) {
        var userInfo = userInfo ?? [:]
        userInfo[UserInfoKeys.changedKeys.rawValue] = changedKeys

        self.init(
            name: name,
            context: context,
            object: object,
            userInfo: userInfo
        )
    }

    public var changeInfo: ObjectChangeInfo? {
        userInfo[UserInfoKeys.changeInfo.rawValue] as? ObjectChangeInfo
    }

    public var changedKeys: [String]? {
        userInfo[UserInfoKeys.changedKeys.rawValue] as? [String]
    }
}
