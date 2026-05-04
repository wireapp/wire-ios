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

private enum PushChannelKeys: String {
    case data
    case identifier = "id"
    case notificationType = "type"
}

private enum PushNotificationType: String {
    case plain
    case notice
}

@objc
public extension ZMOperationLoop {

    func messageNonce(fromPushChannelData payload: [AnyHashable: Any]) -> UUID? {
        guard let notificationData = payload[PushChannelKeys.data.rawValue] as? [AnyHashable: Any],
              let rawNotificationType = notificationData[PushChannelKeys.notificationType.rawValue] as? String,
              let notificationType = PushNotificationType(rawValue: rawNotificationType) else {
            return nil
        }

        switch notificationType {
        case .plain, .notice:
            if let data = notificationData[PushChannelKeys.data.rawValue] as? [AnyHashable: Any],
               let rawUUID = data[PushChannelKeys.identifier.rawValue] as? String {
                return UUID(uuidString: rawUUID)
            }
        }

        return nil
    }

}
