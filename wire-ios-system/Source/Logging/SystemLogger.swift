////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

struct SystemLogger: LoggerProtocol {
    func debug(_ message: LogConvertible, attributes: LogAttributes?) {
        os_log(.debug, log: .default, "\(message.logDescription)")
    }

    func info(_ message: LogConvertible, attributes: LogAttributes?) {
        os_log(.info, log: .default, "\(message.logDescription)")
    }

    func notice(_ message: LogConvertible, attributes: LogAttributes?) {
        os_log(.default, log: .default, "\(message.logDescription)")
    }

    func warn(_ message: LogConvertible, attributes: LogAttributes?) {
        os_log(.fault, log: .default, "\(message.logDescription)")
    }

    func error(_ message: LogConvertible, attributes: LogAttributes?) {
        os_log(.error, log: .default, "\(message.logDescription)")
    }

    func critical(_ message: LogConvertible, attributes: LogAttributes?) {
        os_log(.fault, log: .default, "\(message.logDescription)")
    }
}
