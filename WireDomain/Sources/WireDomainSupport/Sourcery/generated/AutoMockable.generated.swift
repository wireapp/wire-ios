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

import WireAPI
import WireDataModel

@testable import WireDomain





















class MockConnectionsLocalStoreProtocol: ConnectionsLocalStoreProtocol {

    // MARK: - Life cycle



    // MARK: - storeConnection

    var storeConnection_Invocations: [Connection] = []
    var storeConnection_MockError: Error?
    var storeConnection_MockMethod: ((Connection) async throws -> Void)?

    func storeConnection(_ connectionPayload: Connection) async throws {
        storeConnection_Invocations.append(connectionPayload)

        if let error = storeConnection_MockError {
            throw error
        }

        guard let mock = storeConnection_MockMethod else {
            fatalError("no mock for `storeConnection`")
        }

        try await mock(connectionPayload)
    }

    // MARK: - deleteFederationConnection

    var deleteFederationConnectionWith_Invocations: [String] = []
    var deleteFederationConnectionWith_MockError: Error?
    var deleteFederationConnectionWith_MockMethod: ((String) async throws -> Void)?

    func deleteFederationConnection(with domain: String) async throws {
        deleteFederationConnectionWith_Invocations.append(domain)

        if let error = deleteFederationConnectionWith_MockError {
            throw error
        }

        guard let mock = deleteFederationConnectionWith_MockMethod else {
            fatalError("no mock for `deleteFederationConnectionWith`")
        }

        try await mock(domain)
    }

    // MARK: - removeFederationConnection

    var removeFederationConnectionBetweenAnd_Invocations: [(domain: String, otherDomain: String)] = []
    var removeFederationConnectionBetweenAnd_MockMethod: ((String, String) async -> Void)?

    func removeFederationConnection(between domain: String, and otherDomain: String) async {
        removeFederationConnectionBetweenAnd_Invocations.append((domain: domain, otherDomain: otherDomain))

        guard let mock = removeFederationConnectionBetweenAnd_MockMethod else {
            fatalError("no mock for `removeFederationConnectionBetweenAnd`")
        }

        await mock(domain, otherDomain)
    }

}

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

public class MockSelfUserProviderProtocol: SelfUserProviderProtocol {

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

class MockUpdateEventProcessorProtocol: UpdateEventProcessorProtocol {

    // MARK: - Life cycle



    // MARK: - processEvent

    var processEvent_Invocations: [UpdateEvent] = []
    var processEvent_MockError: Error?
    var processEvent_MockMethod: ((UpdateEvent) async throws -> Void)?

    func processEvent(_ event: UpdateEvent) async throws {
        processEvent_Invocations.append(event)

        if let error = processEvent_MockError {
            throw error
        }

        guard let mock = processEvent_MockMethod else {
            fatalError("no mock for `processEvent`")
        }

        try await mock(event)
    }

}

class MockUpdateEventsRepositoryProtocol: UpdateEventsRepositoryProtocol {

    // MARK: - Life cycle



    // MARK: - pullPendingEvents

    var pullPendingEvents_Invocations: [Void] = []
    var pullPendingEvents_MockError: Error?
    var pullPendingEvents_MockMethod: (() async throws -> Void)?

    func pullPendingEvents() async throws {
        pullPendingEvents_Invocations.append(())

        if let error = pullPendingEvents_MockError {
            throw error
        }

        guard let mock = pullPendingEvents_MockMethod else {
            fatalError("no mock for `pullPendingEvents`")
        }

        try await mock()
    }

    // MARK: - fetchNextPendingEvents

    var fetchNextPendingEventsLimit_Invocations: [UInt] = []
    var fetchNextPendingEventsLimit_MockError: Error?
    var fetchNextPendingEventsLimit_MockMethod: ((UInt) async throws -> [UpdateEventEnvelope])?
    var fetchNextPendingEventsLimit_MockValue: [UpdateEventEnvelope]?

    func fetchNextPendingEvents(limit: UInt) async throws -> [UpdateEventEnvelope] {
        fetchNextPendingEventsLimit_Invocations.append(limit)

        if let error = fetchNextPendingEventsLimit_MockError {
            throw error
        }

        if let mock = fetchNextPendingEventsLimit_MockMethod {
            return try await mock(limit)
        } else if let mock = fetchNextPendingEventsLimit_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchNextPendingEventsLimit`")
        }
    }

    // MARK: - deleteNextPendingEvents

    var deleteNextPendingEventsLimit_Invocations: [UInt] = []
    var deleteNextPendingEventsLimit_MockError: Error?
    var deleteNextPendingEventsLimit_MockMethod: ((UInt) async throws -> Void)?

    func deleteNextPendingEvents(limit: UInt) async throws {
        deleteNextPendingEventsLimit_Invocations.append(limit)

        if let error = deleteNextPendingEventsLimit_MockError {
            throw error
        }

        guard let mock = deleteNextPendingEventsLimit_MockMethod else {
            fatalError("no mock for `deleteNextPendingEventsLimit`")
        }

        try await mock(limit)
    }

    // MARK: - startBufferingLiveEvents

    var startBufferingLiveEvents_Invocations: [Void] = []
    var startBufferingLiveEvents_MockError: Error?
    var startBufferingLiveEvents_MockMethod: (() async throws -> AsyncThrowingStream<UpdateEventEnvelope, Error>)?
    var startBufferingLiveEvents_MockValue: AsyncThrowingStream<UpdateEventEnvelope, Error>?

    func startBufferingLiveEvents() async throws -> AsyncThrowingStream<UpdateEventEnvelope, Error> {
        startBufferingLiveEvents_Invocations.append(())

        if let error = startBufferingLiveEvents_MockError {
            throw error
        }

        if let mock = startBufferingLiveEvents_MockMethod {
            return try await mock()
        } else if let mock = startBufferingLiveEvents_MockValue {
            return mock
        } else {
            fatalError("no mock for `startBufferingLiveEvents`")
        }
    }

    // MARK: - stopReceivingLiveEvents

    var stopReceivingLiveEvents_Invocations: [Void] = []
    var stopReceivingLiveEvents_MockMethod: (() async -> Void)?

    func stopReceivingLiveEvents() async {
        stopReceivingLiveEvents_Invocations.append(())

        guard let mock = stopReceivingLiveEvents_MockMethod else {
            fatalError("no mock for `stopReceivingLiveEvents`")
        }

        await mock()
    }

    // MARK: - storeLastEventEnvelopeID

    var storeLastEventEnvelopeID_Invocations: [UUID] = []
    var storeLastEventEnvelopeID_MockMethod: ((UUID) -> Void)?

    func storeLastEventEnvelopeID(_ id: UUID) {
        storeLastEventEnvelopeID_Invocations.append(id)

        guard let mock = storeLastEventEnvelopeID_MockMethod else {
            fatalError("no mock for `storeLastEventEnvelopeID`")
        }

        mock(id)
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

    // MARK: - pullKnownUsers

    public var pullKnownUsers_Invocations: [Void] = []
    public var pullKnownUsers_MockError: Error?
    public var pullKnownUsers_MockMethod: (() async throws -> Void)?

    public func pullKnownUsers() async throws {
        pullKnownUsers_Invocations.append(())

        if let error = pullKnownUsers_MockError {
            throw error
        }

        guard let mock = pullKnownUsers_MockMethod else {
            fatalError("no mock for `pullKnownUsers`")
        }

        try await mock()
    }

    // MARK: - pullUsers

    public var pullUsersUserIDs_Invocations: [[WireDataModel.QualifiedID]] = []
    public var pullUsersUserIDs_MockError: Error?
    public var pullUsersUserIDs_MockMethod: (([WireDataModel.QualifiedID]) async throws -> Void)?

    public func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws {
        pullUsersUserIDs_Invocations.append(userIDs)

        if let error = pullUsersUserIDs_MockError {
            throw error
        }

        guard let mock = pullUsersUserIDs_MockMethod else {
            fatalError("no mock for `pullUsersUserIDs`")
        }

        try await mock(userIDs)
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
