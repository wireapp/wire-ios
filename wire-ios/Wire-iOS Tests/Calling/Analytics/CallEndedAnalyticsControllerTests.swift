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

import XCTest
import WireLogging
import WireAnalytics
import WireAnalyticsSupport
import WireDataModelSupport

@testable import Wire
@testable import WireSyncEngine

final class CallEndedAnalyticsControllerTests: XCTestCase {

    private var notificationCenter: NotificationCenter!
    private var coreDataStack: CoreDataStack!
    private var mockAnalyticsEventTracker: MockAnalyticsEventTracker!
    private var sut: CallEndedAnalyticsController<MockCallCenter>!

    override func setUp() async throws {
        notificationCenter = .init()
        coreDataStack = try await CoreDataStackHelper().createStack()
        mockAnalyticsEventTracker = .init()
        sut = .init(
            contextProvider: coreDataStack,
            notificationCenter: notificationCenter,
            analyticsEventTracker: { self.mockAnalyticsEventTracker },
            logger: WireLogger(tag: "mock")
        )
    }

    override func tearDown() {
        sut = nil
        mockAnalyticsEventTracker = nil
        coreDataStack = nil
        notificationCenter = nil
    }

    func testExample() throws {
        // When
        // TODO: send call started event + call cancelled event

        // Then
        // ensure the correct event has been sent to the analytics backend
        // ensure the logger logged the event as well
    }
}

// MARK: -

private final class MockCallCenter: WireCallCenterV3 {}
