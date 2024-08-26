////
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
    public var sendMessageMessage_MockError: Error?
    public var sendMessageMessage_MockMethod: ((any SendableMessage) async throws -> Void)?

    public func sendMessage(message: any SendableMessage) async throws {
        sendMessageMessage_Invocations.append(message)

        if let error = sendMessageMessage_MockError {
            throw error
        }

        guard let mock = sendMessageMessage_MockMethod else {
            fatalError("no mock for `sendMessageMessage`")
        }

        try await mock(message)
    }

    // MARK: - broadcastMessage

    public var broadcastMessageMessage_Invocations: [any ProteusMessage] = []
    public var broadcastMessageMessage_MockError: Error?
    public var broadcastMessageMessage_MockMethod: ((any ProteusMessage) async throws -> Void)?

    public func broadcastMessage(message: any ProteusMessage) async throws {
        broadcastMessageMessage_Invocations.append(message)

        if let error = broadcastMessageMessage_MockError {
            throw error
        }

        guard let mock = broadcastMessageMessage_MockMethod else {
            fatalError("no mock for `broadcastMessageMessage`")
        }

        try await mock(message)
    }

}

public class MockSessionEstablisherInterface: SessionEstablisherInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - establishSession

    public var establishSessionWithApiVersion_Invocations: [(clients: Set<QualifiedClientID>, apiVersion: APIVersion)] = []
    public var establishSessionWithApiVersion_MockError: Error?
    public var establishSessionWithApiVersion_MockMethod: ((Set<QualifiedClientID>, APIVersion) async throws -> Void)?

    public func establishSession(with clients: Set<QualifiedClientID>, apiVersion: APIVersion) async throws {
        establishSessionWithApiVersion_Invocations.append((clients: clients, apiVersion: apiVersion))

        if let error = establishSessionWithApiVersion_MockError {
            throw error
        }

        guard let mock = establishSessionWithApiVersion_MockMethod else {
            fatalError("no mock for `establishSessionWithApiVersion`")
        }

        try await mock(clients, apiVersion)
    }

}
