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

struct TeamNotificationDecodingProxy: Decodable {

    let kind: TeamNotification.Kind

    init(kind: TeamNotification.Kind) {
        self.kind = kind
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: TeamNotificationCodingKeys.self)
        let notificationType = try container.decode(String.self, forKey: .notificationType)

        do {
            switch TeamNotificationType(rawValue: notificationType) {
            case .memberJoin:
                let notification = try TeamMemberJoinNotificationDecoder().decode(from: container)
                self.kind = .memberJoin(notification)
            case .none:
                throw UnknownTeamNotificationTypeError()
            }
        } catch {
            throw TeamNotificationDecodingProxyError(
                notificationType: notificationType,
                decodingError: error
            )
        }
    }

    struct UnknownTeamNotificationTypeError: Error {}

}
