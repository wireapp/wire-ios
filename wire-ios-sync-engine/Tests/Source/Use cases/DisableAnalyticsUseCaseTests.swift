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

final class DisableAnalyticsUseCaseTests: XCTestCase, AnalyticsEventTrackerProvider {

    private var sut: DisableAnalyticsUseCase!
    private var service: MockAnalyticsServiceProtocol!

    var analyticsEventTracker: (any AnalyticsEventTracker)?

    override func setUp() {
        super.setUp()
        service = MockAnalyticsServiceProtocol()
        sut = DisableAnalyticsUseCase(service: service, provider: self)
        analyticsEventTracker = MockAnalyticsEventTracker()
    }

    override func tearDown() {
        sut = nil
        service = nil
        analyticsEventTracker = nil
        super.tearDown()
    }

    func createAnalyticsUser() async throws -> AnalyticsUser {
        AnalyticsUser(analyticsIdentifier: UUID().uuidString)
    }

    func testInvoke_disables_via_service() throws {
        // Mock
        service.disableTracking_MockMethod = { }

        // Given
        XCTAssertNotNil(analyticsEventTracker)

        // When
        try sut.invoke()

        // Then
        XCTAssertEqual(service.disableTracking_Invocations.count, 1)
        XCTAssertNil(analyticsEventTracker)
    }

}
