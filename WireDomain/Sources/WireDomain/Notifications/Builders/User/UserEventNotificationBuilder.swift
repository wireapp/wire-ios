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

// sourcery: AutoMockable
protocol UserEventNotificationBuilderProtocol {
    func buildContent(
        event: UserEvent
    ) async -> UserNotification?
}

struct UserEventNotificationBuilder: UserEventNotificationBuilderProtocol {

    let validator: Validator
    let userConnectionEventNotificationBuilder: UserConnectionEventNotificationBuilder
    let userContactJoinEventNotificationBuilder: UserContactJoinEventNotificationBuilder

    func buildContent(
        event: UserEvent
    ) async -> UserNotification? {
        let canDisplayNotification = await validator.validate()

        guard canDisplayNotification else {
            return nil
        }

        switch event {
        case let .connection(userConnectionEvent):

            return await userConnectionEventNotificationBuilder.buildContent(
                event: userConnectionEvent
            )

        case let .contactJoin(userContactJoinEvent):

            return await userContactJoinEventNotificationBuilder.buildContent(
                event: userContactJoinEvent
            )

        default:
            return nil
        }
    }

}

extension UserEventNotificationBuilder {
    struct Validator {

        func validate() async -> Bool {
            true // No top level validation criteria for these notifications
        }
    }
}
