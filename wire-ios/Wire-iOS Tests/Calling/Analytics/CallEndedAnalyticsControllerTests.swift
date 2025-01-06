//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAnalyticsSupport
import WireDataModelSupport
import WireLogging
import WireSystemSupport
import XCTest

@testable import Wire
@testable import WireAnalytics
@testable import WireSyncEngine

final class CallEndedAnalyticsControllerTests: XCTestCase {

    private var notificationCenter: NotificationCenter!
    private var coreDataStack: CoreDataStack!
    private var selfUser: ZMUser!
    private var otherUser: ZMUser!
    private var mockAnalyticsEventTracker: MockAnalyticsEventTracker!
    private var mockDateProvider: MockCurrentDateProviding!
    private var sut: CallEndedAnalyticsController<WireCallCenterV3>!

    var syncContext: NSManagedObjectContext { coreDataStack.syncContext }
    var viewContext: NSManagedObjectContext { coreDataStack.viewContext }

    override func setUp() async throws {

        notificationCenter = .init()

        coreDataStack = try await CoreDataStackHelper().createStack()
        selfUser = await setupSelfUser()
        otherUser = await setupOtherUser()

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
        mockAnalyticsEventTracker = nil
        coreDataStack = nil
        notificationCenter = nil
    }

    func testMissedGroupVideoCall() throws {
        // Given
        let conversationID = setupGroupConversation()

        // When
        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .incoming(isVideo: true, shouldRing: true, degraded: false),
            conversationId: conversationID,
            callerId: otherUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: nil
        ).post(in: viewContext.notificationContext)
        mockDateProvider.now.addTimeInterval(3)
        WireCallCenterCallStateNotification(
            context: viewContext,
            callState: .terminating(reason: .canceled),
            conversationId: conversationID,
            callerId: otherUser.avsIdentifier,
            messageTime: mockDateProvider.now,
            previousCallState: .incoming(isVideo: true, shouldRing: true, degraded: false)
        ).post(in: viewContext.notificationContext)

        // Then
        let event = try XCTUnwrap(mockAnalyticsEventTracker.trackedEvents.last)
        let segmentation = event.segmentation
        XCTAssertEqual(event.name, "calling.ended_call")
        XCTAssert(segmentation.contains { $0.key == "device_model" })
        XCTAssert(segmentation.contains { $0.key == "os_version" })
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
        let otherUser = await syncContext.perform { [syncContext] in
            defer { try! syncContext.save() }
            return ZMUser.fetchOrCreate(with: .init(), domain: "wire.com", in: syncContext)
        }
        return await viewContext.perform { [viewContext] in
            viewContext.object(with: otherUser.objectID) as! ZMUser
        }
    }

    private func setupGroupConversation() -> AVSIdentifier {
        viewContext.performAndWait { [viewContext] in
            ModelHelper().createGroupConversation(
                id: .init(),
                with: [selfUser, otherUser],
                team: nil,
                domain: "wire.com",
                in: viewContext
            ).avsIdentifier!
        }
    }
}

private class MockAnalyticsEventTracker: AnalyticsEventTracker {

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
