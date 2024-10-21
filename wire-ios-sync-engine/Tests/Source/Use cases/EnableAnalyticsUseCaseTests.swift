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

import WireAnalytics
import WireAnalyticsSupport
import XCTest

@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class EnableAnalyticsUseCaseTests: XCTestCase, AnalyticsEventTrackerProvider {

    private var sut: EnableAnalyticsUseCase!
    private var currentUser: AnalyticsUser!
    private var service: MockAnalyticsServiceProtocol!

    var analyticsEventTracker: (any AnalyticsEventTracker)?

    override func setUp() {
        super.setUp()
        currentUser = AnalyticsUser(analyticsIdentifier: UUID().transportString())
        service = MockAnalyticsServiceProtocol()
        sut = EnableAnalyticsUseCase(service: service, provider: self)
    }

    override func tearDown() {
        sut = nil
        currentUser = nil
        service = nil
        analyticsEventTracker = nil
        super.tearDown()
    }

    func setAnalyticsEventTracker(_ tracker: (any AnalyticsEventTracker)?) {
        analyticsEventTracker = tracker
    }

    func createAnalyticsUser() async throws -> AnalyticsUser {
        currentUser
    }

    func testInvoke_enables_and_switches_user_via_service() async throws {
        // Mock
        service.enableTracking_MockMethod = { }
        service.switchUser_MockMethod = { _ in }

        // Given
        XCTAssertNil(analyticsEventTracker)

        // When
        try await sut.invoke()

        // Then
        XCTAssertEqual(service.enableTracking_Invocations.count, 1)
        XCTAssertEqual(service.switchUser_Invocations, [currentUser])
        XCTAssertNotNil(analyticsEventTracker)
    }
}
