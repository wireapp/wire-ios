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

import Combine
import WireAPI
import Foundation
@testable import WireDomain

class MockUpdateEventsRepositoryProtocol: UpdateEventsRepositoryProtocol {

    // MARK: - Life cycle



    // MARK: - observePendingEvents

    var observePendingEvents_Invocations: [Void] = []
    var observePendingEvents_MockMethod: (() -> AnyPublisher<[UpdateEvent], Never>)?
    var observePendingEvents_MockValue: AnyPublisher<[UpdateEvent], Never>?

    func observePendingEvents() -> AnyPublisher<[UpdateEvent], Never> {
        observePendingEvents_Invocations.append(())

        if let mock = observePendingEvents_MockMethod {
            return mock()
        } else if let mock = observePendingEvents_MockValue {
            return mock
        } else {
            fatalError("no mock for `observePendingEvents`")
        }
    }

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

    // MARK: - fetchLastEventEnvelopeID

    var fetchLastEventEnvelopeID_Invocations: [Void] = []
    var fetchLastEventEnvelopeID_MockMethod: (() -> UUID?)?
    var fetchLastEventEnvelopeID_MockValue: UUID??

    func fetchLastEventEnvelopeID() -> UUID? {
        fetchLastEventEnvelopeID_Invocations.append(())

        if let mock = fetchLastEventEnvelopeID_MockMethod {
            return mock()
        } else if let mock = fetchLastEventEnvelopeID_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchLastEventEnvelopeID`")
        }
    }

    // MARK: - pullLastEventID

    var pullLastEventID_Invocations: [Void] = []
    var pullLastEventID_MockError: Error?
    var pullLastEventID_MockMethod: (() async throws -> Void)?

    func pullLastEventID() async throws {
        pullLastEventID_Invocations.append(())

        if let error = pullLastEventID_MockError {
            throw error
        }

        guard let mock = pullLastEventID_MockMethod else {
            fatalError("no mock for `pullLastEventID`")
        }

        try await mock()
    }

}
