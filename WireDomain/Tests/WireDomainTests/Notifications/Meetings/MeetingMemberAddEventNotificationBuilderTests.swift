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

import Foundation
import UserNotifications
import WireDataModel
import WireDataModelSupport
import WireNetwork
import WireUpdateEventCoding
import XCTest

@testable import WireDomain

final class MeetingMemberAddEventNotificationBuilderTests: XCTestCase {

    private var stackHelper: CoreDataStackHelper!
    private var stack: CoreDataStack!
    private var meetingsAPI: InvitationMeetingsAPI!
    private var usersAPI: InvitationUsersAPI!
    private var featureStore: MockFeatureConfigLocalStoreProtocol!
    private var sut: MeetingMemberAddEventNotificationBuilder!

    override func setUp() async throws {
        try await super.setUp()
        stackHelper = CoreDataStackHelper()
        stack = try await stackHelper.createStack()
        meetingsAPI = InvitationMeetingsAPI()
        usersAPI = InvitationUsersAPI()
        featureStore = MockFeatureConfigLocalStoreProtocol()
        let context = stack.syncContext
        featureStore.fetchFeatureName_MockValue = await context.perform {
            Feature.updateOrCreate(havingName: .meetings, in: context) { $0.status = .enabled }
            return Feature.fetch(name: .meetings, context: context)
        }
        featureStore.isFeatureEnabled_ReturnValue = true
        sut = MeetingMemberAddEventNotificationBuilder(
            meetingsAPI: meetingsAPI,
            usersAPI: usersAPI,
            featureConfigLocalStore: featureStore,
            accountID: UUID(),
            locale: Locale(identifier: "en_GB"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
    }

    override func tearDown() async throws {
        sut = nil
        meetingsAPI = nil
        usersAPI = nil
        featureStore = nil
        stack = nil
        try stackHelper.cleanupDirectory()
        stackHelper = nil
        try await super.tearDown()
    }

    func testInvitationFetchesDetailsAndUsesInviterRatherThanCreator() async throws {
        let result = await sut.buildContent(event: Scaffolding.event)
        guard case let .text(content) = try XCTUnwrap(result) else {
            return XCTFail("Expected an invitation notification")
        }
        XCTAssertEqual(meetingsAPI.requestedIDs, [Scaffolding.meetingID])
        XCTAssertEqual(usersAPI.requestedIDs, [Scaffolding.senderID])
        XCTAssertNotEqual(Scaffolding.meeting.creatorID, Scaffolding.senderID)
        XCTAssertEqual(content.title, "Planning")
        XCTAssertEqual(content.body, "Federico invited you to a meeting on 10 Oct 2026 · 14:00 to 15:00")
        XCTAssertEqual(content.categoryIdentifier, NotificationCategory.meetingInvitation.rawValue)
        XCTAssertEqual(content.sound, .default)
        XCTAssertEqual(content.userInfo[NotificationUserInfoKey.selfUserID] as? String, sut.accountID.uuidString)
    }

    func testInvitationUsesRecipientTimeZone() async throws {
        sut.timeZone = TimeZone(secondsFromGMT: 7200)!
        let result = await sut.buildContent(event: Scaffolding.event)
        guard case let .text(content) = try XCTUnwrap(result) else {
            return XCTFail("Expected an invitation notification")
        }
        XCTAssertEqual(content.body, "Federico invited you to a meeting on 10 Oct 2026 · 16:00 to 17:00")
    }

    func testDisabledMeetingsDoNotFetchOrNotify() async {
        featureStore.isFeatureEnabled_ReturnValue = false
        let result = await sut.buildContent(event: Scaffolding.event)
        XCTAssertNil(result)
        XCTAssertTrue(meetingsAPI.requestedIDs.isEmpty)
        XCTAssertTrue(usersAPI.requestedIDs.isEmpty)
    }

    func testMissingMeetingDoesNotNotify() async {
        meetingsAPI.shouldFail = true
        let result = await sut.buildContent(event: Scaffolding.event)
        XCTAssertNil(result)
        XCTAssertTrue(usersAPI.requestedIDs.isEmpty)
    }

    func testMissingInviterDoesNotNotify() async {
        usersAPI.shouldFail = true
        let result = await sut.buildContent(event: Scaffolding.event)
        XCTAssertNil(result)
    }

    func testGenericMeetingUpdateDoesNotNotify() async {
        let builder = MeetingEventNotificationBuilder(
            meetingDeleteEventBuilder: UnusedMeetingDeleteBuilder(),
            meetingMemberAddEventBuilder: sut
        )
        let result = await builder.buildContent(event: .update(.init(meetingID: Scaffolding.meetingID)))
        XCTAssertNil(result)
        XCTAssertTrue(meetingsAPI.requestedIDs.isEmpty)
    }

    func testMemberAddIsRoutedToInvitationBuilder() async {
        let builder = MeetingEventNotificationBuilder(
            meetingDeleteEventBuilder: UnusedMeetingDeleteBuilder(),
            meetingMemberAddEventBuilder: sut
        )
        let result = await builder.buildContent(event: .memberAdd(Scaffolding.event))
        XCTAssertNotNil(result)
        XCTAssertEqual(meetingsAPI.requestedIDs, [Scaffolding.meetingID])
    }

    func testMemberAddStillRefreshesMeetingThroughUpdateProcessor() async throws {
        let processors = InvitationEventProcessors()
        let processor = MeetingEventProcessor(
            createEventProcessor: processors,
            deleteEventProcessor: processors,
            updateEventProcessor: processors
        )
        try await processor.processEvent(.memberAdd(Scaffolding.event))
        XCTAssertEqual(processors.updates, [MeetingUpdateEvent(meetingID: Scaffolding.meetingID)])
    }

    func testStoredInvitationPreservesEventTypeAndInviter() throws {
        let envelope = UpdateEventEnvelope(
            id: UUID(),
            events: [.meeting(.memberAdd(Scaffolding.event))],
            isTransient: false
        )
        let coder = StorableUpdateEventCoder()
        XCTAssertEqual(try coder.decode(coder.encode(envelope)), envelope)
    }
}

private enum Scaffolding {
    static let meetingID = WireNetwork.QualifiedID(id: UUID(), domain: "example.com")
    static let senderID = WireNetwork.QualifiedID(id: UUID(), domain: "example.com")
    static let event = MeetingMemberAddEvent(meetingID: meetingID, senderID: senderID)
    static let startTime = ISO8601DateFormatter().date(from: "2026-10-10T14:00:00Z")!
    static let meeting = MeetingResponse(
        id: meetingID,
        title: "Planning",
        creatorID: .init(id: UUID(), domain: "example.com"),
        startTime: startTime,
        endTime: startTime.addingTimeInterval(3600),
        conversationID: .init(id: UUID(), domain: "example.com"),
        invitedEmails: [],
        isTrial: false,
        createdAt: startTime,
        updatedAt: startTime
    )
}

private enum InvitationTestError: Error {
    case unavailable
}

private final class InvitationMeetingsAPI: MeetingsAPI, @unchecked Sendable {
    var requestedIDs: [WireNetwork.QualifiedID] = []
    var shouldFail = false

    func getMeeting(id: WireNetwork.QualifiedID) async throws -> MeetingResponse {
        requestedIDs.append(id)
        if shouldFail { throw InvitationTestError.unavailable }
        return Scaffolding.meeting
    }

    func listMeetings() async throws -> [MeetingResponse] { throw InvitationTestError.unavailable }
    func createMeeting(parameters: CreateMeetingParameters) async throws -> MeetingResponse {
        throw InvitationTestError.unavailable
    }

    func updateMeeting(
        id: WireNetwork.QualifiedID,
        parameters: UpdateMeetingParameters
    ) async throws -> MeetingResponse {
        throw InvitationTestError.unavailable
    }

    func deleteMeeting(id: WireNetwork.QualifiedID) async throws { throw InvitationTestError.unavailable }
}

private final class InvitationUsersAPI: UsersAPI {
    var requestedIDs: [UserID] = []
    var shouldFail = false

    func getUser(for userID: UserID) async throws -> WireNetwork.User {
        requestedIDs.append(userID)
        if shouldFail { throw InvitationTestError.unavailable }
        return WireNetwork.User(
            id: userID,
            name: "Federico",
            handle: nil,
            teamID: nil,
            type: nil,
            accentID: 0,
            assets: [],
            deleted: false,
            email: nil,
            expiresAt: nil,
            app: nil,
            service: nil,
            supportedProtocols: nil,
            legalholdStatus: .disabled
        )
    }

    func getUsers(userIDs: [UserID]) async throws -> UserList { throw InvitationTestError.unavailable }
}

private struct UnusedMeetingDeleteBuilder: MeetingDeleteEventNotificationBuilderProtocol {
    func buildContent(event: MeetingDeleteEvent) async -> UserNotification? { nil }
}

private final class InvitationEventProcessors: MeetingCreateEventProcessorProtocol,
    MeetingDeleteEventProcessorProtocol, MeetingUpdateEventProcessorProtocol {
    var updates: [MeetingUpdateEvent] = []

    func processEvent(_ event: MeetingCreateEvent) async throws { XCTFail("Unexpected create") }
    func processEvent(_ event: MeetingDeleteEvent) async { XCTFail("Unexpected delete") }
    func processEvent(_ event: MeetingUpdateEvent) async throws { updates.append(event) }
}
