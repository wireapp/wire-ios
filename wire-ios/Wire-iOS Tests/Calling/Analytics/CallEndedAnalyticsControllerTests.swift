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

import WireDataModelSupport
import WireFoundation
import WireFoundationSupport
import WireLogging
import XCTest

@testable import Wire
@testable import WireAnalytics
@testable import WireSyncEngine

final class CallEndedAnalyticsControllerTests: XCTestCase {

    private var notificationCenter: NotificationCenter!
    private var coreDataStack: CoreDataStack!
    private var selfUser: ZMUser!
    private var secondUser: ZMUser!
    private var thirdUser: ZMUser!
    private var mockAnalyticsEventTracker: MockAnalyticsEventTracker!
    private var mockDateProvider: CurrentDateProvidingMock!
    private var sut: CallEndedAnalyticsController<WireCallCenterV3>!

    var syncContext: NSManagedObjectContext { coreDataStack.syncContext }
    var viewContext: NSManagedObjectContext { coreDataStack.viewContext }

    override func setUp() async throws {

        notificationCenter = .init()

        coreDataStack = try await CoreDataStackHelper().createStack()
        selfUser = await setupSelfUser()
        secondUser = await setupOtherUser()
        thirdUser = await setupOtherUser()

        mockAnalyticsEventTracker = .init()

        mockDateProvider = .init()
        mockDateProvider.now = ISO8601DateFormatter().date(from: "2025-01-06T12:00:27+01:00")!

        sut = .init(
            contextProvider: coreDataStack,
            notificationCenter: notificationCenter,
            analyticsEventTracker: { self.mockAnalyticsEventTracker },
            logger: WireLogger(tag: "mock"),
            currentDateProvider: mockDateProvider
        )
    }

    override func tearDown() {
        sut = nil
        mockDateProvider = nil
        mockAnalyticsEventTracker = nil
        thirdUser = nil
        secondUser = nil
        selfUser = nil
        coreDataStack = nil
        notificationCenter = nil
    }

    func testMissedGroupVideoCall() throws {
        // Given
        let conversationID = setupGroupConversation(team: nil, participants: [selfUser, secondUser])

        // When
        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .incoming(isVideo: true, shouldRing: true, degraded: false),
            conversationId: conversationID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        mockDateProvider.now.addTimeInterval(3)

        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .terminating(reason: .canceled),
            conversationId: conversationID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        // Then
        let event = try XCTUnwrap(mockAnalyticsEventTracker.trackedEvents.last)
        let segmentation = event.segmentation
        XCTAssertEqual(event.name, "calling.ended_call")
        XCTAssertEqual(segmentation["call_screen_share"], "False")
        XCTAssertEqual(segmentation["call_screen_share_duration"], "0")
        XCTAssertEqual(segmentation["call_screen_share_unique"], "0")
        XCTAssertEqual(segmentation["call_direction"], "incoming")
        XCTAssertEqual(segmentation["call_duration"], "0")
        XCTAssertEqual(segmentation["conversation_type"], "group")
        XCTAssertEqual(segmentation["conversation_size"], "2")
        XCTAssertEqual(segmentation["conversation_guests"], "0")
        XCTAssertEqual(segmentation["conversation_guests_pro"], "0")
        XCTAssertEqual(segmentation["call_participants"], "0")
        XCTAssertEqual(segmentation["call_end_reason"], "4") // WCALL_REASON_CANCELED = 4
        XCTAssertEqual(segmentation["conversation_services"], "0")
        XCTAssertEqual(segmentation["call_av_switch_toggle"], "False")
        XCTAssertEqual(segmentation["call_video"], "True")
        XCTAssertEqual(segmentation["team_is_team"], "False")
    }

    func testOutgoingOneOnOneCall() throws {
        // Given
        setupSelfTeam()
        setupTeam(selfUser.team!, for: secondUser)
        let conversationID = setupOneOnOneConversation()

        // When
        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .outgoing(isVideo: false, degraded: false),
            conversationId: conversationID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        mockDateProvider.now.addTimeInterval(1)

        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .established,
            conversationId: conversationID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        mockDateProvider.now.addTimeInterval(3)

        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .terminating(reason: .everyoneLeft),
            conversationId: conversationID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        // Then
        let event = try XCTUnwrap(mockAnalyticsEventTracker.trackedEvents.last)
        let segmentation = event.segmentation
        XCTAssertEqual(event.name, "calling.ended_call")
        XCTAssertEqual(segmentation["call_screen_share"], "False")
        XCTAssertEqual(segmentation["call_screen_share_duration"], "0")
        XCTAssertEqual(segmentation["call_screen_share_unique"], "0")
        XCTAssertEqual(segmentation["call_direction"], "outgoing")
        XCTAssertEqual(segmentation["call_duration"], "3")
        XCTAssertEqual(segmentation["conversation_type"], "one_to_one")
        XCTAssertEqual(segmentation["conversation_size"], "2")
        XCTAssertEqual(segmentation["conversation_guests"], "0")
        XCTAssertEqual(segmentation["conversation_guests_pro"], "0")
        XCTAssertEqual(segmentation["call_participants"], "0")
        XCTAssertEqual(segmentation["call_end_reason"], "13") // WCALL_REASON_EVERYONE_LEFT = 13
        XCTAssertEqual(segmentation["conversation_services"], "0")
        XCTAssertEqual(segmentation["call_av_switch_toggle"], "False")
        XCTAssertEqual(segmentation["call_video"], "False")
        XCTAssertEqual(segmentation["team_is_team"], "True")
    }

    /// A group conversation with three users.
    /// The conversation is from the team of the third user, the second user is a personal user, the self user is from a
    /// different team.
    /// The self user toggles its video.
    func testIncomingOneOnOneCallWithToggledVideo() throws {
        // Given
        setupSelfTeam()
        let otherTeam = setupOtherTeam()
        setupTeam(otherTeam, for: thirdUser)
        let conversationID = setupGroupConversation(
            team: otherTeam,
            participants: [selfUser, secondUser, thirdUser]
        )

        // When
        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .outgoing(isVideo: false, degraded: false),
            conversationId: conversationID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        mockDateProvider.now.addTimeInterval(1)

        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .established,
            conversationId: conversationID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        mockDateProvider.now.addTimeInterval(3)

        notificationCenter.post(
            name: WireCallCenterV3.didToggleVideoNotification,
            object: nil,
            userInfo: [WireCallCenterV3.conversationIDUserInfoKey: conversationID]
        )

        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .terminating(reason: .unknown),
            conversationId: conversationID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        // Then
        let event = try XCTUnwrap(mockAnalyticsEventTracker.trackedEvents.last)
        let segmentation = event.segmentation
        XCTAssertEqual(event.name, "calling.ended_call")
        XCTAssertEqual(segmentation["call_screen_share"], "False")
        XCTAssertEqual(segmentation["call_screen_share_duration"], "0")
        XCTAssertEqual(segmentation["call_screen_share_unique"], "0")
        XCTAssertEqual(segmentation["call_direction"], "outgoing")
        XCTAssertEqual(segmentation["call_duration"], "3")
        XCTAssertEqual(segmentation["conversation_type"], "group")
        XCTAssertEqual(segmentation["conversation_size"], "3")
        XCTAssertEqual(segmentation["conversation_guests"], "1") // `secondUser`
        XCTAssertEqual(segmentation["conversation_guests_pro"], "1") // `selfUser`
        XCTAssertEqual(segmentation["call_participants"], "0")
        XCTAssertEqual(segmentation["call_end_reason"], "1") // WCALL_REASON_ERROR = 1
        XCTAssertEqual(segmentation["conversation_services"], "0")
        XCTAssertEqual(segmentation["call_av_switch_toggle"], "True")
        XCTAssertEqual(segmentation["call_video"], "False")
        XCTAssertEqual(segmentation["team_is_team"], "True")
    }

    func testSecondIncomingCall() throws {
        // Given
        let conversation0ID = setupGroupConversation(team: nil, participants: [selfUser, secondUser])
        let conversation1ID = setupGroupConversation(team: nil, participants: [selfUser, thirdUser])

        // When
        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .incoming(isVideo: true, shouldRing: true, degraded: false),
            conversationId: conversation0ID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        mockDateProvider.now.addTimeInterval(1)

        // call established

        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .established,
            conversationId: conversation0ID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        mockDateProvider.now.addTimeInterval(3)

        // another incoming call

        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .incoming(isVideo: false, shouldRing: true, degraded: false),
            conversationId: conversation1ID,
            callerId: thirdUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        mockDateProvider.now.addTimeInterval(3)

        // incoming call is cancelled

        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .terminating(reason: .canceled),
            conversationId: conversation1ID,
            callerId: thirdUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        mockDateProvider.now.addTimeInterval(3)

        // first call ended

        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .terminating(reason: .unknown),
            conversationId: conversation0ID,
            callerId: secondUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)

        // Then
        let event0 = try XCTUnwrap(mockAnalyticsEventTracker.trackedEvents.first)
        let segmentation0 = event0.segmentation
        XCTAssertEqual(event0.name, "calling.ended_call")
        XCTAssertEqual(segmentation0["call_screen_share"], "False")
        XCTAssertEqual(segmentation0["call_screen_share_duration"], "0")
        XCTAssertEqual(segmentation0["call_screen_share_unique"], "0")
        XCTAssertEqual(segmentation0["call_direction"], "incoming")
        XCTAssertEqual(segmentation0["call_duration"], "0")
        XCTAssertEqual(segmentation0["conversation_type"], "group")
        XCTAssertEqual(segmentation0["conversation_size"], "2")
        XCTAssertEqual(segmentation0["conversation_guests"], "0")
        XCTAssertEqual(segmentation0["conversation_guests_pro"], "0")
        XCTAssertEqual(segmentation0["call_participants"], "0")
        XCTAssertEqual(segmentation0["call_end_reason"], "4") // WCALL_REASON_CANCELED = 4
        XCTAssertEqual(segmentation0["conversation_services"], "0")
        XCTAssertEqual(segmentation0["call_av_switch_toggle"], "False")
        XCTAssertEqual(segmentation0["call_video"], "False")
        XCTAssertEqual(segmentation0["team_is_team"], "False")

        let event1 = try XCTUnwrap(mockAnalyticsEventTracker.trackedEvents.last)
        let segmentation1 = event1.segmentation
        XCTAssertEqual(event1.name, "calling.ended_call")
        XCTAssertEqual(segmentation1["call_screen_share"], "False")
        XCTAssertEqual(segmentation1["call_screen_share_duration"], "0")
        XCTAssertEqual(segmentation1["call_screen_share_unique"], "0")
        XCTAssertEqual(segmentation1["call_direction"], "incoming")
        XCTAssertEqual(segmentation1["call_duration"], "9")
        XCTAssertEqual(segmentation1["conversation_type"], "group")
        XCTAssertEqual(segmentation1["conversation_size"], "2")
        XCTAssertEqual(segmentation1["conversation_guests"], "0")
        XCTAssertEqual(segmentation1["conversation_guests_pro"], "0")
        XCTAssertEqual(segmentation1["call_participants"], "0")
        XCTAssertEqual(segmentation1["call_end_reason"], "1") // WCALL_REASON_ERROR = 1
        XCTAssertEqual(segmentation1["conversation_services"], "0")
        XCTAssertEqual(segmentation1["call_av_switch_toggle"], "False")
        XCTAssertEqual(segmentation1["call_video"], "True")
        XCTAssertEqual(segmentation1["team_is_team"], "False")
    }

    // MARK: - Helpers

    private func setupSelfUser() async -> ZMUser {
        let selfUser = await syncContext.perform { [syncContext] in
            defer { try! syncContext.save() }
            return ModelHelper().createSelfUser(id: .init(), domain: "wire.com", in: syncContext)
        }
        return await viewContext.perform { [viewContext] in
            viewContext.object(with: selfUser.objectID) as! ZMUser
        }
    }

    private func setupOtherUser() async -> ZMUser {
        let secondUser = await syncContext.perform { [syncContext] in
            defer { try! syncContext.save() }
            return ZMUser.fetchOrCreate(with: .init(), domain: "wire.com", in: syncContext)
        }
        return await viewContext.perform { [viewContext] in
            viewContext.object(with: secondUser.objectID) as! ZMUser
        }
    }

    private func setupSelfTeam() {
        syncContext.performAndWait {
            _ = syncContext.object(with: secondUser.objectID) as! ZMUser
            let modelHelper = ModelHelper()
            modelHelper.createSelfTeam(numberOfUsers: 0, in: syncContext)
            try! syncContext.save()
        }
    }

    private func setupOtherTeam() -> Team {
        let team = syncContext.performAndWait {
            defer { try! syncContext.save() }
            return Team.fetchOrCreate(with: .init(), in: syncContext)
        }
        return viewContext.object(with: team.objectID) as! Team
    }

    private func setupTeam(_ team: Team, for user: ZMUser) {
        ModelHelper().addUser(user, to: team, in: viewContext)
        try! viewContext.save()
    }

    private func setupGroupConversation(team: Team?, participants: Set<ZMUser>) -> AVSIdentifier {
        defer { try! viewContext.save() }
        return ModelHelper().createGroupConversation(
            id: .init(),
            with: participants,
            team: team,
            domain: "wire.com",
            in: viewContext
        ).avsIdentifier!
    }

    private func setupOneOnOneConversation() -> AVSIdentifier {
        defer { try! viewContext.save() }
        let conversation = ModelHelper().createOneOnOne(
            id: .init(),
            domain: "wire.com",
            with: secondUser,
            team: selfUser.team,
            in: viewContext
        )
        conversation.teamRemoteIdentifier = selfUser.team?.remoteIdentifier
        return conversation.avsIdentifier!
    }
}

private class MockAnalyticsEventTracker: AnalyticsEventTrackerProtocol {

    var trackedEvents = [AnalyticsEvent]()

    func trackEvent(_ event: AnalyticsEvent) {
        trackedEvents += [event]
    }
}

private extension Set<AnalyticsEvent.Segmentation> {

    subscript(key: String) -> String? {
        first { $0.key == key }?.value
    }
}
