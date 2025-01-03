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
import WireDataModelSupport

@testable import Wire

final class CallEndedAnalyticsControllerTests: XCTestCase {

    private var notificationCenter: NotificationCenter!
    private var coreDataStack: CoreDataStack!
    private var analyticsEventTracker: AnalyticsEventTracker!
    private var sut: CallEndedAnalyticsController<WireCallCenterV3>! // TODO: mock call center?

    override func setUp() async throws {
        notificationCenter = .init()
        coreDataStack = try await CoreDataStackHelper().createStack()
        sut = .init(
            contextProvider: coreDataStack,
            notificationCenter: notificationCenter,
            analyticsEventTracker: { self.analyticsEventTracker },
            logger: WireLogger(tag: "mock")
        )
    }

    override func tearDown() {
        sut = nil
        analyticsEventTracker = nil
        coreDataStack = nil
        notificationCenter = nil
    }

    func testExample() throws {
        print(sut!)
    }
}
