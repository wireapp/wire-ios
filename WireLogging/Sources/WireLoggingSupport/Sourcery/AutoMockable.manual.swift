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

public class WireTaggedLoggerProtocolMock: WireTaggedLoggerProtocol, @unchecked Sendable {

    public init() {}

    public var tag: WireLogTag {
        get { return underlyingTag }
        set(value) { underlyingTag = value }
    }
    public var underlyingTag: (WireLogTag)!


    //MARK: - debug

    public var debugMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount = 0
    public var debugMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCalled: Bool {
        return debugMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount > 0
    }
    public var debugMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments: (message: WireLogMessage, additionalAttributes: [WireLogAttribute])?
    public var debugMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations: [(message: WireLogMessage, additionalAttributes: [WireLogAttribute])] = []
    public var debugMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure: ((WireLogMessage, [WireLogAttribute]) -> Void)?

    public func debug(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        debugMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount += 1
        debugMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments = (message: message, additionalAttributes: additionalAttributes)
        debugMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations.append((message: message, additionalAttributes: additionalAttributes))
        debugMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure?(message, additionalAttributes)
    }

    //MARK: - info

    public var infoMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount = 0
    public var infoMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCalled: Bool {
        return infoMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount > 0
    }
    public var infoMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments: (message: WireLogMessage, additionalAttributes: [WireLogAttribute])?
    public var infoMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations: [(message: WireLogMessage, additionalAttributes: [WireLogAttribute])] = []
    public var infoMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure: ((WireLogMessage, [WireLogAttribute]) -> Void)?

    public func info(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        infoMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount += 1
        infoMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments = (message: message, additionalAttributes: additionalAttributes)
        infoMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations.append((message: message, additionalAttributes: additionalAttributes))
        infoMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure?(message, additionalAttributes)
    }

    //MARK: - notice

    public var noticeMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount = 0
    public var noticeMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCalled: Bool {
        return noticeMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount > 0
    }
    public var noticeMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments: (message: WireLogMessage, additionalAttributes: [WireLogAttribute])?
    public var noticeMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations: [(message: WireLogMessage, additionalAttributes: [WireLogAttribute])] = []
    public var noticeMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure: ((WireLogMessage, [WireLogAttribute]) -> Void)?

    public func notice(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        noticeMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount += 1
        noticeMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments = (message: message, additionalAttributes: additionalAttributes)
        noticeMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations.append((message: message, additionalAttributes: additionalAttributes))
        noticeMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure?(message, additionalAttributes)
    }

    //MARK: - warn

    public var warnMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount = 0
    public var warnMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCalled: Bool {
        return warnMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount > 0
    }
    public var warnMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments: (message: WireLogMessage, additionalAttributes: [WireLogAttribute])?
    public var warnMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations: [(message: WireLogMessage, additionalAttributes: [WireLogAttribute])] = []
    public var warnMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure: ((WireLogMessage, [WireLogAttribute]) -> Void)?

    public func warn(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        warnMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount += 1
        warnMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments = (message: message, additionalAttributes: additionalAttributes)
        warnMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations.append((message: message, additionalAttributes: additionalAttributes))
        warnMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure?(message, additionalAttributes)
    }

    //MARK: - error

    public var errorMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount = 0
    public var errorMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCalled: Bool {
        return errorMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount > 0
    }
    public var errorMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments: (message: WireLogMessage, additionalAttributes: [WireLogAttribute])?
    public var errorMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations: [(message: WireLogMessage, additionalAttributes: [WireLogAttribute])] = []
    public var errorMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure: ((WireLogMessage, [WireLogAttribute]) -> Void)?

    public func error(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        errorMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount += 1
        errorMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments = (message: message, additionalAttributes: additionalAttributes)
        errorMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations.append((message: message, additionalAttributes: additionalAttributes))
        errorMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure?(message, additionalAttributes)
    }

    //MARK: - critical

    public var criticalMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount = 0
    public var criticalMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCalled: Bool {
        return criticalMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount > 0
    }
    public var criticalMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments: (message: WireLogMessage, additionalAttributes: [WireLogAttribute])?
    public var criticalMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations: [(message: WireLogMessage, additionalAttributes: [WireLogAttribute])] = []
    public var criticalMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure: ((WireLogMessage, [WireLogAttribute]) -> Void)?

    public func critical(_ message: WireLogMessage, _ additionalAttributes: WireLogAttribute...) {
        criticalMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidCallsCount += 1
        criticalMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedArguments = (message: message, additionalAttributes: additionalAttributes)
        criticalMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidReceivedInvocations.append((message: message, additionalAttributes: additionalAttributes))
        criticalMessageWireLogMessageAdditionalAttributesWireLogAttributeVoidClosure?(message, additionalAttributes)
    }


}
