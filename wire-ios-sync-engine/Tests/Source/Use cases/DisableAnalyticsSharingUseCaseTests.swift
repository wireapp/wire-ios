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

import WireAnalyticsSupport
import XCTest

@testable import WireSyncEngine

final class DisableAnalyticsSharingUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var sut: DisableAnalyticsUseCase!
    private var mockAnalyticsManager: MockAnalyticsManagerProtocol!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockAnalyticsManager = MockAnalyticsManagerProtocol()
        sut = DisableAnalyticsUseCase(analyticsManager: mockAnalyticsManager)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockAnalyticsManager = nil
        super.tearDown()
    }

    // MARK: - Unit Tests

    func testInvoke_CallsDisableTrackingOnAnalyticsManager() {
        // GIVEN
        XCTAssertFalse(mockAnalyticsManager.invokedDisableTracking)
        XCTAssertEqual(mockAnalyticsManager.invokedDisableTrackingCount, 0)

        // WHEN
        sut.invoke()

        // THEN
        XCTAssertTrue(mockAnalyticsManager.invokedDisableTracking, "disableTracking should be called on the analytics manager")
        XCTAssertEqual(mockAnalyticsManager.invokedDisableTrackingCount, 1, "disableTracking should be called exactly once")
    }
}
