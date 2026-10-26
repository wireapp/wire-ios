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
import XCTest

@testable import WireDomain

final class MeetingUpdateEventNotificationBuilderTests: XCTestCase {

    private var stackHelper: CoreDataStackHelper!
    private var stack: CoreDataStack!
    private var meetingsAPI: UpdateMeetingsAPI!
    private var usersAPI: UpdateUsersAPI!
    private var featureStore: MockFeatureConfigLocalStoreProtocol!
    private var sut: MeetingUpdateEventNotificationBuilder!

    override func setUp() async throws {
        try await super.setUp()
        stackHelper = CoreDataStackHelper()
        stack = try await stackHelper.createStack()
        meetingsAPI = UpdateMeetingsAPI()
        usersAPI = UpdateUsersAPI()
        featureStore = MockFeatureConfigLocalStoreProtocol()
        let context = stack.syncContext
        featureStore.fetchFeatureName_MockValue = await context.perform {
            Feature.updateOrCreate(havingName: .meetings, in: context) { $0.status = .enabled }
            return Feature.fetch(name: .meetings, context: context)
        }
        featureStore.isFeatureEnabled_ReturnValue = true
        sut = MeetingUpdateEventNotificationBuilder(
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

    func testUpdateFetchesMeetingAndHostAndBuildsNotification() async throws {
        let result = await sut.buildContent(event: Scaffolding.event)
        guard case let .text(content) = try XCTUnwrap(result) else {
            return XCTFail("Expected an update notification")
        }
        XCTAssertEqual(meetingsAPI.requestedIDs, [Scaffolding.meetingID])
        XCTAssertEqual(usersAPI.requestedIDs, [Scaffolding.meeting.creatorID])
        XCTAssertEqual(content.title, "Update: Planning")
        XCTAssertEqual(content.body, "Alice updated this meeting to 10 Oct 2026 · 14:00 to 15:00")
        XCTAssertEqual(content.categoryIdentifier, NotificationCategory.meetingUpdate.rawValue)
        XCTAssertEqual(content.sound, .default)
        XCTAssertEqual(content.userInfo[NotificationUserInfoKey.selfUserID] as? String, sut.accountID.uuidString)
    }

    func testUpdateUsesRecipientTimeZone() async throws {
        sut.timeZone = TimeZone(secondsFromGMT: 7200)!
        let result = await sut.buildContent(event: Scaffolding.event)
        guard case let .text(content) = try XCTUnwrap(result) else {
            return XCTFail("Expected an update notification")
        }
        XCTAssertEqual(content.body, "Alice updated this meeting to 10 Oct 2026 · 16:00 to 17:00")
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

    func testSelfAuthoredUpdateDoesNotNotify() async {
        sut = MeetingUpdateEventNotificationBuilder(
            meetingsAPI: meetingsAPI,
            usersAPI: usersAPI,
            featureConfigLocalStore: featureStore,
            accountID: Scaffolding.meeting.creatorID.id,
            locale: Locale(identifier: "en_GB"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        let result = await sut.buildContent(event: Scaffolding.event)
        XCTAssertNil(result)
        XCTAssertTrue(usersAPI.requestedIDs.isEmpty)
    }

    func testMissingHostDoesNotNotify() async {
        usersAPI.shouldFail = true
        let result = await sut.buildContent(event: Scaffolding.event)
        XCTAssertNil(result)
    }

    func testEmptyHostNameDoesNotNotify() async {
        usersAPI.overrideName = ""
        let result = await sut.buildContent(event: Scaffolding.event)
        XCTAssertNil(result)
    }

    func testUpdateIsRoutedToUpdateBuilder() async {
        let builder = MeetingEventNotificationBuilder(
            meetingDeleteEventBuilder: UnusedDeleteBuilder(),
            meetingMemberAddEventBuilder: UnusedMemberAddBuilder(),
            meetingUpdateEventBuilder: sut
        )
        let result = await builder.buildContent(event: .update(Scaffolding.event))
        XCTAssertNotNil(result)
        XCTAssertEqual(meetingsAPI.requestedIDs, [Scaffolding.meetingID])
    }
}

private enum Scaffolding {
    static let meetingID = WireNetwork.QualifiedID(id: UUID(), domain: "example.com")
    static let event = MeetingUpdateEvent(meetingID: meetingID)
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

private enum UpdateTestError: Error {
    case unavailable
}

private final class UpdateMeetingsAPI: MeetingsAPI, @unchecked Sendable {
    var requestedIDs: [WireNetwork.QualifiedID] = []
    var shouldFail = false

    func getMeeting(id: WireNetwork.QualifiedID) async throws -> MeetingResponse {
        requestedIDs.append(id)
        if shouldFail { throw UpdateTestError.unavailable }
        return Scaffolding.meeting
    }

    func listMeetings() async throws -> [MeetingResponse] { throw UpdateTestError.unavailable }
    func createMeeting(parameters: CreateMeetingParameters) async throws -> MeetingResponse {
        throw UpdateTestError.unavailable
    }

    func updateMeeting(
        id: WireNetwork.QualifiedID,
        parameters: UpdateMeetingParameters
    ) async throws -> MeetingResponse {
        throw UpdateTestError.unavailable
    }

    func deleteMeeting(id: WireNetwork.QualifiedID) async throws { throw UpdateTestError.unavailable }
}

private final class UpdateUsersAPI: UsersAPI {
    var requestedIDs: [UserID] = []
    var shouldFail = false
    var overrideName: String?

    func getUser(for userID: UserID) async throws -> WireNetwork.User {
        requestedIDs.append(userID)
        if shouldFail { throw UpdateTestError.unavailable }
        return WireNetwork.User(
            id: userID,
            name: overrideName ?? "Alice",
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

    func getUsers(userIDs: [UserID]) async throws -> UserList { throw UpdateTestError.unavailable }
}

private struct UnusedDeleteBuilder: MeetingDeleteEventNotificationBuilderProtocol {
    func buildContent(event: MeetingDeleteEvent) async -> UserNotification? { nil }
}

private struct UnusedMemberAddBuilder: MeetingMemberAddEventNotificationBuilderProtocol {
    func buildContent(event: MeetingMemberAddEvent) async -> UserNotification? { nil }
}
