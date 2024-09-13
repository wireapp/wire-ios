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

final class OperationLoopNewRequestObserver {
    var token: NSObjectProtocol?
    var notifications = [Notification]()
    private var notificationCenter = NotificationCenter.default
    private var newRequestNotification = "RequestAvailableNotification"

    init() {
        self.token = notificationCenter.addObserver(
            forName: Notification.Name(rawValue: newRequestNotification),
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.notifications.append(note)
        }
    }

    deinit {
        notifications.removeAll()
        if let token {
            notificationCenter.removeObserver(token)
        }
    }
}
