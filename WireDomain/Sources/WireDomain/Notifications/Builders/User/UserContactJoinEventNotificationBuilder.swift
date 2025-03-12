//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireAPI

struct UserContactJoinEventNotificationBuilder: NotificationBuilder {

    private struct Context {
        let name: String
    }

    private let context: Context

    init(
        name: String
    ) {
        self.context = Context(
            name: name
        )
    }

    func shouldBuildNotification() async -> Bool {
        true
    }

    func buildContent() async -> UserNotification {
        buildUserContactJoinNotification()
    }

    // MARK: - Build notifications

    private func buildUserContactJoinNotification() -> UserNotification {
        let content = UNMutableNotificationContent()

        let body = String.formated(key: "push.notification.body.contactJoined", context.name)
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
