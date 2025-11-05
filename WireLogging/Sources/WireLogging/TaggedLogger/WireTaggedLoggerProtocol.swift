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

public protocol WireTaggedLoggerProtocol: Sendable {

    var tag: WireLogTag { get }

    func debug(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...)
    func info(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...)
    func notice(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...)
    func warn(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...)
    func error(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...)
    func critical(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...)

}
