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

extension ZMConversation {
    public enum UserInfoKeys: String {
        case nonFederatingBackends
    }

    @objc public static let lastReadDidChangeNotificationName = Notification.Name(rawValue: "ZMConversationLastReadDidChangeNotificationName")
    @objc public static let clearTypingNotificationName = Notification.Name(rawValue: "ZMConversationClearTypingNotificationName")
    @objc public static let isVerifiedNotificationName = Notification.Name(rawValue: "ZMConversationIsVerifiedNotificationName")
    @objc public static let missingLegalHoldConsentNotificationName = Notification.Name(rawValue: "ZMConversationMissingLegalHoldConsentNotification")
    @objc public static let nonFederatingBackendsNotification = Notification.Name(rawValue: "ZMConversationNonFederatingBackendsNotification")

    /// Sends a notification with the given name on the UI context
    func notifyOnUI(name: Notification.Name, userInfo: [String: Any]? = nil) {
        guard let userInterfaceContext = self.managedObjectContext?.zm_userInterface else {
            return
        }

        userInterfaceContext.performGroupedBlock {
            NotificationInContext(name: name, context: userInterfaceContext.notificationContext, object: self, userInfo: userInfo).post()
        }
    }
}
