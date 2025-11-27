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

import WireAnalytics
import WireDatadog
import WireLogging
import WireSystem

// TODO: the new implementation currently just wraps the old one, rewrite!

struct NewWireDatadogLogger: WireLogHandlerProtocol {

    let additionalAttributes = LogAttributes()
    let logger: WireDatadog

    func log(
        tag: WireLogTag,
        type: WireLogType,
        message: WireLogMessage,
        additionalAttributes: [WireLogAttribute]
    ) {

        var attributes = LogAttributes()
        for additionalAttribute in additionalAttributes {
            if let key = LogAttributesKey(rawValue: additionalAttribute.key) {
                attributes[key] = additionalAttribute.value
            } else {
                assertionFailure(additionalAttribute.key)
            }
        }
        attributes[.tag] = tag.rawValue

        switch type {
        case .debug:
            logger.debug(message.content, attributes: attributes)
        case .info:
            logger.info(message.content, attributes: attributes)
        case .notice:
            logger.notice(message.content, attributes: attributes)
        case .warn:
            logger.warn(message.content, attributes: attributes)
        case .error:
            logger.error(message.content, attributes: attributes)
        case .critical:
            logger.critical(message.content, attributes: attributes)
        }

    }
}

extension WireDatadog: LoggerProtocol {

    public func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .debug,
            message: message,
            attributes: attributes
        )
    }

    public func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .info,
            message: message,
            attributes: attributes
        )
    }

    public func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .notice,
            message: message,
            attributes: attributes
        )
    }

    public func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .warn,
            message: message,
            attributes: attributes
        )
    }

    public func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .error,
            message: message,
            attributes: attributes
        )
    }

    public func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .critical,
            message: message,
            attributes: attributes
        )
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        if let value {
            addAttribute(forKey: key.rawValue, value: value)
        } else {
            removeAttribute(forKey: key.rawValue)
        }
    }

    // MARK: Helpers

    private func log(
        level: WireLogType,
        message: any LogConvertible,
        error: Error? = nil,
        attributes: [LogAttributes] = []
    ) {
        let plainAttributes: [String: any Encodable] = attributes.reduce(into: [:]) { partialResult, logAttribute in
            logAttribute.forEach { item in
                partialResult[item.key.rawValue] = item.value
            }
        }

        log(
            type: level,
            message: message.logDescription,
            error: error,
            attributes: plainAttributes
        )
    }

}
