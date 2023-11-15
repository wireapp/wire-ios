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
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

@testable import WireSyncEngine

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
