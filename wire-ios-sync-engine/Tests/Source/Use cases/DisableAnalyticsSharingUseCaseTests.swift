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
import WireSyncEngineSupport
import XCTest

@testable import WireSyncEngine

final class DisableAnalyticsSharingUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var sut: DisableAnalyticsUseCase!
    private var mockAnalyticsManagerProvider: MockAnalyticsManagerProviding!
    private var mockAnalyticsManager: MockAnalyticsManagerProtocol!
    private var didDisableAnalyticsCalled: Bool!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockAnalyticsManager = MockAnalyticsManagerProtocol()
        mockAnalyticsManagerProvider = MockAnalyticsManagerProviding()
        mockAnalyticsManagerProvider.analyticsManager = mockAnalyticsManager
        didDisableAnalyticsCalled = false

        sut = DisableAnalyticsUseCase(
            sessionManager: mockAnalyticsManagerProvider,
            didDisableAnalytics: { [weak self] in
                self?.didDisableAnalyticsCalled = true
            }
        )
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockAnalyticsManagerProvider = nil
        mockAnalyticsManager = nil
        didDisableAnalyticsCalled = nil

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

    func testInvoke_SetsAnalyticsManagerToNil() {
        // GIVEN
        XCTAssertNotNil(mockAnalyticsManagerProvider.analyticsManager)

        // WHEN
        sut.invoke()

        // THEN
        XCTAssertNil(mockAnalyticsManagerProvider.analyticsManager, "analyticsManager should be set to nil after invoke")
    }

    func testInvoke_CallsDidDisableAnalyticsClosure() {
        // GIVEN
        XCTAssertFalse(didDisableAnalyticsCalled)

        // WHEN
        sut.invoke()

        // THEN
        XCTAssertTrue(didDisableAnalyticsCalled, "didDisableAnalytics closure should be called after invoke")
    }
}
