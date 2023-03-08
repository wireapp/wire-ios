//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import OSLog
import UserNotifications

extension Loggable {

    var logger: os.Logger {

        return os.Logger(category: String(describing: type(of: self))
)
    }

}

protocol Loggable {

    var logger: os.Logger { get }

}

extension os.Logger {

    private static var subsystem = "simple nse"

    init(category: String) {
        self.init(subsystem: Self.subsystem, category: category)
    }

}

extension OSLogInterpolation {

    mutating func appendInterpolation(_ request: UNNotificationRequest) {
        appendInterpolation(String(request.identifier), align: .none, privacy: .public)
    }

}
