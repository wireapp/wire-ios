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

/// Abstraction of a convenience interface to the Wire logging systems.
public protocol WireLoggerProtocol: Sendable {
    typealias Tag = WireLoggerTag

    var tag: Tag { get }

    func debug(_ message: WireLogMessage)
    func info(_ message: WireLogMessage)
    func notice(_ message: WireLogMessage)
    func warn(_ message: WireLogMessage)
    func error(_ message: WireLogMessage)
    func critical(_ message: WireLogMessage)
}
