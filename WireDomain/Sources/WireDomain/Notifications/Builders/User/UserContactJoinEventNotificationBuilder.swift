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

import UserNotifications
import WireDataModel
import WireNetwork

struct UserContactJoinEventNotificationBuilder {

    let context: Context
    let validator: Validator

    func buildContent(
        event: UserContactJoinEvent
    ) async -> UserNotification? {
        let canBuildNotification = await validator.validate()

        guard canBuildNotification else {
            return nil
        }

        return buildUserContactJoinNotification(
            name: event.name
        )
    }

    // MARK: - Build notifications

    private func buildUserContactJoinNotification(
        name: String
    ) -> UserNotification {
        let content = UNMutableNotificationContent()

        let body = String.formated(
            key: "push.notification.body.contactJoined",
            bundle: .module,
            name
        )

        content.body = body
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()

        return .text(content)
    }

    // MARK: - Helpers

    private func makeSound(type: NotificationSound = .default) -> UNNotificationSound {
        let notificationSoundName = UNNotificationSoundName(type.rawValue)
        return UNNotificationSound(named: notificationSoundName)
    }

    private func makeCategory() -> String {
        NotificationCategory.nonActionable.rawValue
    }

}

extension UserContactJoinEventNotificationBuilder {
    struct Validator {

        func validate() async -> Bool {
            true // No validation criteria for this notification
        }
    }

    struct Context {}
}
