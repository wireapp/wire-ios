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

public struct WireTaggedLogger<
    LogHandler: WireLogHandlerProtocol
> {

    public var tag: WireLogTag
    public var handler: LogHandler

    public init(
        tag: WireLogTag,
        handler: LogHandler
    ) {
        self.tag = tag
        self.handler = handler
    }

    private func log(
        _ type: WireLogType,
        _ message: WireLogMessage,
        _ additionalAttributes: [WireLogAttribute]
    ) {
        handler.log(
            tag: tag,
            type: type,
            message: message,
            additionalAttributes: additionalAttributes
        )
    }

}

// MARK: -

extension WireTaggedLogger: WireTaggedLoggerProtocol {

    public func debug(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        log(.debug, message, additionalAttributes)
    }

    public func info(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        log(.info, message, additionalAttributes)
    }

    public func notice(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        log(.notice, message, additionalAttributes)
    }

    public func warn(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        log(.warn, message, additionalAttributes)
    }

    public func error(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        log(.error, message, additionalAttributes)
    }

    public func critical(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        log(.critical, message, additionalAttributes)
    }

}
