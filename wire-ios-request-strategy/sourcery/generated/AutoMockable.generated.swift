// Generated using Sourcery 2.1.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

@testable import WireRequestStrategy

public class MockMessageSenderInterface: MessageSenderInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - sendMessage

    public var sendMessageMessage_Invocations: [any SendableMessage] = []
    public var sendMessageMessage_MockMethod: ((any SendableMessage) async -> Swift.Result<Void, MessageSendError>)?
    public var sendMessageMessage_MockValue: Swift.Result<Void, MessageSendError>?

    public func sendMessage(message: any SendableMessage) async -> Swift.Result<Void, MessageSendError> {
        sendMessageMessage_Invocations.append(message)

        if let mock = sendMessageMessage_MockMethod {
            return await mock(message)
        } else if let mock = sendMessageMessage_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendMessageMessage`")
        }
    }

}
