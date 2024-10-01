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
import WireDataModelSupport
import WireSyncEngineSupport
import XCTest

@testable import WireDataModel
@testable import WireSyncEngine

final class AppendLocationMessageUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var analyticsEventTracker: MockAnalyticsEventTracker!
    private var mockConversation: MockMessageAppendableConversation!
    private var sut: AppendLocationMessageUseCase!

    // MARK: - setUp

    override func setUp() {
        analyticsEventTracker = .init()
        mockConversation = .init()
        sut = AppendLocationMessageUseCase(analyticsEventTracker: analyticsEventTracker)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockConversation = nil
        analyticsEventTracker = nil
    }

    // MARK: - Unit Tests

    func testInvoke_AppendLocationContent_TracksEventCorrectly() throws {
        // GIVEN
        mockConversation.conversationType = .group
        mockConversation.localParticipants = []
        mockConversation.appendLocation_MockMethod = { _, _ in
            MockZMConversationMessage()
        }
        analyticsEventTracker.trackEvent_MockMethod = { _ in }

        let testLocationData = LocationData(latitude: 37.7749, longitude: -122.4194, name: "San Francisco", zoomLevel: 10)

        // WHEN
        try sut.invoke(withLocationData: testLocationData, in: mockConversation)

        // THEN
        XCTAssertEqual(mockConversation.appendLocation_Invocations.count, 1)
        let appendLocationInvocation = try XCTUnwrap(mockConversation.appendLocation_Invocations.first)
        XCTAssertEqual(appendLocationInvocation.locationData.latitude, testLocationData.latitude)
        XCTAssertEqual(appendLocationInvocation.locationData.longitude, testLocationData.longitude)
        XCTAssertEqual(appendLocationInvocation.locationData.name, testLocationData.name)
        XCTAssertEqual(appendLocationInvocation.locationData.zoomLevel, testLocationData.zoomLevel)
        XCTAssertNotNil(appendLocationInvocation.nonce)

        let expectedEvent = AnalyticsEvent.conversationContribution(
            .locationMessage,
            conversationType: .group,
            conversationSize: 0
        )
        
        XCTAssertEqual(
            analyticsEventTracker.trackEvent_Invocations,
            [expectedEvent]
        )
    }
}
