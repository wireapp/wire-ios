// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import WireDataModel
import WireAPI

@testable import WireDomain





















class MockProteusMessageDecryptorProtocol: ProteusMessageDecryptorProtocol {

    // MARK: - Life cycle



    // MARK: - decryptedEventData

    var decryptedEventDataFrom_Invocations: [ConversationProteusMessageAddEvent] = []
    var decryptedEventDataFrom_MockError: Error?
    var decryptedEventDataFrom_MockMethod: ((ConversationProteusMessageAddEvent) async throws -> ConversationProteusMessageAddEvent)?
    var decryptedEventDataFrom_MockValue: ConversationProteusMessageAddEvent?

    func decryptedEventData(from eventData: ConversationProteusMessageAddEvent) async throws -> ConversationProteusMessageAddEvent {
        decryptedEventDataFrom_Invocations.append(eventData)

        if let error = decryptedEventDataFrom_MockError {
            throw error
        }

        if let mock = decryptedEventDataFrom_MockMethod {
            return try await mock(eventData)
        } else if let mock = decryptedEventDataFrom_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptedEventDataFrom`")
        }
    }

}

class MockUpdateEventDecryptorProtocol: UpdateEventDecryptorProtocol {

    // MARK: - Life cycle



    // MARK: - decryptEvents

    var decryptEventsIn_Invocations: [UpdateEventEnvelope] = []
    var decryptEventsIn_MockError: Error?
    var decryptEventsIn_MockMethod: ((UpdateEventEnvelope) async throws -> [UpdateEvent])?
    var decryptEventsIn_MockValue: [UpdateEvent]?

    func decryptEvents(in eventEnvelope: UpdateEventEnvelope) async throws -> [UpdateEvent] {
        decryptEventsIn_Invocations.append(eventEnvelope)

        if let error = decryptEventsIn_MockError {
            throw error
        }

        if let mock = decryptEventsIn_MockMethod {
            return try await mock(eventEnvelope)
        } else if let mock = decryptEventsIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptEventsIn`")
        }
    }

}

public class MockUserRepositoryProtocol: UserRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchSelfUser

    public var fetchSelfUser_Invocations: [Void] = []
    public var fetchSelfUser_MockMethod: (() -> ZMUser)?
    public var fetchSelfUser_MockValue: ZMUser?

    public func fetchSelfUser() -> ZMUser {
        fetchSelfUser_Invocations.append(())

        if let mock = fetchSelfUser_MockMethod {
            return mock()
        } else if let mock = fetchSelfUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfUser`")
        }
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
