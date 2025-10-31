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

public import WireLogging

public final class MockWireLoggerProtocol: WireLoggerProtocol, @unchecked Sendable { // TODO: replace with WireLoggerProtocolMock

    // MARK: - Life cycle

    public init() {}

    // MARK: - tag

    public var tag: Tag {
        get { return underlyingTag }
        set(value) { underlyingTag = value }
    }

    public var underlyingTag: Tag!

    // MARK: - debug

    public var debug_Invocations: [WireLogMessage] = []
    public var debug_MockMethod: ((WireLogMessage) -> Void)?

    public func debug(_ message: WireLogMessage) {
        debug_Invocations.append(message)

        guard let mock = debug_MockMethod else {
            fatalError("no mock for `debug`")
        }

        mock(message)
    }

    // MARK: - info

    public var info_Invocations: [WireLogMessage] = []
    public var info_MockMethod: ((WireLogMessage) -> Void)?

    public func info(_ message: WireLogMessage) {
        info_Invocations.append(message)

        guard let mock = info_MockMethod else {
            fatalError("no mock for `info`")
        }

        mock(message)
    }

    // MARK: - notice

    public var notice_Invocations: [WireLogMessage] = []
    public var notice_MockMethod: ((WireLogMessage) -> Void)?

    public func notice(_ message: WireLogMessage) {
        notice_Invocations.append(message)

        guard let mock = notice_MockMethod else {
            fatalError("no mock for `notice`")
        }

        mock(message)
    }

    // MARK: - warn

    public var warn_Invocations: [WireLogMessage] = []
    public var warn_MockMethod: ((WireLogMessage) -> Void)?

    public func warn(_ message: WireLogMessage) {
        warn_Invocations.append(message)

        guard let mock = warn_MockMethod else {
            fatalError("no mock for `warn`")
        }

        mock(message)
    }

    // MARK: - error

    public var error_Invocations: [WireLogMessage] = []
    public var error_MockMethod: ((WireLogMessage) -> Void)?

    public func error(_ message: WireLogMessage) {
        error_Invocations.append(message)

        guard let mock = error_MockMethod else {
            fatalError("no mock for `error`")
        }

        mock(message)
    }

    // MARK: - critical

    public var critical_Invocations: [WireLogMessage] = []
    public var critical_MockMethod: ((WireLogMessage) -> Void)?

    public func critical(_ message: WireLogMessage) {
        critical_Invocations.append(message)

        guard let mock = critical_MockMethod else {
            fatalError("no mock for `critical`")
        }

        mock(message)
    }

}
