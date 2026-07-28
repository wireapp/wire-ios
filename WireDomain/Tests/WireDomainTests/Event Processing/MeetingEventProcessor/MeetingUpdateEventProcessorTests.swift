//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireCallingData
import WireCallingDomain
import WireDataModelSupport
import WireDomainSupport
import WireNetwork
import XCTest

@testable import WireDomain

final class MeetingUpdateEventProcessorTests: XCTestCase {

    private var sut: MeetingUpdateEventProcessor!
    private var repository: MeetingRepositoryProtocolMock!
    private var conversationRepository: MockConversationRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        repository = MeetingRepositoryProtocolMock()
        conversationRepository = MockConversationRepositoryProtocol()
        sut = MeetingUpdateEventProcessor(
            repository: repository,
            conversationRepository: conversationRepository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        repository = nil
        conversationRepository = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Pulls_Meeting_From_Repository() async throws {
        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(repository.pullMeetingIdQualifiedIDMeetingReceivedInvocations, [Scaffolding.meetingID])
    }

    func testProcessEvent_It_Throws_When_Pulling_Meeting_Fails() async {
        // Mock

        repository.pullMeetingIdQualifiedIDMeetingThrowableError = MeetingsAPIError.meetingNotFound

        // When / Then

        do {
            try await sut.processEvent(Scaffolding.event)
            XCTFail("expected an error to be thrown")
        } catch {
            XCTAssertEqual(repository.pullMeetingIdQualifiedIDMeetingReceivedInvocations, [Scaffolding.meetingID])
        }
    }

    func testProcessEvent_It_Pulls_Unknown_Conversation_And_Stores_Meeting_Again() async throws {
        // Mock

        repository.pullMeetingIdQualifiedIDMeetingReturnValue = Scaffolding.meeting
        conversationRepository.fetchConversationIdDomain_MockValue = .some(nil)
        conversationRepository.pullConversationIdDomain_MockMethod = { _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(conversationRepository.pullConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(
            conversationRepository.pullConversationIdDomain_Invocations.first?.id,
            Scaffolding.conversationID.id
        )
        XCTAssertEqual(
            conversationRepository.pullConversationIdDomain_Invocations.first?.domain,
            Scaffolding.conversationID.domain
        )
        XCTAssertEqual(repository.storeMeetingMeetingMeetingVoidReceivedInvocations.map(\.id), [Scaffolding.meetingID])
    }

    func testProcessEvent_It_Does_Not_Pull_Conversation_When_It_Is_Already_Known() async throws {
        // Mock

        let coreDataStackHelper = CoreDataStackHelper()
        let coreDataStack = try await coreDataStackHelper.createStack()
        let context = coreDataStack.syncContext
        let conversation = await context.perform {
            ModelHelper().createGroupConversation(
                id: Scaffolding.conversationID.id,
                domain: Scaffolding.conversationID.domain,
                in: context
            )
        }

        repository.pullMeetingIdQualifiedIDMeetingReturnValue = Scaffolding.meeting
        conversationRepository.fetchConversationIdDomain_MockValue = conversation

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertTrue(conversationRepository.pullConversationIdDomain_Invocations.isEmpty)
        XCTAssertTrue(repository.storeMeetingMeetingMeetingVoidReceivedInvocations.isEmpty)

        try coreDataStackHelper.cleanupDirectory()
    }

    private enum Scaffolding {

        static let meetingID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            domain: "example.com"
        )

        static let conversationID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "b57f1571-6a29-4e5d-9d45-a576a2d4b6b7")!,
            domain: "example.com"
        )

        static let meeting = Meeting(
            id: meetingID,
            title: "Team Sync",
            start: Date(timeIntervalSince1970: 1_000_000),
            end: Date(timeIntervalSince1970: 1_003_600),
            recurrence: nil,
            conversationID: conversationID,
            creatorID: WireNetwork.QualifiedID(
                id: UUID(uuidString: "cd2c1465-4bd6-4a5e-9d47-90e99a473ce5")!,
                domain: "example.com"
            )
        )

        static let event = MeetingUpdateEvent(meetingID: meetingID)

    }

}

// duplicate symbols errors prevent using the autogenerated MeetingRepositoryProtocolMock from WireCallingDomainSupport
private final class MeetingRepositoryProtocolMock: MeetingRepositoryProtocol, @unchecked Sendable {
    typealias MeetingRecurrence = WireCallingDomain.MeetingRecurrence
    typealias QualifiedID = WireCallingDomain.QualifiedID

    public init() {}

    // MARK: - observeMeetingChanges

    public var observeMeetingChangesAsyncStreamVoidCallsCount = 0
    public var observeMeetingChangesAsyncStreamVoidCalled: Bool {
        observeMeetingChangesAsyncStreamVoidCallsCount > 0
    }

    public var observeMeetingChangesAsyncStreamVoidReturnValue: AsyncStream<Void>!
    public var observeMeetingChangesAsyncStreamVoidClosure: (() -> AsyncStream<Void>)?

    public func observeMeetingChanges() -> AsyncStream<Void> {
        observeMeetingChangesAsyncStreamVoidCallsCount += 1
        if let observeMeetingChangesAsyncStreamVoidClosure {
            return observeMeetingChangesAsyncStreamVoidClosure()
        } else {
            return observeMeetingChangesAsyncStreamVoidReturnValue
        }
    }

    // MARK: - createMeeting

    public var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingThrowableError: (
        any Error
    )?
    public var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCallsCount = 0
    public var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCalled: Bool {
        createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCallsCount > 0
    }

    public var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedArguments: (
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?
    )?
    public var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedInvocations: [(
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?
    )] = []
    public var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReturnValue: Meeting!
    public var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingClosure: ((
        String,
        Date,
        Date,
        MeetingRecurrence?
    ) async throws -> Meeting)?

    public func createMeeting(
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?
    ) async throws -> Meeting {
        createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCallsCount += 1
        createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedArguments = (
            title: title,
            startTime: startTime,
            endTime: endTime,
            recurrence: recurrence
        )
        createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedInvocations.append((
            title: title,
            startTime: startTime,
            endTime: endTime,
            recurrence: recurrence
        ))
        if let error =
            createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingThrowableError {
            throw error
        }
        if let createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingClosure {
            return try await createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingClosure(
                title,
                startTime,
                endTime,
                recurrence
            )
        } else {
            return createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReturnValue
        }
    }

    // MARK: - updateMeeting

    public var updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingThrowableError: (
        any Error
    )?
    public var updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCallsCount =
        0
    public var updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCalled: Bool {
        updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCallsCount > 0
    }

    public var updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedArguments: (
        id: QualifiedID,
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?
    )?
    public var updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedInvocations: [
        (
            id: QualifiedID,
            title: String,
            startTime: Date,
            endTime: Date,
            recurrence: MeetingRecurrence?
        )
    ] = []
    public var updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReturnValue: Meeting!
    public var updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingClosure: (
        (
            QualifiedID,
            String,
            Date,
            Date,
            MeetingRecurrence?
        ) async throws -> Meeting
    )?

    public func updateMeeting(
        id: QualifiedID,
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?
    ) async throws -> Meeting {
        updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCallsCount += 1
        updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedArguments =
            (
                id: id,
                title: title,
                startTime: startTime,
                endTime: endTime,
                recurrence: recurrence
            )
        updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedInvocations
            .append((
                id: id,
                title: title,
                startTime: startTime,
                endTime: endTime,
                recurrence: recurrence
            ))
        if let error =
            updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingThrowableError {
            throw error
        }
        if let updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingClosure {
            return try await updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingClosure(
                id,
                title,
                startTime,
                endTime,
                recurrence
            )
        } else {
            return updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReturnValue
        }
    }

    // MARK: - storeMeeting

    public var storeMeetingMeetingMeetingVoidCallsCount = 0
    public var storeMeetingMeetingMeetingVoidCalled: Bool {
        storeMeetingMeetingMeetingVoidCallsCount > 0
    }

    public var storeMeetingMeetingMeetingVoidReceivedMeeting: Meeting?
    public var storeMeetingMeetingMeetingVoidReceivedInvocations: [Meeting] = []
    public var storeMeetingMeetingMeetingVoidClosure: ((Meeting) async -> Void)?

    public func storeMeeting(_ meeting: Meeting) async {
        storeMeetingMeetingMeetingVoidCallsCount += 1
        storeMeetingMeetingMeetingVoidReceivedMeeting = meeting
        storeMeetingMeetingMeetingVoidReceivedInvocations.append(meeting)
        await storeMeetingMeetingMeetingVoidClosure?(meeting)
    }

    // MARK: - pullMeeting

    public var pullMeetingIdQualifiedIDMeetingThrowableError: (any Error)?
    public var pullMeetingIdQualifiedIDMeetingCallsCount = 0
    public var pullMeetingIdQualifiedIDMeetingCalled: Bool {
        pullMeetingIdQualifiedIDMeetingCallsCount > 0
    }

    public var pullMeetingIdQualifiedIDMeetingReceivedId: QualifiedID?
    public var pullMeetingIdQualifiedIDMeetingReceivedInvocations: [QualifiedID] = []
    public var pullMeetingIdQualifiedIDMeetingReturnValue: Meeting?
    public var pullMeetingIdQualifiedIDMeetingClosure: ((QualifiedID) async throws -> Meeting?)?

    @discardableResult
    public func pullMeeting(id: QualifiedID) async throws -> Meeting? {
        pullMeetingIdQualifiedIDMeetingCallsCount += 1
        pullMeetingIdQualifiedIDMeetingReceivedId = id
        pullMeetingIdQualifiedIDMeetingReceivedInvocations.append(id)
        if let error = pullMeetingIdQualifiedIDMeetingThrowableError {
            throw error
        }
        if let pullMeetingIdQualifiedIDMeetingClosure {
            return try await pullMeetingIdQualifiedIDMeetingClosure(id)
        } else {
            return pullMeetingIdQualifiedIDMeetingReturnValue
        }
    }

    // MARK: - pullMeetings

    public var pullMeetingsVoidThrowableError: (any Error)?
    public var pullMeetingsVoidCallsCount = 0
    public var pullMeetingsVoidCalled: Bool {
        pullMeetingsVoidCallsCount > 0
    }

    public var pullMeetingsVoidClosure: (() async throws -> Void)?

    public func pullMeetings() async throws {
        pullMeetingsVoidCallsCount += 1
        if let error = pullMeetingsVoidThrowableError {
            throw error
        }
        try await pullMeetingsVoidClosure?()
    }

    // MARK: - deleteLocalMeeting

    public var deleteLocalMeetingIdQualifiedIDVoidCallsCount = 0
    public var deleteLocalMeetingIdQualifiedIDVoidCalled: Bool {
        deleteLocalMeetingIdQualifiedIDVoidCallsCount > 0
    }

    public var deleteLocalMeetingIdQualifiedIDVoidReceivedId: QualifiedID?
    public var deleteLocalMeetingIdQualifiedIDVoidReceivedInvocations: [QualifiedID] = []
    public var deleteLocalMeetingIdQualifiedIDVoidClosure: ((QualifiedID) async -> Void)?

    public func deleteLocalMeeting(id: QualifiedID) async {
        deleteLocalMeetingIdQualifiedIDVoidCallsCount += 1
        deleteLocalMeetingIdQualifiedIDVoidReceivedId = id
        deleteLocalMeetingIdQualifiedIDVoidReceivedInvocations.append(id)
        await deleteLocalMeetingIdQualifiedIDVoidClosure?(id)
    }

    // MARK: - deleteMeeting

    public var deleteMeetingIdQualifiedIDVoidThrowableError: (any Error)?
    public var deleteMeetingIdQualifiedIDVoidCallsCount = 0
    public var deleteMeetingIdQualifiedIDVoidCalled: Bool {
        deleteMeetingIdQualifiedIDVoidCallsCount > 0
    }

    public var deleteMeetingIdQualifiedIDVoidReceivedId: QualifiedID?
    public var deleteMeetingIdQualifiedIDVoidReceivedInvocations: [QualifiedID] = []
    public var deleteMeetingIdQualifiedIDVoidClosure: ((QualifiedID) async throws -> Void)?

    public func deleteMeeting(id: QualifiedID) async throws {
        deleteMeetingIdQualifiedIDVoidCallsCount += 1
        deleteMeetingIdQualifiedIDVoidReceivedId = id
        deleteMeetingIdQualifiedIDVoidReceivedInvocations.append(id)
        if let error = deleteMeetingIdQualifiedIDVoidThrowableError {
            throw error
        }
        try await deleteMeetingIdQualifiedIDVoidClosure?(id)
    }

    // MARK: - fetchMeetings

    public var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingThrowableError: (any Error)?
    public var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingCallsCount = 0
    public var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingCalled: Bool {
        fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingCallsCount > 0
    }

    public var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReceivedArguments: (
        range: Range<Date>,
        offset: Int,
        limit: Int
    )?
    public var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReceivedInvocations: [(
        range: Range<Date>,
        offset: Int,
        limit: Int
    )] = []
    public var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue: [Meeting]!
    public var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingClosure: ((Range<Date>, Int, Int) async throws
        -> [Meeting])?

    public func fetchMeetings(in range: Range<Date>, offset: Int, limit: Int) async throws -> [Meeting] {
        fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingCallsCount += 1
        fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReceivedArguments = (
            range: range,
            offset: offset,
            limit: limit
        )
        fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReceivedInvocations.append((
            range: range,
            offset: offset,
            limit: limit
        ))
        if let error = fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingThrowableError {
            throw error
        }
        if let fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingClosure {
            return try await fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingClosure(range, offset, limit)
        } else {
            return fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue
        }
    }

    // MARK: - hasUpcomingMeetings

    public var hasUpcomingMeetingsAfterDateDateBoolThrowableError: (any Error)?
    public var hasUpcomingMeetingsAfterDateDateBoolCallsCount = 0
    public var hasUpcomingMeetingsAfterDateDateBoolCalled: Bool {
        hasUpcomingMeetingsAfterDateDateBoolCallsCount > 0
    }

    public var hasUpcomingMeetingsAfterDateDateBoolReceivedDate: Date?
    public var hasUpcomingMeetingsAfterDateDateBoolReceivedInvocations: [Date] = []
    public var hasUpcomingMeetingsAfterDateDateBoolReturnValue: Bool!
    public var hasUpcomingMeetingsAfterDateDateBoolClosure: ((Date) async throws -> Bool)?

    public func hasUpcomingMeetings(after date: Date) async throws -> Bool {
        hasUpcomingMeetingsAfterDateDateBoolCallsCount += 1
        hasUpcomingMeetingsAfterDateDateBoolReceivedDate = date
        hasUpcomingMeetingsAfterDateDateBoolReceivedInvocations.append(date)
        if let error = hasUpcomingMeetingsAfterDateDateBoolThrowableError {
            throw error
        }
        if let hasUpcomingMeetingsAfterDateDateBoolClosure {
            return try await hasUpcomingMeetingsAfterDateDateBoolClosure(date)
        } else {
            return hasUpcomingMeetingsAfterDateDateBoolReturnValue
        }
    }

}
