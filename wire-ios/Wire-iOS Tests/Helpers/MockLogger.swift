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
@testable import WireSystem

final class MockLogger: LoggerProtocol {
    typealias LoggingCompletion = ((WireSystem.LogConvertible, WireSystem.LogAttributes?) -> Void)
    var debugIsCalled: LoggingCompletion?
    var infoIsCalled: LoggingCompletion?
    var noticeIsCalled: LoggingCompletion?
    var warnIsCalled: LoggingCompletion?
    var errorIsCalled: LoggingCompletion?
    var criticalIsCalled: LoggingCompletion?

    func debug(_ message: WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {
        debugIsCalled?(message, attributes)
    }

    func info(_ message: WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {
        infoIsCalled?(message, attributes)
    }

    func notice(_ message: WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {
        noticeIsCalled?(message, attributes)
    }

    func warn(_ message: WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {
        warnIsCalled?(message, attributes)
    }

    func error(_ message: WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {
        errorIsCalled?(message, attributes)
    }

    func critical(_ message: WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {
        criticalIsCalled?(message, attributes)
    }
}
