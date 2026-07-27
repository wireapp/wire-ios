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

final class MeetingCreateEventProcessorTests: XCTestCase {

    private var sut: MeetingCreateEventProcessor!
    private var repository: MeetingRepositoryProtocolMock!
    private var conversationRepository: MockConversationRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        repository = MeetingRepositoryProtocolMock()
        conversationRepository = MockConversationRepositoryProtocol()
        sut = MeetingCreateEventProcessor(
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
            conversation: MeetingConversation(qualifiedID: conversationID, participants: []),
            creatorID: WireNetwork.QualifiedID(
                id: UUID(uuidString: "cd2c1465-4bd6-4a5e-9d47-90e99a473ce5")!,
                domain: "example.com"
            )
        )

        static let event = MeetingCreateEvent(meetingID: meetingID)

    }

}

// duplicate symbols errors prevent using the autogenerated MeetingRepositoryProtocolMock from WireCallingDomainSupport
private final class MeetingRepositoryProtocolMock: MeetingRepositoryProtocol, @unchecked Sendable {
    typealias MeetingRecurrence = WireCallingDomain.MeetingRecurrence
    typealias QualifiedID = WireCallingDomain.QualifiedID

    init() {}

    // MARK: - observeMeetingChanges

    var observeMeetingChangesAsyncStreamVoidCallsCount = 0
    var observeMeetingChangesAsyncStreamVoidCalled: Bool {
        observeMeetingChangesAsyncStreamVoidCallsCount > 0
    }

    var observeMeetingChangesAsyncStreamVoidReturnValue: AsyncStream<Void>!
    var observeMeetingChangesAsyncStreamVoidClosure: (() -> AsyncStream<Void>)?

    func observeMeetingChanges() -> AsyncStream<Void> {
        observeMeetingChangesAsyncStreamVoidCallsCount += 1
        if let observeMeetingChangesAsyncStreamVoidClosure {
            return observeMeetingChangesAsyncStreamVoidClosure()
        } else {
            return observeMeetingChangesAsyncStreamVoidReturnValue
        }
    }

    // MARK: - createMeeting

    var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingThrowableError: (any Error)?
    var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCallsCount = 0
    var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCalled: Bool {
        createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCallsCount > 0
    }

    var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedArguments: (
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?
    )?
    var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedInvocations: [(
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?
    )] = []
    var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReturnValue: Meeting!
    var createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingClosure: ((
        String,
        Date,
        Date,
        MeetingRecurrence?
    ) async throws -> Meeting)?

    func createMeeting(
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

    // MARK: - storeMeeting

    var storeMeetingMeetingMeetingVoidCallsCount = 0
    var storeMeetingMeetingMeetingVoidCalled: Bool {
        storeMeetingMeetingMeetingVoidCallsCount > 0
    }

    var storeMeetingMeetingMeetingVoidReceivedMeeting: Meeting?
    var storeMeetingMeetingMeetingVoidReceivedInvocations: [Meeting] = []
    var storeMeetingMeetingMeetingVoidClosure: ((Meeting) async -> Void)?

    func storeMeeting(_ meeting: Meeting) async {
        storeMeetingMeetingMeetingVoidCallsCount += 1
        storeMeetingMeetingMeetingVoidReceivedMeeting = meeting
        storeMeetingMeetingMeetingVoidReceivedInvocations.append(meeting)
        await storeMeetingMeetingMeetingVoidClosure?(meeting)
    }

    // MARK: - pullMeeting

    var pullMeetingIdQualifiedIDMeetingThrowableError: (any Error)?
    var pullMeetingIdQualifiedIDMeetingCallsCount = 0
    var pullMeetingIdQualifiedIDMeetingCalled: Bool {
        pullMeetingIdQualifiedIDMeetingCallsCount > 0
    }

    var pullMeetingIdQualifiedIDMeetingReceivedId: QualifiedID?
    var pullMeetingIdQualifiedIDMeetingReceivedInvocations: [QualifiedID] = []
    var pullMeetingIdQualifiedIDMeetingReturnValue: Meeting?
    var pullMeetingIdQualifiedIDMeetingClosure: ((QualifiedID) async throws -> Meeting?)?

    func pullMeeting(id: QualifiedID) async throws -> Meeting? {
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

    var pullMeetingsVoidThrowableError: (any Error)?
    var pullMeetingsVoidCallsCount = 0
    var pullMeetingsVoidCalled: Bool {
        pullMeetingsVoidCallsCount > 0
    }

    var pullMeetingsVoidClosure: (() async throws -> Void)?

    func pullMeetings() async throws {
        pullMeetingsVoidCallsCount += 1
        if let error = pullMeetingsVoidThrowableError {
            throw error
        }
        try await pullMeetingsVoidClosure?()
    }

    // MARK: - deleteLocalMeeting

    var deleteLocalMeetingIdQualifiedIDVoidCallsCount = 0
    var deleteLocalMeetingIdQualifiedIDVoidCalled: Bool {
        deleteLocalMeetingIdQualifiedIDVoidCallsCount > 0
    }

    var deleteLocalMeetingIdQualifiedIDVoidReceivedId: QualifiedID?
    var deleteLocalMeetingIdQualifiedIDVoidReceivedInvocations: [QualifiedID] = []
    var deleteLocalMeetingIdQualifiedIDVoidClosure: ((QualifiedID) async -> Void)?

    func deleteLocalMeeting(id: QualifiedID) async {
        deleteLocalMeetingIdQualifiedIDVoidCallsCount += 1
        deleteLocalMeetingIdQualifiedIDVoidReceivedId = id
        deleteLocalMeetingIdQualifiedIDVoidReceivedInvocations.append(id)
        await deleteLocalMeetingIdQualifiedIDVoidClosure?(id)
    }

    // MARK: - deleteMeeting

    var deleteMeetingIdQualifiedIDVoidThrowableError: (any Error)?
    var deleteMeetingIdQualifiedIDVoidCallsCount = 0
    var deleteMeetingIdQualifiedIDVoidCalled: Bool {
        deleteMeetingIdQualifiedIDVoidCallsCount > 0
    }

    var deleteMeetingIdQualifiedIDVoidReceivedId: QualifiedID?
    var deleteMeetingIdQualifiedIDVoidReceivedInvocations: [QualifiedID] = []
    var deleteMeetingIdQualifiedIDVoidClosure: ((QualifiedID) async throws -> Void)?

    func deleteMeeting(id: QualifiedID) async throws {
        deleteMeetingIdQualifiedIDVoidCallsCount += 1
        deleteMeetingIdQualifiedIDVoidReceivedId = id
        deleteMeetingIdQualifiedIDVoidReceivedInvocations.append(id)
        if let error = deleteMeetingIdQualifiedIDVoidThrowableError {
            throw error
        }
        try await deleteMeetingIdQualifiedIDVoidClosure?(id)
    }

    // MARK: - fetchMeetings

    var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingThrowableError: (any Error)?
    var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingCallsCount = 0
    var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingCalled: Bool {
        fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingCallsCount > 0
    }

    var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReceivedArguments: (
        range: Range<Date>,
        offset: Int,
        limit: Int
    )?
    var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReceivedInvocations: [(
        range: Range<Date>,
        offset: Int,
        limit: Int
    )] = []
    var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue: [Meeting]!
    var fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingClosure: ((Range<Date>, Int, Int) async throws
        -> [Meeting])?

    func fetchMeetings(in range: Range<Date>, offset: Int, limit: Int) async throws -> [Meeting] {
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

    var hasUpcomingMeetingsAfterDateDateBoolThrowableError: (any Error)?
    var hasUpcomingMeetingsAfterDateDateBoolCallsCount = 0
    var hasUpcomingMeetingsAfterDateDateBoolCalled: Bool {
        hasUpcomingMeetingsAfterDateDateBoolCallsCount > 0
    }

    var hasUpcomingMeetingsAfterDateDateBoolReceivedDate: Date?
    var hasUpcomingMeetingsAfterDateDateBoolReceivedInvocations: [Date] = []
    var hasUpcomingMeetingsAfterDateDateBoolReturnValue: Bool!
    var hasUpcomingMeetingsAfterDateDateBoolClosure: ((Date) async throws -> Bool)?

    func hasUpcomingMeetings(after date: Date) async throws -> Bool {
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
