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
import UserNotifications

/**
 * The categories of notifications supported by the app.
 */

enum PushNotificationCategory: String, CaseIterable {
    case incomingCall = "incomingCallCategory"
    case missedCall = "missedCallCategory"
    case conversation = "conversationCategory"
    case conversationWithMute = "conversationCategoryWithMute"
    case conversationWithLike = "conversationCategoryWithLike"
    case conversationWithLikeAndMute = "conversationCategoryWithLikeAndMute"
    case connect = "connectCategory"
    case alert = "alertCategory"
    case conversationUnderEncryptionAtRest = "conversationUnderEncryptionAtRestCategory"
    case conversationUnderEncryptionAtRestWithMute = "conversationUnderEncryptionAtRestWithMuteCategory"

    /// All the supported categories.
    static var allCategories: Set<UNNotificationCategory> {
        let categories = PushNotificationCategory.allCases.map(\.userNotificationCategory)

        return Set(categories)
    }

    /// The actions for notifications of this category.
    var actions: [NotificationAction] {
        switch self {
        case .incomingCall:
            [CallNotificationAction.ignore]
        case .missedCall:
            [CallNotificationAction.callBack]
        case .conversation:
            []
        case .conversationWithMute:
            [ConversationNotificationAction.mute]
        case .conversationWithLike:
            []
        case .conversationWithLikeAndMute:
            [ConversationNotificationAction.mute]
        case .connect:
            [ConversationNotificationAction.connect]
        case .alert:
            []
        case .conversationUnderEncryptionAtRest:
            []
        case .conversationUnderEncryptionAtRestWithMute:
            [ConversationNotificationAction.mute]
        }
    }

    /// The representation of the category that can be used with `UserNotifications` API.
    var userNotificationCategory: UNNotificationCategory {
        let userActions = self.actions.map(\.userAction)
        return UNNotificationCategory(identifier: rawValue, actions: userActions, intentIdentifiers: [], options: [])
    }
}
