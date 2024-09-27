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

import WireDataModel

// MARK: - Typing

private let typingNotificationUsersKey = "typingUsers"

extension ZMConversation {
    @objc
    public func addTypingObserver(_ observer: ZMTypingChangeObserver) -> Any {
        NotificationInContext.addObserver(
            name: ZMConversation.typingNotificationName,
            context: managedObjectContext!.notificationContext,
            object: self
        ) { [weak observer, weak self] note in
            guard let self else {
                return
            }

            let users = note.userInfo[typingNotificationUsersKey] as? Set<ZMUser> ?? Set()
            observer?.typingDidChange(conversation: self, typingUsers: Array(users))
        }
    }

    @objc
    func notifyTyping(typingUsers: Set<ZMUser>) {
        NotificationInContext(
            name: ZMConversation.typingNotificationName,
            context: managedObjectContext!.notificationContext,
            object: self,
            userInfo: [typingNotificationUsersKey: typingUsers]
        ).post()
    }
}

// MARK: - ZMTypingChangeObserver

@objc
public protocol ZMTypingChangeObserver: NSObjectProtocol {
    func typingDidChange(conversation: ZMConversation, typingUsers: [UserType])
}

// MARK: - DatabaseEncryptionLockNotification

public struct DatabaseEncryptionLockNotification: SelfPostingNotification {
    static var notificationName = Notification.Name("DatabaseEncryptionLockNotification")

    var databaseIsEncrypted: Bool
}
